string CONTENT_SEPARATOR="℥";
integer MEMORY_TO_BE_USED=60000;

integer DOPOSE=200;
integer DOACTIONS=207;
integer DOPOSE_READER=222;
integer DOACTION_READER=223;
integer MEM_USAGE=34334;

list cache;
//the cache list contains only fully read (valid) content
integer CACHE_NC_NAME=0;
integer CACHE_START_LINE=1;
integer CACHE_END_LINE=2;
integer CACHE_CONTENT=3;
integer CACHE_STRIDE=4;

list ncReadStack;
//this is the working list, it contains partly read content
integer NC_READ_STACK_NC_NAME=0;
integer NC_READ_STACK_START_LINE=1;
integer NC_READ_STACK_END_LINE=2;
integer NC_READ_STACK_CONTENT=3;
integer NC_READ_STACK_CURRENT_LINE=4;
integer NC_READ_STACK_LINE_ID=5;
integer NC_READ_STACK_STRIDE=6;

list responseStack;
//this is used to ensure that the requests are servered in the right order
integer RESPONSE_STACK_NC_NAME=0;
integer RESPONSE_STACK_START_LINE=1;
integer RESPONSE_STACK_END_LINE=2;
integer RESPONSE_STACK_AVATAR_KEY=3;
integer RESPONSE_STACK_TYPE=4;
integer RESPONSE_SATCK_PLACEHOLDER=5;
integer RESPONSE_STACK_STRIDE=6;

integer RESPONSE_STACK_TYPE_DOPOSE=DOPOSE_READER;
integer RESPONSE_STACK_TYPE_DOACTION=DOACTION_READER;

integer cacheHits; //only used for statistical data
integer requests; //only used for statistical data

//pragma inline
checkMemory() {
	//if memory is low, flush the oldest cache entry
	while(llGetUsedMemory()>MEMORY_TO_BE_USED) {
		cache=llDeleteSubList(cache, 0, CACHE_STRIDE-1);
	}
}

//pragma inline
debug(list message) {
	llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message, "\n#>"));
}

//pragma inline
markCacheHit(integer index) {
	//if a cache hit occurs, move the cache entry to the end of the list, to prevent it from deleting due low memory
	cacheHits++;
	cache=llDeleteSubList(cache, index, index + CACHE_STRIDE -1) + llList2List(cache, index, index + CACHE_STRIDE - 1);
}

//pragma inline
fetchNcContent(string str, key id, integer type) {
	//we can also use the expanded DOPOSE/DOACTIONS format:
	//str: cardname, placeholder(currently not used), startLine, endline
	list parts=llCSV2List(str);
	string ncName=llList2String(parts, 0);
	if(llGetInventoryType(ncName) == INVENTORY_NOTECARD) {
		requests++;
		
		integer startLine=(integer)llList2String(parts, 2);
		integer endLine=-1;
		if(llList2String(parts, 3)!="") {
			endLine=(integer)llList2String(parts, 3);
		}
	
		list identifier=[ncName, startLine, endLine];
		responseStack+=identifier + [id, type, llList2String(parts, 1)];

		integer index=llListFindList(cache, identifier);
		if(~index) {
			//the card is cached, so check if we are ready to served the content or if we have to wait for other pending request
			markCacheHit(index);
			processResponseStack();
		}
		else if(!~llListFindList(ncReadStack, identifier)) {
			//the card has to be processed. Start the NC reading task
			ncReadStack+=identifier + ["", startLine, llGetNotecardLine(ncName, startLine)];
		}
		// else {
			// the card is currently beeing processed, so we have to do nothing but wait until it is finished
		// }
		
		checkMemory();
	}
}

processResponseStack() {
	do{
		if(!llGetListLength(responseStack)) {
			//there are no pending Requests: nothing to do
			return;
		}
		list identifier=llList2List(responseStack, 0, 2);
		integer index=llListFindList(ncReadStack, identifier);
		if(~index) {
			//this entry is currently being processed, we can't respond to it now.
			return;
		}
		index=llListFindList(cache, identifier);
		if(~index) {
			//The data is in the cache (and therefore valid and fully read) .. send the response
			postResponse(
				llList2String(responseStack, RESPONSE_STACK_NC_NAME),
				llList2String(responseStack, RESPONSE_SATCK_PLACEHOLDER),
				llList2Integer(responseStack, RESPONSE_STACK_START_LINE),
				llList2Integer(responseStack, RESPONSE_STACK_END_LINE),
				llList2Key(responseStack, RESPONSE_STACK_AVATAR_KEY),
				llList2Integer(responseStack, RESPONSE_STACK_TYPE),
				llList2String(cache, index + CACHE_CONTENT)
			);
		}
		//else {
			//there is a problem. The entry is not beeing processed and not in the cache .. this should never happen
		//}
		
		//we serverd the response, so we can delete it from the stack and check if there is more to do
		responseStack=llDeleteSubList(responseStack, 0, RESPONSE_STACK_STRIDE - 1);
	}
	while(TRUE);
}

