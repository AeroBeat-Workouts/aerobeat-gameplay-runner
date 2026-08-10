extends RefCounted
## Converts InputManager signals into gameplay-runner input envelopes.

const GameplayInputStreamScript := preload("res://addons/aerobeat-gameplay-runner/src/interfaces/gameplay_input_stream.gd")

var input_manager: Node = null
var clock: Variant = null
var _events: Array[Dictionary] = []

func bind(manager: Node, timeline_clock: Variant) -> void:
	input_manager = manager
	clock = timeline_clock
	if input_manager == null:
		return
	for event_name: String in GameplayInputStreamScript.BOXING_PUNCH_EVENTS:
		if input_manager.has_signal(event_name):
			input_manager.connect(event_name, func() -> void: _push_boxing(event_name))
	for event_name: String in GameplayInputStreamScript.BOXING_STATE_EVENTS:
		if input_manager.has_signal(event_name):
			input_manager.connect(event_name, func() -> void: _push_boxing(event_name))
	for event_name: String in ["left_wrist_cell_entered", "right_wrist_cell_entered", "nose_cell_entered"]:
		if input_manager.has_signal(event_name):
			input_manager.connect(event_name, func(cell: int, direction: int) -> void: _push_body_cell(event_name, cell, direction))
	for event_name: String in GameplayInputStreamScript.FLOW_EVENTS:
		if input_manager.has_signal(event_name):
			input_manager.connect(event_name, func() -> void: _push_flow(event_name))

func reset() -> void:
	_events.clear()

func poll_frame(position_sec: float) -> Dictionary:
	var ready: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	for envelope in _events:
		if float(envelope.get("position_sec", 0.0)) <= position_sec:
			ready.append(envelope)
		else:
			remaining.append(envelope)
	_events = remaining
	return {"input_events": ready}

func _push_boxing(event_name: String) -> void:
	_events.append(GameplayInputStreamScript.make_envelope(GameplayInputStreamScript.CONTRACT_BOXING_V1, event_name, _position(), []))

func _push_flow(event_name: String) -> void:
	_events.append(GameplayInputStreamScript.make_envelope(GameplayInputStreamScript.CONTRACT_FLOW_V1, event_name, _position(), []))

func _push_body_cell(event_name: String, cell: int, direction: int) -> void:
	_events.append(GameplayInputStreamScript.make_envelope(GameplayInputStreamScript.CONTRACT_BODY_CELL_V1, event_name, _position(), [cell, direction]))

func _position() -> float:
	if clock != null and clock.has_method("get_position_sec"):
		return float(clock.get_position_sec())
	return 0.0
