extends RefCounted
## Runner-owned session setup envelope that derives a mode-local config subset.

const ModeRunConfig := preload("res://addons/aerobeat-mode-core/src/data_types/mode_run_config.gd")

var mode_id := ""
var chart_id := ""
var chart_ref: Dictionary = {}
var chart_data: Dictionary = {}
var seed := 0
var timeline: Dictionary = {}
var tuning: Dictionary = {}
var scoring: Dictionary = {}
var metadata: Dictionary = {}

func _init(values: Dictionary = {}) -> void:
	mode_id = String(values.get("mode_id", mode_id)).strip_edges()
	chart_id = String(values.get("chart_id", chart_id)).strip_edges()
	chart_ref = _dictionary_or_empty(values.get("chart_ref", chart_ref))
	chart_data = _dictionary_or_empty(values.get("chart_data", chart_data))
	seed = int(values.get("seed", seed))
	timeline = _dictionary_or_empty(values.get("timeline", timeline))
	tuning = _dictionary_or_empty(values.get("tuning", tuning))
	scoring = _dictionary_or_empty(values.get("scoring", scoring))
	metadata = _dictionary_or_empty(values.get("metadata", metadata))

func duplicate_config() -> RefCounted:
	return get_script().new(to_dict())

func to_dict() -> Dictionary:
	return {
		"mode_id": mode_id,
		"chart_id": chart_id,
		"chart_ref": chart_ref.duplicate(true),
		"chart_data": chart_data.duplicate(true),
		"seed": seed,
		"timeline": timeline.duplicate(true),
		"tuning": tuning.duplicate(true),
		"scoring": scoring.duplicate(true),
		"metadata": metadata.duplicate(true)
	}

func to_mode_run_config() -> RefCounted:
	return ModeRunConfig.new({
		"mode_id": mode_id,
		"chart_id": chart_id,
		"chart_ref": chart_ref,
		"chart_data": chart_data,
		"seed": seed,
		"tuning": tuning,
		"scoring": scoring,
		"metadata": metadata
	})

func is_valid() -> bool:
	return not mode_id.is_empty()

static func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
