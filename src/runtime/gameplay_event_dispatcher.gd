extends RefCounted
## Stores normalized gameplay events emitted during a run.

var _events: Array = []

func clear() -> void:
	_events.clear()

func dispatch(event: Dictionary) -> Dictionary:
	var normalized := event.duplicate(true)
	if not normalized.has("event_type"):
		normalized["event_type"] = String(normalized.get("type", "event"))
	_events.append(normalized)
	return normalized

func dispatch_many(events: Array) -> Array:
	var normalized_events: Array = []
	for event in events:
		var normalized := _to_dictionary(event)
		if not normalized.is_empty():
			normalized_events.append(dispatch(normalized))
	return normalized_events

func get_events() -> Array:
	return _events.duplicate(true)

static func _to_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	if value is RefCounted and value.has_method("to_dict"):
		return value.to_dict()
	return {}
