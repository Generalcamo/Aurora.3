TIMER_SUBSYSTEM_DEF(runechat)
	name = "Runechat"
	priority = FIRE_PRIORITY_RUNECHAT

	var/list/datum/callback/message_queue = list()

/datum/controller/subsystem/timer/runechat/fire(resumed)
	CAN_BE_REDEFINED(TRUE)
	. = ..() //poggers
	while(message_queue.len)
		var/datum/callback/queued_message = message_queue[message_queue.len]
		queued_message.Invoke()
		LIST_DEC(message_queue)
		if(MC_TICK_CHECK)
			return
