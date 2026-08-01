extends RefCounted
## Interface documentation for gameplay timeline clocks.
##
## Expected methods:
## - reset() -> void
## - advance(delta_sec: float) -> float
## - get_position_sec() -> float
## - is_complete() -> bool

var position_sec := 0.0

func reset() -> void:
	position_sec = 0.0

func advance(delta_sec: float) -> float:
	position_sec += maxf(delta_sec, 0.0)
	return position_sec

func get_position_sec() -> float:
	return position_sec

func is_complete() -> bool:
	return false