//pragma inline
postResponse(string ncName, string placeholder, integer startLine, integer endLine, key id, integer type, string content) {
	//data Format:
	//str (separated by the CONTENT_SEPARATOR: NC Name, placeholder(currently not used), startline, endline, content
	llMessageLinked(LINK_SET, type,
		ncName + CONTENT_SEPARATOR +
		placeholder + CONTENT_SEPARATOR +
		(string)startLine + CONTENT_SEPARATOR +
		(string)endLine +
		content, id
	);
	//debug start
	debug(["Send content from: " + ncName, "Cached entries: " + (string)(llGetListLength(cache)/CACHE_STRIDE), "UsedMemory: " + (string)llGetUsedMemory()]);
	//debug(["\nCache: " + llList2CSV(cache)]);
	//debug end
}

default {
	link_message(integer sender, integer num, string str, key id) {
		if(num==DOPOSE) {
			fetchNcContent(str, id, DOPOSE_READER);
		}
		else if(num==DOACTIONS) {
			fetchNcContent(str, id, DOACTION_READER);
		}
		else if (num == MEM_USAGE){
			float hitRate;
			if(requests) {
				hitRate=(float)cacheHits / (float)requests * 100.0;
			}
			llSay(0,
				"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + 
				" of " + (string)llGetMemoryLimit() + 
				", Leaving " + (string)llGetFreeMemory() + " memory free.\nWe served " +
				(string)requests + " requests with a cache hit rate of " + 
				(string)llRound(hitRate) + "%."
			);
		}
	}
	dataserver(key queryid, string data) {
		integer ncReadStackIndex=llListFindList(ncReadStack, [queryid]) - NC_READ_STACK_LINE_ID;
		if(ncReadStackIndex>=0) {
			//its for us
			checkMemory();
			if(data!=EOF) {
				data=llStringTrim(data, STRING_TRIM);
				if(!llSubStringIndex(data, "#")) {
					//ignore comments
					data="";
				}
				integer nextLine=llList2Integer(ncReadStack, ncReadStackIndex + NC_READ_STACK_CURRENT_LINE) + 1;
				integer endLine=llList2Integer(ncReadStack, ncReadStackIndex + NC_READ_STACK_END_LINE);
				if(~endLine && nextLine>endLine) {
					//this is the last line in a single NC setup (.CONFIG)
					//checking this here means that
					// * we need a little more code memory
					// * the code get more confusing
					// * but we have one line less to read (~100-150ms faster)
					if(data) {
						ncReadStack=llListReplaceList(ncReadStack, [
							llList2String(ncReadStack, ncReadStackIndex + NC_READ_STACK_CONTENT) + CONTENT_SEPARATOR + data
						], ncReadStackIndex + NC_READ_STACK_CONTENT, ncReadStackIndex + NC_READ_STACK_CONTENT);
					}
					data=EOF;
				}
				else {
					string ncName=llList2String(ncReadStack, ncReadStackIndex + NC_READ_STACK_NC_NAME);
					if(data) {
						ncReadStack=llListReplaceList(ncReadStack, [
							llList2String(ncReadStack, ncReadStackIndex + NC_READ_STACK_CONTENT) + CONTENT_SEPARATOR + data,
							nextLine,
							llGetNotecardLine(ncName, nextLine)
							
						], ncReadStackIndex + NC_READ_STACK_CONTENT, ncReadStackIndex + NC_READ_STACK_CONTENT + 2);
					}
					else {
						//this is an empty line or a comment, no need to replace the content
						ncReadStack=llListReplaceList(ncReadStack, [
							nextLine,
							llGetNotecardLine(ncName, nextLine)
						], ncReadStackIndex + NC_READ_STACK_CURRENT_LINE, ncReadStackIndex + NC_READ_STACK_CURRENT_LINE + 1);
					}
				}
			}
			if(data==EOF) {
				//move the stuff to the cache and process the response stack
				cache+=llList2List(ncReadStack, ncReadStackIndex, ncReadStackIndex + NC_READ_STACK_CONTENT);
				ncReadStack=llDeleteSubList(ncReadStack, ncReadStackIndex, ncReadStackIndex + NC_READ_STACK_STRIDE - 1);
				processResponseStack();
			}
		} 
	}
	changed(integer change) {
		if(change & CHANGED_INVENTORY) {
			cache=[];
			ncReadStack=[];
			responseStack=[];
		}
	}
}
