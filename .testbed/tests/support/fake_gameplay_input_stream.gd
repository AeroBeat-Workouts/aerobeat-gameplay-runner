extends RefCounted

const GameplayInputStream := preload("res://addons/aerobeat-gameplay-runner/src/interfaces/gameplay_input_stream.gd")

var events: Array[Dictionary] = []
var cursor := 0
var reset_count := 0

func _init(rows: Array = []) -> void:
	for row in rows:
		if row is Dictionary:
			events.append(row.duplicate(true))

func reset() -> void:
	reset_count += 1
	cursor = 0

func poll_frame(position_sec: float) -> Array:
	var due: Array[Dictionary] = []
	while cursor < events.size():
		var event := events[cursor]
		if float(event.get("position_sec", 0.0)) > position_sec:
			break
		due.append(event.duplicate(true))
		cursor += 1
	return due

static func boxing(event: String, position_sec: float) -> Dictionary:
	return GameplayInputStream.make_boxing_event(event, position_sec)

static func body_cell(event: String, position_sec: float, cell: int, direction: int) -> Dictionary:
	return GameplayInputStream.make_body_cell_event(event, position_sec, cell, direction)

static func flow(event: String, position_sec: float) -> Dictionary:
	return GameplayInputStream.make_flow_event(event, position_sec)
