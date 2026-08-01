extends Node
## Repo-owned gameplay runner facade.
##
## This singleton creates runner sessions and contract data objects. Concrete
## feature modes provide the mode runner, timeline clock, and input stream
## implementations consumed by GameplaySession.

const GameplayRunConfig := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_config.gd")
const GameplayRunResult := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_result.gd")
const GameplayRunState := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_state.gd")
const GameplaySession := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_session.gd")

signal session_started(session: RefCounted)
signal session_completed(result: RefCounted)

var _active_session: RefCounted = null

func create_config(values: Dictionary = {}) -> RefCounted:
	return GameplayRunConfig.new(values)

func create_session(config: RefCounted = null, mode_runner: Variant = null) -> RefCounted:
	var session := GameplaySession.new()
	if config != null and mode_runner != null:
		session.start(config, mode_runner)
		session_started.emit(session)
	_active_session = session
	return session

func start_session(config: RefCounted, mode_runner: Variant) -> String:
	var session := create_session(config, mode_runner)
	return session.get_state()

func stop_session(reason: String = "stopped") -> RefCounted:
	if _active_session == null:
		return GameplayRunResult.new({
			"state": GameplayRunState.IDLE,
			"reason": "no_active_session"
		})
	var result: RefCounted = _active_session.stop(reason)
	session_completed.emit(result)
	_active_session = null
	return result

func get_active_session() -> RefCounted:
	return _active_session

func get_state() -> String:
	if _active_session == null:
		return GameplayRunState.IDLE
	return _active_session.get_state()
