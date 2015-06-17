// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose Core 0.30.025 (beta1)(NcReader+XANIM).lslp Wed Jun 17 13:46:30 Mitteleuropäische Sommerzeit 2015
/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
	- If you distribute the nPose scripts, you must leave them full perms.
	- If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/


//define block start
string adminHudName = "npose admin hud";
string defaultprefix = "DEFAULT:";
string cardprefix = "SET:";
//define block end

integer slotMax;
integer curPrimCount;
integer lastPrimCount;
integer lastStrideCount = 12;
integer rezadjusters;
//integer listener;
integer chatchannel;
integer explicitFlag;
integer x;
integer n;
integer stop;
key hudId;
string lastDoPoseCardName;
string lastDoPosePlaceholder;
integer lastDoPoseStartLine;
integer lastDoPoseEndLine;
key lastDoPoseCardId;
key lastDoPoseAvatarId;
list slots;

integer FindEmptySlot(){
    for (n = 0; n < slotMax; ++n) {
        if (llList2String(slots,n * 8 + 4) == "") {
            return n;
        }
    }
    return -1;
}

list SeatedAvs(){
    list avs = [];
    n = llGetNumberOfPrims();
    for (; n >= 0; --n) {
        key id = llGetLinkKey(n);
        if (llGetAgentSize(id) != ZERO_VECTOR) {
            avs = [id] + avs;
        }
    }
    return avs;
}

assignSlots(){
    list avqueue = SeatedAvs();
    stop = llGetListLength(avqueue);
    if (slotMax < lastStrideCount) {
        for (x = slotMax; x <= lastStrideCount; ++x) {
            if (llList2Key(slots,x * 8 + 4) != "") {
                integer emptySlot = FindEmptySlot();
                if (emptySlot >= 0 && emptySlot < slotMax) {
                    slots = llListReplaceList(slots,[llList2Key(slots,x * 8 + 4)],emptySlot * 8 + 4,emptySlot * 8 + 4);
                }
            }
        }
        slots = llDeleteSubList(slots,slotMax * 8,-1);
        for (n = 0; n < stop; ++n) {
            if (!~llListFindList(slots,[llList2Key(avqueue,n)])) {
                llMessageLinked(-1,-222,llList2String(avqueue,n),NULL_KEY);
            }
        }
    }
    if (curPrimCount > lastPrimCount) {
        key thisKey = llList2Key(avqueue,stop - 1);
        integer primcount = llGetObjectPrimCount(llGetKey());
        integer slotNum = -1;
        for (n = 1; n <= primcount; ++n) {
            integer _x3 = (integer)llGetSubString(llGetLinkName(n),4,-1);
            if (_x3 > 0 && _x3 <= slotMax) {
                if (llAvatarOnLinkSitTarget(n) == thisKey) {
                    if (llList2String(slots,(_x3 - 1) * 8 + 4) == "") {
                        slotNum = (integer)llGetLinkName(n);
                    }
                }
            }
        }
        integer nn;
        for (nn = 1; nn <= primcount; ++nn) {
            if (~slotNum && !~llListFindList(slots,[thisKey])) {
                if (slotNum <= slotMax) {
                    slots = llListReplaceList(slots,[thisKey],(slotNum - 1) * 8 + 4,(slotNum - 1) * 8 + 4);
                }
                else  {
                    integer y = FindEmptySlot();
                    if (~y) {
                        slots = llListReplaceList(slots,[thisKey],y * 8 + 4,y * 8 + 4);
                    }
                    else  if (~llListFindList(SeatedAvs(),[thisKey])) {
                        llMessageLinked(-1,-222,(string)thisKey,NULL_KEY);
                    }
                }
            }
            if (!~llListFindList(slots,[thisKey])) {
                integer y = FindEmptySlot();
                if (~y) {
                    slots = llListReplaceList(slots,[thisKey],y * 8 + 4,y * 8 + 4);
                }
                else  if (~llListFindList(SeatedAvs(),[thisKey])) {
                    llMessageLinked(-1,-222,(string)thisKey,NULL_KEY);
                }
            }
        }
    }
    else  if (curPrimCount < lastPrimCount) {
        for (x = 0; x < slotMax; ++x) {
            if (!~llListFindList(avqueue,[llList2Key(slots,x * 8 + 4)])) {
                slots = llListReplaceList(slots,[""],x * 8 + 4,x * 8 + 4);
            }
        }
    }
    lastPrimCount = curPrimCount;
    lastStrideCount = slotMax;
    llMessageLinked(-1,35353,llDumpList2String(slots,"^"),NULL_KEY);
}

