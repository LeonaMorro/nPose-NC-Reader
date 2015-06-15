integer DOPOSE=200;
integer DOACTIONS=207;
integer CORE_DOPOSE_STRING=123456789;
integer CORE_DOACTION_STRING=123456790;

debug(list message) {
	llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message, "\n#>"));
}

default {
	state_entry() {
	}

	link_message(integer sender_num, integer num, string str, key id) {
		if(num==DOPOSE) {
			debug(["DOPOSE", str, "DOPOSE id", id]);
		}
		else if(num==DOACTIONS) {
			debug(["DOACTIONS", str, "DOACTIONS id", id]);
		}
		else if(num==CORE_DOPOSE_STRING) {
			debug(["CORE_DOPOSE_STRING", str, "CORE_DOPOSE_STRING id", id]);
		}
		else if(num==CORE_DOACTION_STRING) {
			debug(["CORE_DOACTION_STRING", str, "CORE_DOACTION_STRING id", id]);
		}
	}
}
