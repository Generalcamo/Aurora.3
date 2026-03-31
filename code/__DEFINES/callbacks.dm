#define GLOBAL_PROC "some_magic_bullshit"
/// A shorthand for the callback datum, [documented here](datum/callback.html)
#define CALLBACK new /datum/callback

//dupe code because dm can't handle 3 level deep macros
#define VARSET_CALLBACK(datum, var, var_value) CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(___callbackvarset), ##datum, NAMEOF(##datum, ##var), ##var_value)
/// Same as VARSET_CALLBACK, but uses a weakref to the datum.
/// Use this if the timer is exceptionally long.
#define VARSET_WEAK_CALLBACK(datum, var, var_value) CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(___callbackvarset), WEAKREF(##datum), NAMEOF(##datum, ##var), ##var_value)

/proc/___callbackvarset(list_or_datum, var_name, var_value)
	if(length(list_or_datum))
		list_or_datum[var_name] = var_value
		return

	var/datum/datum = list_or_datum

	if (isweakref(datum))
		var/datum/weakref/datum_weakref = datum
		datum = datum_weakref.resolve()
		if (isnull(datum))
			return

	//if(IsAdminAdvancedProcCall())
	//	datum.vv_edit_var(var_name, var_value) //same result generally, unless badmemes
	//else
	datum.vars[var_name] = var_value

/proc/___callbackvarsetlistremove(list, var_value)
	if(length(list))
		list -= var_value

///Per the DM reference, spawn(-1) will execute the spawned code immediately until a block is met.
#define MAKE_SPAWN_ACT_LIKE_WAITFOR -1
///Create a codeblock that will not block the callstack if a block is met.
#define ASYNC spawn(MAKE_SPAWN_ACT_LIKE_WAITFOR)

#define INVOKE_ASYNC(proc_owner, proc_path, proc_arguments...) \
	if ((proc_owner) == GLOBAL_PROC) { \
		ASYNC { \
			call(proc_path)(##proc_arguments); \
		}; \
	} \
	else { \
		ASYNC { \
			/* Written with `0 ||` to avoid the compiler seeing call("string"), and thinking it's a deprecated DLL */ \
			call(0 || proc_owner, proc_path)(##proc_arguments); \
		}; \
	}

/// like CALLBACK but specifically for verb callbacks
#define VERB_CALLBACK new /datum/callback/verb_callback
