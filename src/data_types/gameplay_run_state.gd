extends RefCounted
## Shared gameplay session state names.

const IDLE := "idle"
const READY := "ready"
const RUNNING := "running"
const PAUSED := "paused"
const COMPLETED := "completed"
const STOPPED := "stopped"
const FAILED := "failed"

static func is_terminal(state: String) -> bool:
	return state == COMPLETED or state == STOPPED or state == FAILED

static func is_active(state: String) -> bool:
	return state == RUNNING or state == PAUSED
