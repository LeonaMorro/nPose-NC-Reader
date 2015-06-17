integer DOPOSE=200;
integer DOACTIONS=207;
integer DOPOSE_READER=222;
integer DOACTION_READER=223;

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
		else if(num==DOPOSE_READER) {
			debug(["DOPOSE_READER", str, "DOPOSE_READER id", id]);
		}
		else if(num==DOACTION_READER) {
			debug(["DOACTION_READER", str, "DOACTION_READER id", id]);
		}
	}
}
