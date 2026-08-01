extends RefCounted
## Minimal score accumulator for contract-level gameplay events.

var score := 0
var combo := 0
var max_combo := 0
var hits := 0
var misses := 0

func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	hits = 0
	misses = 0

func apply_event(event: Dictionary) -> void:
	var event_type := String(event.get("type", ""))
	if event_type == "miss":
		misses += 1
		combo = 0
		return

	var score_delta := int(event.get("score", event.get("score_delta", 0)))
	if score_delta != 0:
		score += score_delta
		hits += 1
		combo += 1
		max_combo = maxi(max_combo, combo)

func apply_events(events: Array) -> void:
	for event in events:
		if event is Dictionary:
			apply_event(event)

func get_accuracy() -> float:
	var total := hits + misses
	if total <= 0:
		return 0.0
	return float(hits) / float(total)

func to_dict() -> Dictionary:
	return {
		"score": score,
		"combo": combo,
		"max_combo": max_combo,
		"hits": hits,
		"misses": misses,
		"accuracy": get_accuracy()
	}
