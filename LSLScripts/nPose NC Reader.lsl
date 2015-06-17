// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose NC Reader.lslp Wed Jun 17 13:49:25 Mitteleuropäische Sommerzeit 2015
string CONTENT_SEPARATOR = "℥";

list cache;

list ncReadStack;

list responseStack;

integer cacheHits;
integer requests;

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
        if (~index) {
            string ncName = llList2String(responseStack,0);
            string placeholder = llList2String(responseStack,5);
            integer startLine = llList2Integer(responseStack,1);
            integer endLine = llList2Integer(responseStack,2);
            key id = llList2Key(responseStack,3);
            integer type = llList2Integer(responseStack,4);
            string content = llList2String(cache,index + 3);
            llMessageLinked(-1,type,ncName + CONTENT_SEPARATOR + placeholder + CONTENT_SEPARATOR + (string)startLine + CONTENT_SEPARATOR + (string)endLine + content,id);
            list message = ["Send content from: " + ncName,"Cached entries: " + (string)(llGetListLength(cache) / 4),"UsedMemory: " + (string)llGetUsedMemory()];
            llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message,"\n#>"));
        }
        responseStack = llDeleteSubList(responseStack,0,5);
    }
    while (1);
}

default {

	link_message(integer sender,integer num,string str,key id) {
        if (num == 200) {
            list parts = llCSV2List(str);
            string ncName = llList2String(parts,0);
            if (llGetInventoryType(ncName) == 7) {
                requests++;
                integer startLine = (integer)llList2String(parts,2);
                integer endLine = -1;
                if (llList2String(parts,3) != "") {
                    endLine = (integer)llList2String(parts,3);
                }
                list identifier = [ncName,startLine,endLine];
                responseStack += identifier + [id,222,llList2String(parts,1)];
                integer index = llListFindList(cache,identifier);
                if (~index) {
                    cacheHits++;
                    cache = llDeleteSubList(cache,index,index + 4 - 1) + llList2List(cache,index,index + 4 - 1);
                    processResponseStack();
                }
                else  if (!~llListFindList(ncReadStack,identifier)) {
                    ncReadStack += identifier + ["",startLine,llGetNotecardLine(ncName,startLine)];
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
        else  if (num == 207) {
            list _parts2 = llCSV2List(str);
            string _ncName3 = llList2String(_parts2,0);
            if (llGetInventoryType(_ncName3) == 7) {
                requests++;
                integer _startLine4 = (integer)llList2String(_parts2,2);
                integer _endLine5 = -1;
                if (llList2String(_parts2,3) != "") {
                    _endLine5 = (integer)llList2String(_parts2,3);
                }
                list _identifier6 = [_ncName3,_startLine4,_endLine5];
                responseStack += _identifier6 + [id,223,llList2String(_parts2,1)];
                integer _index7 = llListFindList(cache,_identifier6);
                if (~_index7) {
                    cacheHits++;
                    cache = llDeleteSubList(cache,_index7,_index7 + 4 - 1) + llList2List(cache,_index7,_index7 + 4 - 1);
                    processResponseStack();
                }
                else  if (!~llListFindList(ncReadStack,_identifier6)) {
                    ncReadStack += _identifier6 + ["",_startLine4,llGetNotecardLine(_ncName3,_startLine4)];
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
        else  if (num == 34334) {
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
