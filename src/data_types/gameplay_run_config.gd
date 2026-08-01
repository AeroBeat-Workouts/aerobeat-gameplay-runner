extends RefCounted
## Immutable-enough run setup data passed into a gameplay mode runner.

var mode_id := ""
var chart_id := ""
var seed := 0
var timeline: Dictionary = {}
var scoring: Dictionary = {}
var metadata: Dictionary = {}

func _init(values: Dictionary = {}) -> void:
	mode_id = String(values.get("mode_id", mode_id)).strip_edges()
	chart_id = String(values.get("chart_id", chart_id)).strip_edges()
	seed = int(values.get("seed", seed))
	timeline = _dictionary_or_empty(values.get("timeline", timeline))
	scoring = _dictionary_or_empty(values.get("scoring", scoring))
	metadata = _dictionary_or_empty(values.get("metadata", metadata))

func duplicate_config() -> RefCounted:
	return get_script().new(to_dict())

func to_dict() -> Dictionary:
	return {
		"mode_id": mode_id,
		"chart_id": chart_id,
		"seed": seed,
		"timeline": timeline.duplicate(true),
		"scoring": scoring.duplicate(true),
		"metadata": metadata.duplicate(true)
	}

func is_valid() -> bool:
	return not mode_id.is_empty()

static func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