SwapTwoSlots(integer currentseatnum,integer newseatnum){
    if (newseatnum <= slotMax) {
        integer slotNum;
        integer OldSlot;
        integer NewSlot;
        for (; slotNum < slotMax; ++slotNum) {
            integer z = llSubStringIndex(llList2String(slots,slotNum * 8 + 7),"Â§");
            string strideSeat = llGetSubString(llList2String(slots,slotNum * 8 + 7),z + 1,-1);
            if (strideSeat == "seat" + (string)currentseatnum) {
                OldSlot = slotNum;
            }
            if (strideSeat == "seat" + (string)newseatnum) {
                NewSlot = slotNum;
            }
        }
        list curslot = llList2List(slots,NewSlot * 8,NewSlot * 8 + 3) + [llList2Key(slots,OldSlot * 8 + 4)] + llList2List(slots,NewSlot * 8 + 5,NewSlot * 8 + 7);
        slots = llListReplaceList(slots,llList2List(slots,OldSlot * 8,OldSlot * 8 + 3) + [llList2Key(slots,NewSlot * 8 + 4)] + llList2List(slots,OldSlot * 8 + 5,OldSlot * 8 + 7),OldSlot * 8,(OldSlot + 1) * 8 - 1);
        slots = llListReplaceList(slots,curslot,NewSlot * 8,(NewSlot + 1) * 8 - 1);
    }
    else  {
        llRegionSayTo(llList2Key(slots,llListFindList(slots,["seat" + (string)currentseatnum]) - 4),0,"Seat " + (string)newseatnum + " is not available for this pose set");
    }
    llMessageLinked(-1,35353,llDumpList2String(slots,"^"),NULL_KEY);
}



SwapAvatarInto(key avatar,string newseat){
    integer slotIndex = llListFindList(slots,[avatar]);
    integer z = llSubStringIndex(llList2String(slots,slotIndex + 3),"Â§");
    string strideSeat = llGetSubString(llList2String(slots,slotIndex + 3),z + 1,-1);
    integer oldseat = (integer)llGetSubString(strideSeat,4,-1);
    if (oldseat <= 0) {
        llWhisper(0,"avatar is not assigned a slot: " + (string)avatar);
    }
    else  {
        SwapTwoSlots(oldseat,(integer)newseat);
    }
}


