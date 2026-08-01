extends RefCounted
## Stores normalized gameplay events emitted during a run.

var _events: Array = []

func clear() -> void:
	_events.clear()

func dispatch(event: Dictionary) -> Dictionary:
	var normalized := event.duplicate(true)
	if not normalized.has("type"):
		normalized["type"] = "event"
	_events.append(normalized)
	return normalized

func dispatch_many(events: Array) -> Array:
	var normalized_events: Array = []
	for event in events:
		if event is Dictionary:
			normalized_events.append(dispatch(event))
	return normalized_events

func get_events() -> Array:
	return _events.duplicate(true)
