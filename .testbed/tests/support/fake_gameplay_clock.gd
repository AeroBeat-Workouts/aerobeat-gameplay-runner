extends RefCounted

var position_sec := 0.0
var duration_sec := 1.0
var state := "ready"
var reset_count := 0
var advance_called := false

func reset() -> void:
	reset_count += 1
	position_sec = 0.0
	state = "running"

func get_position_sec() -> float:
	return position_sec

func get_duration_sec() -> float:
	return duration_sec

func get_state() -> String:
	return state

func is_complete() -> bool:
	return state == "complete" or (duration_sec > 0.0 and position_sec >= duration_sec)

func set_position(value: float) -> void:
	position_sec = maxf(value, 0.0)
	if is_complete():
		state = "complete"

func advance(_delta_sec: float) -> float:
	advance_called = true
	return position_sec