ProcessLine(string sLine,key av,string ncName){
    sLine = llDumpList2String(llParseStringKeepNulls(sLine,["%AVKEY%"],[]),av);
    sLine = llDumpList2String(llParseStringKeepNulls(sLine,["%CARDNAME%"],[]),ncName);
    list params = llParseStringKeepNulls(sLine,["|"],[]);
    string action = llList2String(params,0);
    if (action == "ANIM") {
        if (slotMax < lastStrideCount) {
            slots = llListReplaceList(slots,[llList2String(params,1),(vector)llList2String(params,2),llEuler2Rot((vector)llList2String(params,3) * 1.745329238e-2),llList2String(params,4),llList2Key(slots,slotMax * 8 + 4),"","",llGetSubString(llList2String(params,5),0,12) + "Â§" + "seat" + (string)(slotMax + 1)],slotMax * 8,slotMax * 8 + 7);
        }
        else  {
            slots += [llList2String(params,1),(vector)llList2String(params,2),llEuler2Rot((vector)llList2String(params,3) * 1.745329238e-2),llList2String(params,4),"","","",llGetSubString(llList2String(params,5),0,12) + "Â§" + "seat" + (string)(slotMax + 1)];
        }
        slotMax++;
    }
    else  if (action == "XANIM") {
        integer seatNum = (integer)llList2String(params,6) - 1;
        slots = llListReplaceList(slots,[llList2String(params,1),(vector)llList2String(params,2),llEuler2Rot((vector)llList2String(params,3) * 1.745329238e-2),llList2String(params,4)],seatNum * 8,seatNum * 8 + 3);
        slots = llListReplaceList(slots,[llGetSubString(llList2String(params,5),0,12) + "Â§seat" + (string)(seatNum + 1)],seatNum * 8 + 7,seatNum * 8 + 7);
        slotMax = lastStrideCount;
    }
    else  if (action == "SINGLE") {
        integer posIndex = llListFindList(slots,[(vector)llList2String(params,2)]);
        if (posIndex == -1 || (posIndex != -1 && llList2String(slots,posIndex - 1) != llList2String(params,1))) {
            integer slotindex = llListFindList(slots,[av]) - 4;
            if (slotindex >= 0) {
                slots = llListReplaceList(slots,[llList2String(params,1),(vector)llList2String(params,2),llEuler2Rot((vector)llList2String(params,3) * 1.745329238e-2),llList2String(params,4),llList2Key(slots,slotindex + 4),"","",llList2String(slots,slotindex + 7)],slotindex,slotindex + 7);
            }
        }
        slotMax = llGetListLength(slots) / 8;
        lastStrideCount = slotMax;
    }
    else  if (action == "PROP") {
        string obj = llList2String(params,1);
        if (llGetInventoryType(obj) == 6) {
            list strParm2 = llParseString2List(llList2String(params,2),["="],[]);
            if (llList2String(strParm2,1) == "die") {
                llRegionSay(chatchannel,llList2String(strParm2,0) + "=die");
            }
            else  {
                explicitFlag = 0;
                if (llList2String(params,4) == "explicit") {
                    explicitFlag = 1;
                }
                vector vDelta = (vector)llList2String(params,2);
                vector pos = llGetPos() + vDelta * llGetRot();
                rotation rot = llEuler2Rot((vector)llList2String(params,3) * 1.745329238e-2) * llGetRot();
                if (llVecMag(vDelta) > 9.9) {
                    llRezAtRoot(obj,llGetPos(),ZERO_VECTOR,rot,chatchannel);
                    llSleep(1.0);
                    llRegionSay(chatchannel,llDumpList2String(["MOVEPROP",obj,(string)pos],"|"));
                }
                else  {
                    llRezAtRoot(obj,llGetPos() + (vector)llList2String(params,2) * llGetRot(),ZERO_VECTOR,rot,chatchannel);
                }
            }
        }
    }
    else  if (action == "LINKMSG") {
        integer num = (integer)llList2String(params,1);
        key lmid;
        if ((key)llList2String(params,3) != "") {
            lmid = (key)llList2String(params,3);
        }
        else  {
            lmid = (key)llList2String(slots,(slotMax - 1) * 8 + 4);
        }
        string str = llList2String(params,2);
        llMessageLinked(-1,num,str,lmid);
        llRegionSay(chatchannel,llDumpList2String(["LINKMSG",num,str,lmid],"|"));
    }
    else  if (action == "SATMSG") {
        integer index = (slotMax - 1) * 8 + 5;
        slots = llListReplaceList(slots,[llDumpList2String([llList2String(slots,index),llDumpList2String(llDeleteSubList(params,0,0),"|")],"Â§")],index,index);
    }
    else  if (action == "NOTSATMSG") {
        integer index = (slotMax - 1) * 8 + 6;
        slots = llListReplaceList(slots,[llDumpList2String([llList2String(slots,index),llDumpList2String(llDeleteSubList(params,0,0),"|")],"Â§")],index,index);
    }
}

