extends RefCounted
## Interface documentation for gameplay input streams.
##
## Expected methods:
## - poll_frame(position_sec: float) -> Dictionary
## - reset() -> void

func poll_frame(_position_sec: float) -> Dictionary:
	return {}

func reset() -> void:
	pass
