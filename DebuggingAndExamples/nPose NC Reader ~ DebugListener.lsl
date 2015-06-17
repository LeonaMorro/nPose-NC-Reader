// LSL script generated - patched Render.hs (0.1.6.2): DebuggingAndExamples.nPose NC Reader ~ DebugListener.lslp Wed Jun 17 13:43:55 Mitteleuropäische Sommerzeit 2015


debug(list message){
    llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message,"\n#>"));
}

default {

	state_entry() {
    }


	link_message(integer sender_num,integer num,string str,key id) {
        if (num == 200) {
            debug(["DOPOSE",str,"DOPOSE id",id]);
        }
        else  if (num == 207) {
            debug(["DOACTIONS",str,"DOACTIONS id",id]);
        }
        else  if (num == 222) {
            debug(["DOPOSE_READER",str,"DOPOSE_READER id",id]);
        }
        else  if (num == 223) {
            debug(["DOACTION_READER",str,"DOACTION_READER id",id]);
        }
    }
}
