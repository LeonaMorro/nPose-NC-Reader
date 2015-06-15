// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose NC Reader V0.03.lslp Mon Jun 15 13:22:37 Mitteleuropäische Sommerzeit 2015
string CONTENT_SEPARATOR = "\n";

list cache;

list ncReadStack;

list responseStack;

integer cacheHits;
integer cacheMisses;

processResponseStack(){
    do  {
        if (!llGetListLength(responseStack)) {
            return;
        }
        list identifier = llList2List(responseStack,0,2);
        integer index = llListFindList(ncReadStack,identifier);
        if (~index) {
            return;
        }
        index = llListFindList(cache,identifier);
        if (!~index) {
        }
        else  {
            string ncName = llList2String(responseStack,0);
            integer startLine = llList2Integer(responseStack,1);
            integer endLine = llList2Integer(responseStack,2);
            key id = llList2Key(responseStack,3);
            integer type = llList2Integer(responseStack,4);
            string content = llList2String(cache,index + 3);
            llMessageLinked(-1,type,ncName + CONTENT_SEPARATOR + (string)startLine + CONTENT_SEPARATOR + (string)endLine + content,id);
            list message = ["\nSend content from: " + ncName + "\nCached entries: " + (string)(llGetListLength(cache) / 4) + "\nUsedMemory: " + (string)llGetUsedMemory()];
            llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message,"\n#>"));
        }
        responseStack = llDeleteSubList(responseStack,0,4);
    }
    while (1);
}

default {

	link_message(integer sender,integer num,string str,key id) {
        if (num == 200 || num == 207) {
            if (llGetInventoryType(str) == 7) {
                if (num == 200) {
                    cacheHits++;
                    list identifier = [str,0,-1];
                    responseStack += identifier + [id,123456789];
                    integer index = llListFindList(cache,identifier);
                    if (~index) {
                        cache = llDeleteSubList(cache,index,index + 4 - 1) + llList2List(cache,index,index + 4 - 1);
                        processResponseStack();
                    }
                    else  if (!~llListFindList(ncReadStack,identifier)) {
                        cacheHits--;
                        cacheMisses++;
                        ncReadStack += identifier + ["",0,llGetNotecardLine(str,0)];
                    }
                    while (llGetUsedMemory() > 60000) {
                        {
                            {
                                cache = llDeleteSubList(cache,0,3);
                            }
                        }
                    }
                }
                else  {
                    cacheHits++;
                    list _identifier2 = [str,0,-1];
                    responseStack += _identifier2 + [id,123456790];
                    integer _index3 = llListFindList(cache,_identifier2);
                    if (~_index3) {
                        cache = llDeleteSubList(cache,_index3,_index3 + 4 - 1) + llList2List(cache,_index3,_index3 + 4 - 1);
                        processResponseStack();
                    }
                    else  if (!~llListFindList(ncReadStack,_identifier2)) {
                        cacheHits--;
                        cacheMisses++;
                        ncReadStack += _identifier2 + ["",0,llGetNotecardLine(str,0)];
                    }
                    while (llGetUsedMemory() > 60000) {
                        {
                            {
                                cache = llDeleteSubList(cache,0,3);
                            }
                        }
                    }
                }
            }
        }
        else  if (num == 34334) {
            integer requests = cacheHits + cacheMisses;
            float hitRate;
            if (requests) {
                hitRate = (float)cacheHits / (float)requests * 100.0;
            }
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.\nWe served " + (string)requests + " requests with a cache hit rate of " + (string)llRound(hitRate) + "%.");
        }
    }

	dataserver(key queryid,string data) {
        integer ncReadStackIndex = llListFindList(ncReadStack,[queryid]) - 5;
        if (ncReadStackIndex >= 0) {
            while (llGetUsedMemory() > 60000) {
                {
                    cache = llDeleteSubList(cache,0,3);
                }
            }
            if (data != EOF) {
                data = llStringTrim(data,3);
                if (!llSubStringIndex(data,"#")) {
                    data = "";
                }
                integer nextLine = llList2Integer(ncReadStack,ncReadStackIndex + 4) + 1;
                integer endLine = llList2Integer(ncReadStack,ncReadStackIndex + 2);
                if (~endLine && nextLine > endLine) {
                    if (data) {
                        ncReadStack = llListReplaceList(ncReadStack,[llList2String(ncReadStack,ncReadStackIndex + 3) + CONTENT_SEPARATOR + data],ncReadStackIndex + 3,ncReadStackIndex + 3);
                    }
                    data = EOF;
                }
                else  {
                    string ncName = llList2String(ncReadStack,ncReadStackIndex + 0);
                    if (data) {
                        ncReadStack = llListReplaceList(ncReadStack,[llList2String(ncReadStack,ncReadStackIndex + 3) + CONTENT_SEPARATOR + data,nextLine,llGetNotecardLine(ncName,nextLine)],ncReadStackIndex + 3,ncReadStackIndex + 3 + 2);
                    }
                    else  {
                        ncReadStack = llListReplaceList(ncReadStack,[nextLine,llGetNotecardLine(ncName,nextLine)],ncReadStackIndex + 4,ncReadStackIndex + 4 + 1);
                    }
                }
            }
            if (data == EOF) {
                cache += llList2List(ncReadStack,ncReadStackIndex,ncReadStackIndex + 3);
                ncReadStack = llDeleteSubList(ncReadStack,ncReadStackIndex,ncReadStackIndex + 6 - 1);
                processResponseStack();
            }
        }
    }

	changed(integer change) {
        if (change & 1) {
            cache = [];
            ncReadStack = [];
            responseStack = [];
        }
    }
}
