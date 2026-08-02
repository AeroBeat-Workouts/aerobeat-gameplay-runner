extends RefCounted
## Gameplay runner clock adapter. Audio position is the timing authority.

var audio_loader: Node = null
var audio_id := "default"

func _init(loader: Node = null, slot_id: String = "default") -> void:
	audio_loader = loader
	audio_id = slot_id

func reset() -> void:
	if audio_loader != null and audio_loader.has_method("seek"):
		audio_loader.seek(0.0, audio_id)

func get_position_sec() -> float:
	if audio_loader != null and audio_loader.has_method("get_position"):
		return maxf(0.0, float(audio_loader.get_position(audio_id)))
	return 0.0

func get_duration_sec() -> float:
	if audio_loader != null and audio_loader.has_method("get_duration"):
		return maxf(0.0, float(audio_loader.get_duration(audio_id)))
	return 0.0

func get_state() -> String:
	if audio_loader != null and audio_loader.has_method("get_state"):
		var state: Variant = audio_loader.get_state(audio_id)
		if state is Dictionary:
			return String(state.get("state", ""))
	return ""

func is_complete() -> bool:
	var duration := get_duration_sec()
	return duration > 0.0 and get_position_sec() >= duration
