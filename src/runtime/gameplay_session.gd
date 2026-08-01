extends RefCounted
## Coordinates one gameplay mode run from start through final result.

const GameplayRunResult := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_result.gd")
const GameplayRunState := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_state.gd")
const GameplayEventDispatcher := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_event_dispatcher.gd")
const GameplayScoreAggregator := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_score_aggregator.gd")

var config: RefCounted = null
var mode_runner: Variant = null
var timeline_clock: Variant = null
var input_stream: Variant = null

var _state := GameplayRunState.IDLE
var _duration_sec := 0.0
var _dispatcher := GameplayEventDispatcher.new()
var _score := GameplayScoreAggregator.new()
var _start_detail: Dictionary = {}
var _stop_detail: Dictionary = {}

func start(run_config: RefCounted, runner: Variant, clock: Variant = null, stream: Variant = null) -> String:
	if run_config == null or runner == null:
		_state = GameplayRunState.FAILED
		return _state

	config = run_config
	mode_runner = runner
	timeline_clock = clock
	input_stream = stream
	_duration_sec = 0.0
	_dispatcher.clear()
	_score.reset()
	_start_detail = {}
	_stop_detail = {}

	if timeline_clock != null and timeline_clock.has_method("reset"):
		timeline_clock.reset()
	if input_stream != null and input_stream.has_method("reset"):
		input_stream.reset()
	if mode_runner.has_method("start"):
		var detail: Variant = mode_runner.start(config)
		_start_detail = detail.duplicate(true) if detail is Dictionary else {}

	_state = GameplayRunState.RUNNING
	return _state

func tick(delta_sec: float, input_frame: Dictionary = {}) -> Array:
	if _state != GameplayRunState.RUNNING:
		return []

	var clamped_delta := maxf(delta_sec, 0.0)
	_duration_sec += clamped_delta
	var position_sec := _duration_sec
	if timeline_clock != null and timeline_clock.has_method("advance"):
		position_sec = float(timeline_clock.advance(clamped_delta))

	var frame := input_frame.duplicate(true)
	if frame.is_empty() and input_stream != null and input_stream.has_method("poll_frame"):
		var polled: Variant = input_stream.poll_frame(position_sec)
		frame = polled.duplicate(true) if polled is Dictionary else {}

	var emitted: Array = []
	if mode_runner != null and mode_runner.has_method("tick"):
		var tick_result: Variant = mode_runner.tick(clamped_delta, frame)
		emitted = tick_result.duplicate(true) if tick_result is Array else []

	var events := _dispatcher.dispatch_many(emitted)
	_score.apply_events(events)

	if _runner_is_complete():
		_state = GameplayRunState.COMPLETED
	return events

func pause() -> String:
	if _state == GameplayRunState.RUNNING:
		_state = GameplayRunState.PAUSED
	return _state

func resume() -> String:
	if _state == GameplayRunState.PAUSED:
		_state = GameplayRunState.RUNNING
	return _state

func stop(reason: String = "stopped") -> RefCounted:
	if _state == GameplayRunState.RUNNING or _state == GameplayRunState.PAUSED:
		_state = GameplayRunState.STOPPED

	if mode_runner != null and mode_runner.has_method("stop"):
		var detail: Variant = mode_runner.stop(reason)
		_stop_detail = detail.duplicate(true) if detail is Dictionary else {}

	return _make_result(reason)

func get_state() -> String:
	return _state

func get_duration_sec() -> float:
	return _duration_sec

func get_score() -> int:
	return _score.score

func get_event_history() -> Array:
	return _dispatcher.get_events()

func get_score_summary() -> Dictionary:
	return _score.to_dict()

func _runner_is_complete() -> bool:
	if mode_runner != null and mode_runner.has_method("is_complete") and bool(mode_runner.is_complete()):
		return true
	if timeline_clock != null and timeline_clock.has_method("is_complete") and bool(timeline_clock.is_complete()):
		return true
	return false

func _make_result(reason: String) -> RefCounted:
	var summary := _score.to_dict()
	return GameplayRunResult.new({
		"state": _state,
		"score": summary.get("score", 0),
		"max_combo": summary.get("max_combo", 0),
		"accuracy": summary.get("accuracy", 0.0),
		"duration_sec": _duration_sec,
		"reason": reason,
		"events": _dispatcher.get_events(),
		"metadata": {
			"start_detail": _start_detail.duplicate(true),
			"stop_detail": _stop_detail.duplicate(true)
		}
	})
