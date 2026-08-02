extends RefCounted
## Final result snapshot for a gameplay run.

var state := "idle"
var score := 0
var max_combo := 0
var accuracy := 0.0
var duration_sec := 0.0
var reason := ""
var events: Array = []
var mode_fragments: Array = []
var judgements: Array = []
var score_deltas: Array = []
var metadata: Dictionary = {}

func _init(values: Dictionary = {}) -> void:
	state = String(values.get("state", state))
	score = int(values.get("score", score))
	max_combo = int(values.get("max_combo", max_combo))
	accuracy = float(values.get("accuracy", accuracy))
	duration_sec = float(values.get("duration_sec", duration_sec))
	reason = String(values.get("reason", reason))
	events = _array_or_empty(values.get("events", events))
	mode_fragments = _array_or_empty(values.get("mode_fragments", mode_fragments))
	judgements = _array_or_empty(values.get("judgements", judgements))
	score_deltas = _array_or_empty(values.get("score_deltas", score_deltas))
	metadata = _dictionary_or_empty(values.get("metadata", metadata))

func to_dict() -> Dictionary:
	return {
		"state": state,
		"score": score,
		"max_combo": max_combo,
		"accuracy": accuracy,
		"duration_sec": duration_sec,
		"reason": reason,
		"events": events.duplicate(true),
		"mode_fragments": mode_fragments.duplicate(true),
		"judgements": judgements.duplicate(true),
		"score_deltas": score_deltas.duplicate(true),
		"metadata": metadata.duplicate(true)
	}

static func _array_or_empty(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []

static func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
