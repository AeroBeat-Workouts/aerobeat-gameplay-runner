extends RefCounted
## Interface documentation for runner-owned gameplay input streams.
##
## Expected methods:
## - poll_frame(position_sec: float) -> Array[Dictionary]
## - reset() -> void
##
## Fake/test streams should mirror input-core signal contracts with event rows:
## {"contract": String, "event": String, "position_sec": float, "args": Array}

const CONTRACT_BOXING_V1 := "aerobeat.input.boxing.v1"
const CONTRACT_BODY_CELL_V1 := "aerobeat.input.body_cell.v1"
const CONTRACT_FLOW_V1 := "aerobeat.input.flow.v1"

const BOXING_PUNCH_EVENTS := [
	"straight_left",
	"straight_right",
	"uppercut_left",
	"uppercut_right",
	"hook_left",
	"hook_right"
]

const BOXING_STATE_EVENTS := [
	"guard_enabled",
	"guard_disabled",
	"squat_enabled",
	"squat_disabled",
	"weave_left_enabled",
	"weave_left_disabled",
	"weave_right_enabled",
	"weave_right_disabled"
]

const BODY_CELL_EVENTS := [
	"left_wrist_cell_entered",
	"right_wrist_cell_entered",
	"nose_cell_entered",
	"calibration_session_updated"
]

const FLOW_EVENTS := [
	"squat_enabled",
	"squat_disabled"
]

func poll_frame(_position_sec: float) -> Array:
	return []

func reset() -> void:
	pass

static func make_envelope(contract: String, event: String, position_sec: float, args: Array = []) -> Dictionary:
	return {
		"contract": contract,
		"event": event,
		"position_sec": position_sec,
		"args": args.duplicate(true)
	}

static func make_boxing_event(event: String, position_sec: float) -> Dictionary:
	return make_envelope(CONTRACT_BOXING_V1, event, position_sec, [])

static func make_body_cell_event(event: String, position_sec: float, cell: int, direction: int) -> Dictionary:
	return make_envelope(CONTRACT_BODY_CELL_V1, event, position_sec, [cell, direction])

static func make_flow_event(event: String, position_sec: float) -> Dictionary:
	return make_envelope(CONTRACT_FLOW_V1, event, position_sec, [])

static func is_valid_envelope(envelope: Dictionary) -> bool:
	var contract := String(envelope.get("contract", ""))
	var event := String(envelope.get("event", ""))
	if contract.is_empty() or event.is_empty() or not envelope.has("position_sec"):
		return false
	var args: Array = envelope.get("args", []) if envelope.get("args", []) is Array else []
	match contract:
		CONTRACT_BOXING_V1:
			if BOXING_PUNCH_EVENTS.has(event):
				return args.is_empty()
			return BOXING_STATE_EVENTS.has(event) and args.is_empty()
		CONTRACT_BODY_CELL_V1:
			if event == "calibration_session_updated":
				return args.size() == 1 and args[0] is Dictionary
			return BODY_CELL_EVENTS.has(event) and args.size() == 2 and args[0] is int and args[1] is int
		CONTRACT_FLOW_V1:
			return FLOW_EVENTS.has(event) and args.is_empty()
		_:
			return false
