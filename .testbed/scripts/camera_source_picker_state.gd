extends RefCounted
## Runner-owned setup state for selecting the camera-tracking source before provider startup.

const MODE_NONE := "none"
const MODE_LIVE := "live_camera"
const MODE_REPLAY := "video_file"

var mode := MODE_NONE
var live_camera_id := "0"
var replay_video_path := ""

func select_live(camera_id: String = "0") -> void:
	var normalized := String(camera_id).strip_edges()
	if normalized.is_empty():
		normalized = "0"
	mode = MODE_LIVE
	live_camera_id = normalized
	replay_video_path = ""

func select_replay(path: String) -> void:
	var normalized := String(path).strip_edges()
	mode = MODE_REPLAY if not normalized.is_empty() else MODE_NONE
	replay_video_path = normalized

func is_configured() -> bool:
	return mode == MODE_LIVE or (mode == MODE_REPLAY and not replay_video_path.is_empty())

func source_identity() -> String:
	if mode == MODE_REPLAY:
		return replay_video_path
	if mode == MODE_LIVE:
		return live_camera_id
	return ""

func provider_settings() -> Dictionary:
	if not is_configured():
		return {}
	var identity := source_identity()
	var source := {"kind": mode}
	if mode == MODE_REPLAY:
		source["path"] = identity
	else:
		source["camera_id"] = identity
		source["id"] = identity
	return {
		"camera_source": identity,
		"selected_camera_device_id": identity,
		"source": source,
	}

func status_text() -> String:
	if mode == MODE_REPLAY:
		return "Replay video: %s" % replay_video_path.get_file()
	if mode == MODE_LIVE:
		return "Live camera: %s" % live_camera_id
	return "Camera source: choose live or replay video"
