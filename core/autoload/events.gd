extends Node
## Global game event bus (autoload `Events`). Only for events that several
## unrelated systems care about; parent/child communication uses normal signals.
##
## The signals are emitted from other scripts, hence the unused_signal ignores.

@warning_ignore("unused_signal")
signal run_started(run: RunState)
@warning_ignore("unused_signal")
signal run_ended(run: RunState)
@warning_ignore("unused_signal")
signal coin_collected(amount: int)
@warning_ignore("unused_signal")
signal key_collected(amount: int)
