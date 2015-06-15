string CONTENT_SEPARATOR="\n";
integer MEMORY_TO_BE_USED=60000;

integer DOPOSE=200;
integer DOACTIONS=207;
integer CORE_DOPOSE_STRING=123456789;
integer CORE_DOACTION_STRING=123456790;
integer MEM_USAGE=34334;

list cache;
integer CACHE_NC_NAME=0;
integer CACHE_START_LINE=1;
integer CACHE_END_LINE=2;
integer CACHE_CONTENT=3;
integer CACHE_STRIDE=4;

list ncReadStack;
integer NC_READ_STACK_NC_NAME=0;
integer NC_READ_STACK_START_LINE=1;
integer NC_READ_STACK_END_LINE=2;
integer NC_READ_STACK_CONTENT=3;
integer NC_READ_STACK_CURRENT_LINE=4;
integer NC_READ_STACK_LINE_ID=5;
integer NC_READ_STACK_STRIDE=6;

list responseStack;
integer RESPONSE_STACK_NC_NAME=0;
integer RESPONSE_STACK_START_LINE=1;
integer RESPONSE_STACK_END_LINE=2;
integer RESPONSE_STACK_AVATAR_KEY=3;
integer RESPONSE_STACK_TYPE=4;
integer RESPONSE_STACK_STRIDE=5;

integer RESPONSE_STACK_TYPE_DOPOSE=CORE_DOPOSE_STRING;
integer RESPONSE_STACK_TYPE_DOACTION=CORE_DOACTION_STRING;

integer cacheHits;
integer cacheMisses;

//pragma inline
checkMemory() {
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
	cache=llDeleteSubList(cache, index, index + CACHE_STRIDE -1) + llList2List(cache, index, index + CACHE_STRIDE - 1);
}

//pragma inline
fetchNcContent(string ncName, key id, integer startLine, integer endLine, integer type) {
	cacheHits++;
	list identifier=[ncName, startLine, endLine];
	responseStack+=identifier + [id, type];

	integer index=llListFindList(cache, identifier);
	if(~index) {
		//the card is cached
		markCacheHit(index);
		processResponseStack();
	}
	else if(!~llListFindList(ncReadStack, identifier)) {
		//the card has to be processed
		cacheHits--;
		cacheMisses++;
		ncReadStack+=identifier + ["", startLine, llGetNotecardLine(ncName, startLine)];
	}
	checkMemory();
}

processResponseStack() {
	do{
		if(!llGetListLength(responseStack)) {
			//nothing to do
			return;
		}
		list identifier=llList2List(responseStack, 0, 2);
		integer index=llListFindList(ncReadStack, identifier);
		if(~index) {
			//this entry is currently being processed
			return;
		}
		index=llListFindList(cache, identifier);
		if(!~index) {
			//there is a problem. The entry is not beeing processed and not in the cache .. this should never happen
		}
		else {
			//ok .. send the response
			postResponse(
				llList2String(responseStack, RESPONSE_STACK_NC_NAME),
				llList2Integer(responseStack, RESPONSE_STACK_START_LINE),
				llList2Integer(responseStack, RESPONSE_STACK_END_LINE),
				llList2Key(responseStack, RESPONSE_STACK_AVATAR_KEY),
				llList2Integer(responseStack, RESPONSE_STACK_TYPE),
				llList2String(cache, index + CACHE_CONTENT)
			);
		}
		responseStack=llDeleteSubList(responseStack, 0, RESPONSE_STACK_STRIDE - 1);
	}
	while(TRUE);
}

//pragma inline
postResponse(string ncName, integer startLine, integer endLine, key id, integer type, string content) {
	llMessageLinked(LINK_SET, type, ncName + CONTENT_SEPARATOR + (string)startLine + CONTENT_SEPARATOR + (string)endLine + content, id);
	//debug start
	debug(["\nSend content from: " + ncName + "\nCached entries: " + (string)(llGetListLength(cache)/CACHE_STRIDE) + "\nUsedMemory: " + (string)llGetUsedMemory()]);
	//debug(["\nCache: " + llList2CSV(cache)]);
	//debug end
}

default {
	link_message(integer sender, integer num, string str, key id) {
		if(num==DOPOSE || num==DOACTIONS) {
			if(llGetInventoryType(str) == INVENTORY_NOTECARD) {
				if(num==DOPOSE) {
					fetchNcContent(str, id, 0, -1, CORE_DOPOSE_STRING);
				}
				else {
					fetchNcContent(str, id, 0, -1, CORE_DOACTION_STRING);
				}
			}
		}
		else if (num == MEM_USAGE){
			integer requests=cacheHits + cacheMisses;
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
					data="";
				}
				integer nextLine=llList2Integer(ncReadStack, ncReadStackIndex + NC_READ_STACK_CURRENT_LINE) + 1;
				integer endLine=llList2Integer(ncReadStack, ncReadStackIndex + NC_READ_STACK_END_LINE);
				if(~endLine && nextLine>endLine) {
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
