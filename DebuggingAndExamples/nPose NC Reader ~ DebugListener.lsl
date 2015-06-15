// LSL script generated - patched Render.hs (0.1.6.2): DebuggingAndExamples.nPose NC Reader ~ DebugListener.lslp Mon Jun 15 13:22:31 Mitteleuropäische Sommerzeit 2015


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
        else  if (num == 123456789) {
            debug(["CORE_DOPOSE_STRING",str,"CORE_DOPOSE_STRING id",id]);
        }
        else  if (num == 123456790) {
            debug(["CORE_DOACTION_STRING",str,"CORE_DOACTION_STRING id",id]);
        }
    }
}
