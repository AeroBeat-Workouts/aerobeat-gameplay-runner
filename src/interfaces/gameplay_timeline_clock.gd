extends RefCounted
## Interface documentation for gameplay timeline clocks.
##
## Expected methods:
## - reset() -> void
## - get_position_sec() -> float
## - get_duration_sec() -> float
## - get_state() -> String
## - is_complete() -> bool

var position_sec := 0.0
var duration_sec := 0.0
var state := ""

func reset() -> void:
	position_sec = 0.0

func get_position_sec() -> float:
	return position_sec

func get_duration_sec() -> float:
	return duration_sec

func get_state() -> String:
	return state

func is_complete() -> bool:
	return false