default {

	state_entry() {
        curPrimCount = llGetNumberOfPrims();
        for (n = 0; n <= curPrimCount; ++n) {
            llLinkSitTarget(n,<0.0,0.0,0.5>,ZERO_ROTATION);
        }
        chatchannel = (integer)("0x" + llGetSubString((string)llGetKey(),0,7));
        llMessageLinked(-1,1,(string)chatchannel,NULL_KEY);
        curPrimCount = llGetNumberOfPrims();
        lastPrimCount = curPrimCount;
        integer listener = llListen(chatchannel,"","","");
        stop = llGetInventoryNumber(7);
        for (n = 0; n < stop; n++) {
            string cardName = llGetInventoryName(7,n);
            if (llSubStringIndex(cardName,defaultprefix) == 0 || llSubStringIndex(cardName,cardprefix) == 0) {
                llSleep(1.0);
                llMessageLinked(-1,200,cardName,NULL_KEY);
                return;
            }
        }
    }

	link_message(integer sender,integer num,string str,key id) {
        if (num == 999999) {
            llMessageLinked(-1,1,(string)chatchannel,NULL_KEY);
        }
        else  if (num == 222 || num == 223) {
            list allData = llParseStringKeepNulls(str,["℥"],[]);
            string ncName = llList2String(allData,0);
            if (num == 222) {
                lastStrideCount = slotMax;
                slotMax = 0;
                llRegionSay(chatchannel,"die");
                llRegionSay(chatchannel,"adjuster_die");
            }
            integer length = llGetListLength(allData);
            integer index = 4;
            for (; index < length; index++) {
                string data = llList2String(allData,index);
                if (num == 222 || !llSubStringIndex(data,"LINKMSG") || !llSubStringIndex(data,"PROP")) {
                    ProcessLine(llList2String(allData,index),id,ncName);
                }
            }
            if (num == 222) {
                if (llGetInventoryType(ncName) == 7) {
                    lastDoPoseCardName = ncName;
                    lastDoPosePlaceholder = llList2String(allData,1);
                    lastDoPoseStartLine = llList2Integer(allData,2);
                    lastDoPoseEndLine = llList2Integer(allData,3);
                    lastDoPoseCardId = llGetInventoryKey(lastDoPoseCardName);
                    lastDoPoseAvatarId = id;
                }
                assignSlots();
                if (rezadjusters) {
                    llMessageLinked(-1,2,"RezAdjuster","");
                }
            }
        }
        else  if (num == 201) {
            rezadjusters = 1;
        }
        else  if (num == 205) {
            rezadjusters = 0;
        }
        else  if (num == 300) {
            list msg = llParseString2List(str,["|"],[]);
            if (id != NULL_KEY) msg = llListReplaceList((msg = []) + msg,[id],2,2);
            llRegionSay(chatchannel,llDumpList2String(["LINKMSG",(string)llList2String(msg,0),llList2String(msg,1),(string)llList2String(msg,2)],"|"));
        }
        else  if (num == 202) {
            if (llGetListLength(slots) / 8 >= 2) {
                list seats2Swap = llParseString2List(str,[","],[]);
                SwapTwoSlots((integer)llList2String(seats2Swap,0),(integer)llList2String(seats2Swap,1));
            }
        }
        else  if (num == 210) {
            SwapAvatarInto(id,str);
        }
        else  if (num == 2035353) {
            list tempList = llParseStringKeepNulls(str,["^"],[]);
            integer listStop = llGetListLength(tempList) / 8;
            integer slotNum;
            for (; slotNum < listStop; ++slotNum) {
                slots = llListReplaceList(slots,[llList2String(tempList,slotNum * 8),(vector)llList2String(tempList,slotNum * 8 + 1),(rotation)llList2String(tempList,slotNum * 8 + 2),llList2String(tempList,slotNum * 8 + 3),(key)llList2String(tempList,slotNum * 8 + 4),llList2String(tempList,slotNum * 8 + 5),llList2String(tempList,slotNum * 8 + 6),llList2String(tempList,slotNum * 8 + 7)],slotNum * 8,slotNum * 8 + 7);
            }
            slotMax = listStop;
        }
        else  if (num == -999) {
            if (llGetInventoryType(adminHudName) != -1 && str == "RezHud") {
                llRezObject(adminHudName,llGetPos() + <0.0,0.0,1.0>,ZERO_VECTOR,llGetRot(),chatchannel);
            }
            else  if (num == -999 && str == "RemoveHud") {
                llRegionSayTo(hudId,chatchannel,"/die");
            }
        }
        else  if (num == 34334) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
            llSay(0,"running script time for all scripts in this nPose object are consuming " + (string)(llList2Float(llGetObjectDetails(llGetKey(),[12]),0) * 1000.0) + " ms of cpu time");
        }
    }


	object_rez(key id) {
        if (llKey2Name(id) == adminHudName) {
            hudId = id;
            llSleep(2.0);
            llRegionSayTo(hudId,chatchannel,"parent|" + (string)llGetKey());
        }
    }


	listen(integer channel,string name,key id,string message) {
        list temp = llParseString2List(message,["|"],[]);
        if (name == "Adjuster") {
            llMessageLinked(-1,3,message,id);
        }
        else  if (llGetListLength(temp) >= 2 || llGetSubString(message,0,4) == "ping" || llGetSubString(message,0,8) == "PROPRELAY") {
            if (llGetOwnerKey(id) == llGetOwner()) {
                if (message == "ping") {
                    llRegionSay(chatchannel,"pong|" + (string)explicitFlag + "|" + (string)llGetPos());
                }
                else  if (llGetSubString(message,0,8) == "PROPRELAY") {
                    list msg = llParseString2List(message,["|"],[]);
                    llMessageLinked(-1,llList2Integer(msg,1),llList2String(msg,2),llList2Key(msg,3));
                }
                else  if (name == "pos_adjuster_hud") {
                }
                else  {
                    list params = llParseString2List(message,["|"],[]);
                    vector newpos = (vector)llList2String(params,0) - llGetPos();
                    newpos = newpos / llGetRot();
                    rotation newrot = (rotation)llList2String(params,1) / llGetRot();
                    llRegionSayTo(llGetOwner(),0,"\nPROP|" + name + "|" + (string)newpos + "|" + (string)(llRot2Euler(newrot) * 57.29578) + "|" + llList2String(params,2));
                    llMessageLinked(-1,34333,"PROP|" + name + "|" + (string)newpos + "|" + (string)(llRot2Euler(newrot) * 57.29578),NULL_KEY);
                }
            }
        }
        else  if (name == llKey2Name(hudId)) {
            if (message == "adjust") {
                llMessageLinked(-1,201,"","");
            }
            else  if (message == "stopadjust") {
                llMessageLinked(-1,205,"","");
            }
            else  if (message == "posdump") {
                llMessageLinked(-1,204,"","");
            }
            else  if (message == "hudsync") {
                llMessageLinked(-1,206,"","");
            }
        }
    }


	changed(integer change) {
        if (change & 1) {
            if (llGetInventoryType(lastDoPoseCardName) == 7) {
                if (lastDoPoseCardId != llGetInventoryKey(lastDoPoseCardName) && !lastDoPoseStartLine && ~lastDoPoseEndLine) {
                    llSleep(1.0);
                    llMessageLinked(-1,200,llList2CSV([lastDoPoseCardName,lastDoPosePlaceholder,lastDoPoseStartLine,lastDoPoseEndLine]),lastDoPoseAvatarId);
                }
                else  {
                    llResetScript();
                }
            }
            else  {
                llResetScript();
            }
        }
        if (change & 32) {
            llMessageLinked(-1,1,(string)chatchannel,NULL_KEY);
            lastPrimCount = curPrimCount;
            curPrimCount = llGetNumberOfPrims();
            assignSlots();
        }
        if (change & 256) {
            llMessageLinked(-1,35353,llDumpList2String(slots,"^"),NULL_KEY);
        }
    }

	
	on_rez(integer param) {
        llResetScript();
    }
}
