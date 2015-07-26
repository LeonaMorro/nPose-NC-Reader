// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose NC Reader.lslp Sun Jul 26 10:54:50 Mitteleuropäische Sommerzeit 2015
// The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:
//
// The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
//   - If you distribute the nPose scripts, you must leave them full perms.
//    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.
//
// "Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
//
// Documentation:
// https://github.com/LeonaMorro/nPose-NC-Reader/wiki
// Report Bugs to:
// https://github.com/LeonaMorro/nPose-NC-Reader/issues
// or IM slmember1 Resident (Leona)

string NC_READER_CONTENT_SEPARATOR = "℥";

list cacheNcNames;
list cacheContent;
//the cache lists contains only fully read (valid) content

list ncReadStackNcNames;
list ncReadStack;

list responseStack;

integer cacheMiss;
integer requests;

checkMemory(){
    while (llGetUsedMemory() > 60000) {
        cacheNcNames = llDeleteSubList(cacheNcNames,0,0);
        cacheContent = llDeleteSubList(cacheContent,0,0);
    }
}

processResponseStack(){
    do  {
        if (!llGetListLength(responseStack)) {
            return;
        }
        string ncName = llList2String(responseStack,0);
        if (~llListFindList(ncReadStackNcNames,[ncName])) {
            return;
        }
        integer index = llListFindList(cacheNcNames,[ncName]);
        if (~index) {
            llMessageLinked(-1,llList2Integer(responseStack,4),llDumpList2String(llList2List(responseStack,0,2),NC_READER_CONTENT_SEPARATOR) + llList2String(cacheContent,index),llList2Key(responseStack,3));
            responseStack = llDeleteSubList(responseStack,0,4);
            cacheNcNames = llDeleteSubList(cacheNcNames,index,index) + llList2List(cacheNcNames,index,index);
            cacheContent = llDeleteSubList(cacheContent,index,index) + llList2List(cacheContent,index,index);
        }
        else  {
            cacheMiss++;
            ncReadStackNcNames += [ncName];
            ncReadStack += [llGetNotecardLine(ncName,0),0,""];
            return;
        }
    }
    while (1);
}

default {

	link_message(integer sender,integer num,string str,key id) {
        if (num == 200) {
            list parts = llParseStringKeepNulls(str,[NC_READER_CONTENT_SEPARATOR],[]);
            string ncName = llList2String(parts,0);
            string menuName = llList2String(parts,1);
            string placeholder = llList2String(parts,2);
            if (llGetInventoryType(ncName) == 7) {
                requests++;
                responseStack += [ncName,menuName,placeholder,id,222];
                processResponseStack();
                checkMemory();
            }
        }
        else  if (num == 207) {
            list _parts2 = llParseStringKeepNulls(str,[NC_READER_CONTENT_SEPARATOR],[]);
            string _ncName3 = llList2String(_parts2,0);
            string _menuName4 = llList2String(_parts2,1);
            string _placeholder5 = llList2String(_parts2,2);
            if (llGetInventoryType(_ncName3) == 7) {
                requests++;
                responseStack += [_ncName3,_menuName4,_placeholder5,id,223];
                processResponseStack();
                checkMemory();
            }
        }
        else  if (num == 224) {
            list _parts7 = llParseStringKeepNulls(str,[NC_READER_CONTENT_SEPARATOR],[]);
            string _ncName8 = llList2String(_parts7,0);
            string _menuName9 = llList2String(_parts7,1);
            string _placeholder10 = llList2String(_parts7,2);
            if (llGetInventoryType(_ncName8) == 7) {
                requests++;
                responseStack += [_ncName8,_menuName9,_placeholder10,id,225];
                processResponseStack();
                checkMemory();
            }
        }
        else  if (num == 34334) {
            float hitRate;
            if (requests) {
                hitRate = 100.0 - (float)cacheMiss / (float)requests * 100.0;
            }
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.\nWe served " + (string)requests + " requests with a cache hit rate of " + (string)llRound(hitRate) + "%.");
        }
    }

	dataserver(key queryid,string data) {
        integer ncReadStackIndex = llListFindList(ncReadStack,[queryid]);
        if (~ncReadStackIndex) {
            checkMemory();
            string ncName = llList2String(ncReadStackNcNames,ncReadStackIndex);
            if (data == EOF) {
                cacheNcNames += ncName;
                cacheContent += llList2String(ncReadStack,ncReadStackIndex + 2);
                ncReadStackNcNames = llDeleteSubList(ncReadStackNcNames,ncReadStackIndex,ncReadStackIndex);
                ncReadStack = llDeleteSubList(ncReadStack,ncReadStackIndex,ncReadStackIndex + 3 - 1);
                processResponseStack();
            }
            else  {
                data = llStringTrim(data,3);
                if (!llSubStringIndex(data,"#")) {
                    data = "";
                }
                if (data) {
                    data = NC_READER_CONTENT_SEPARATOR + data;
                }
                integer nextLine = llList2Integer(ncReadStack,ncReadStackIndex + 1) + 1;
                ncReadStack = llListReplaceList(ncReadStack,[llGetNotecardLine(ncName,nextLine),nextLine,llList2String(ncReadStack,ncReadStackIndex + 2) + data],ncReadStackIndex,ncReadStackIndex + 3 - 1);
            }
        }
    }

	changed(integer change) {
        if (change & 1) {
            cacheNcNames = [];
            cacheContent = [];
            ncReadStackNcNames = [];
            ncReadStack = [];
            responseStack = [];
        }
    }
}
