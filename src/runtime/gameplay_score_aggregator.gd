extends RefCounted
## Minimal score accumulator for contract-level gameplay events.

var score := 0
var combo := 0
var max_combo := 0
var hits := 0
var misses := 0
var accuracy_total := 0.0
var accuracy_count := 0

func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	hits = 0
	misses = 0
	accuracy_total = 0.0
	accuracy_count = 0

func apply_event(event: Variant) -> void:
	var normalized := _to_dictionary(event)
	if normalized.is_empty():
		return

	var event_type := String(normalized.get("event_type", normalized.get("type", "")))
	var judgement := String(normalized.get("judgement", ""))
	if event_type == "judgement" and judgement == "miss":
		misses += 1
		combo = 0
		_record_accuracy(normalized)
		return

	var score_delta := int(normalized.get("score_delta", normalized.get("score", 0)))
	if score_delta != 0:
		score += score_delta
		hits += 1
		combo = max(0, combo + int(normalized.get("combo_delta", 1)))
		max_combo = maxi(max_combo, combo)
	_record_accuracy(normalized)

func apply_events(events: Array) -> void:
	for event in events:
		apply_event(event)

func to_dict() -> Dictionary:
	return {
		"score": score,
		"combo": combo,
		"max_combo": max_combo,
		"hits": hits,
		"misses": misses,
		"accuracy": get_accuracy()
	}

func _record_accuracy(event: Dictionary) -> void:
	if event.has("accuracy_delta"):
		accuracy_total += float(event.get("accuracy_delta", 0.0))
		accuracy_count += 1
	elif event.has("accuracy"):
		accuracy_total += float(event.get("accuracy", 0.0))
		accuracy_count += 1

func get_accuracy() -> float:
	if accuracy_count > 0:
		return accuracy_total / float(accuracy_count)
	var total := hits + misses
	if total <= 0:
		return 0.0
	return float(hits) / float(total)

static func _to_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	if value is RefCounted and value.has_method("to_dict"):
		return value.to_dict()
	return {}
