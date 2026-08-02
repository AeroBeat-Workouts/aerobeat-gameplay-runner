extends RefCounted
## Coordinates one gameplay mode run from start through final result.

const GameplayRunResult := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_result.gd")
const GameplayRunState := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_state.gd")
const GameplayEventDispatcher := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_event_dispatcher.gd")
const GameplayScoreAggregator := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_score_aggregator.gd")
const ModeTickFrame := preload("res://addons/aerobeat-mode-core/src/data_types/mode_tick_frame.gd")
const ModeRunFragment := preload("res://addons/aerobeat-mode-core/src/data_types/mode_run_fragment.gd")
const ModeEvent := preload("res://addons/aerobeat-mode-core/src/data_types/mode_event.gd")
const ModeScoreDelta := preload("res://addons/aerobeat-mode-core/src/data_types/mode_score_delta.gd")

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
var _mode_fragments: Array = []
var _judgements: Array = []
var _score_deltas: Array = []
var _chart_events: Array[Dictionary] = []
var _chart_cursor := 0
var _last_position_sec := 0.0

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
	_mode_fragments.clear()
	_judgements.clear()
	_score_deltas.clear()
	_chart_events = _read_chart_events(run_config)
	_chart_cursor = 0
	_last_position_sec = 0.0

	if timeline_clock != null and timeline_clock.has_method("reset"):
		timeline_clock.reset()
	if input_stream != null and input_stream.has_method("reset"):
		input_stream.reset()
	if mode_runner.has_method("start"):
		var detail: Variant = mode_runner.start(_mode_config_from(run_config))
		_start_detail = _to_dictionary(detail)
		_capture_fragment(detail)

	_state = GameplayRunState.RUNNING
	return _state

func tick(delta_sec: float, input_frame: Variant = {}) -> Array:
	if _state != GameplayRunState.RUNNING:
		return []

	var clamped_delta := maxf(delta_sec, 0.0)
	var position_sec := _sample_position_sec(clamped_delta)
	var frame := ModeTickFrame.new({
		"position_sec": position_sec,
		"delta_sec": clamped_delta,
		"chart_events": _poll_chart_events(position_sec),
		"input_events": _poll_input_events(position_sec, input_frame),
		"metadata": {
			"clock_state": _sample_clock_state()
		}
	})

	var emitted: Array = []
	if mode_runner != null and mode_runner.has_method("tick"):
		var tick_result: Variant = mode_runner.tick(frame)
		emitted = tick_result.duplicate(true) if tick_result is Array else []

	var events := _process_mode_output(emitted)

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
	var should_stop_mode := _state == GameplayRunState.RUNNING or _state == GameplayRunState.PAUSED
	if _state == GameplayRunState.RUNNING or _state == GameplayRunState.PAUSED:
		_state = GameplayRunState.STOPPED

	if should_stop_mode and mode_runner != null and mode_runner.has_method("stop"):
		var detail: Variant = mode_runner.stop(reason)
		_stop_detail = _to_dictionary(detail)
		_capture_fragment(detail)

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

func get_mode_fragments() -> Array:
	return _mode_fragments.duplicate(true)

func get_judgements() -> Array:
	return _judgements.duplicate(true)

func get_score_deltas() -> Array:
	return _score_deltas.duplicate(true)

func _runner_is_complete() -> bool:
	if mode_runner != null and mode_runner.has_method("is_complete") and bool(mode_runner.is_complete()):
		return true
	if timeline_clock != null and timeline_clock.has_method("is_complete") and bool(timeline_clock.is_complete()):
		return true
	return false

func _make_result(reason: String) -> RefCounted:
	var summary := _score.to_dict()
	var result_duration_sec := _duration_sec
	if _runner_is_complete():
		result_duration_sec = maxf(result_duration_sec, _sample_clock_duration_sec())
	return GameplayRunResult.new({
		"state": _state,
		"score": summary.get("score", 0),
		"max_combo": summary.get("max_combo", 0),
		"accuracy": summary.get("accuracy", 0.0),
		"duration_sec": result_duration_sec,
		"reason": reason,
		"events": _dispatcher.get_events(),
		"mode_fragments": _mode_fragments.duplicate(true),
		"judgements": _judgements.duplicate(true),
		"score_deltas": _score_deltas.duplicate(true),
		"metadata": {
			"start_detail": _start_detail.duplicate(true),
			"stop_detail": _stop_detail.duplicate(true),
			"clock_state": _sample_clock_state()
		}
	})

func _mode_config_from(run_config: RefCounted) -> RefCounted:
	if run_config != null and run_config.has_method("to_mode_run_config"):
		return run_config.to_mode_run_config()
	return run_config

func _sample_position_sec(delta_sec: float) -> float:
	var position_sec := _last_position_sec + delta_sec
	if timeline_clock != null and timeline_clock.has_method("get_position_sec"):
		position_sec = float(timeline_clock.get_position_sec())
	_last_position_sec = maxf(position_sec, 0.0)
	_duration_sec = _last_position_sec
	return _last_position_sec

func _sample_clock_state() -> String:
	if timeline_clock != null and timeline_clock.has_method("get_state"):
		return String(timeline_clock.get_state())
	return ""

func _sample_clock_duration_sec() -> float:
	if timeline_clock != null and timeline_clock.has_method("get_duration_sec"):
		return maxf(float(timeline_clock.get_duration_sec()), 0.0)
	return 0.0

func _read_chart_events(run_config: RefCounted) -> Array[Dictionary]:
	var raw_events: Variant = []
	if run_config != null:
		var timeline_value: Variant = run_config.get("timeline")
		if timeline_value is Dictionary:
			raw_events = timeline_value.get("chart_events", [])
		var chart_data_value: Variant = run_config.get("chart_data")
		if raw_events is Array and raw_events.is_empty() and chart_data_value is Dictionary:
			raw_events = chart_data_value.get("events", [])

	var result: Array[Dictionary] = []
	if raw_events is Array:
		for item in raw_events:
			if item is Dictionary:
				result.append(item.duplicate(true))
	return result

func _poll_chart_events(position_sec: float) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	while _chart_cursor < _chart_events.size():
		var event := _chart_events[_chart_cursor]
		if float(event.get("position_sec", 0.0)) > position_sec:
			break
		due.append(event.duplicate(true))
		_chart_cursor += 1
	return due

func _poll_input_events(position_sec: float, direct_input: Variant) -> Array[Dictionary]:
	var events := _input_events_from(direct_input)
	if events.is_empty() and input_stream != null and input_stream.has_method("poll_frame"):
		events = _input_events_from(input_stream.poll_frame(position_sec))
	return events

func _input_events_from(value: Variant) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				events.append(item.duplicate(true))
	elif value is Dictionary:
		if value.has("input_events") and value.get("input_events") is Array:
			for item in value.get("input_events", []):
				if item is Dictionary:
					events.append(item.duplicate(true))
		elif value.has("contract") and value.has("event"):
			events.append(value.duplicate(true))
	return events

func _process_mode_output(emitted: Array) -> Array:
	var dispatchable: Array = []
	var aggregate_items: Array = []
	for item in emitted:
		if _is_fragment(item):
			var fragment := _to_dictionary(item)
			_capture_fragment(fragment)
			dispatchable.append_array(_array_from(fragment.get("events", [])))
			dispatchable.append_array(_array_from(fragment.get("judgements", [])))
			dispatchable.append_array(_events_from_score_deltas(_array_from(fragment.get("score_deltas", []))))
			aggregate_items.append_array(_array_from(fragment.get("judgements", [])))
			aggregate_items.append_array(_array_from(fragment.get("score_deltas", [])))
		else:
			if _is_score_delta(item) or _is_judgement(item):
				if _is_score_delta(item) and not _is_judgement(item):
					dispatchable.append_array(_events_from_score_deltas([item]))
				else:
					dispatchable.append(item)
				aggregate_items.append(item)
			else:
				dispatchable.append(item)
			_capture_judgement_or_delta(item)

	var events := _dispatcher.dispatch_many(dispatchable)
	_score.apply_events(aggregate_items if not aggregate_items.is_empty() else events)
	return events

func _capture_fragment(value: Variant) -> void:
	if not _is_fragment(value):
		return
	var fragment := _to_dictionary(value)
	_mode_fragments.append(fragment)
	for judgement in _array_from(fragment.get("judgements", [])):
		_capture_judgement_or_delta(judgement)
	for delta in _array_from(fragment.get("score_deltas", [])):
		_capture_judgement_or_delta(delta)

func _capture_judgement_or_delta(value: Variant) -> void:
	var normalized := _to_dictionary(value)
	if normalized.is_empty():
		return
	if _is_judgement(normalized):
		_judgements.append(normalized)
	if _is_score_delta(normalized):
		_score_deltas.append(normalized)

func _is_fragment(value: Variant) -> bool:
	if value is ModeRunFragment:
		return true
	var normalized := _to_dictionary(value)
	return normalized.has("fragment_type") or normalized.has("score_deltas") or normalized.has("judgements")

func _is_judgement(value: Variant) -> bool:
	if value is RefCounted and value.get_script() == preload("res://addons/aerobeat-mode-core/src/data_types/mode_judgement_event.gd"):
		return true
	var normalized := _to_dictionary(value)
	return String(normalized.get("event_type", normalized.get("type", ""))) == ModeEvent.TYPE_JUDGEMENT

func _is_score_delta(value: Variant) -> bool:
	if value is ModeScoreDelta:
		return true
	var normalized := _to_dictionary(value)
	return normalized.has("score_delta") or String(normalized.get("event_type", normalized.get("type", ""))) == ModeEvent.TYPE_SCORE_DELTA

func _events_from_score_deltas(deltas: Array) -> Array:
	var events: Array = []
	for delta in deltas:
		var normalized := _to_dictionary(delta)
		if not normalized.is_empty():
			events.append({
				"event_type": ModeEvent.TYPE_SCORE_DELTA,
				"mode_id": normalized.get("mode_id", config.get("mode_id") if config != null else ""),
				"target_ref": normalized.get("target_ref", {}),
				"position_sec": normalized.get("position_sec", _last_position_sec),
				"metadata": normalized.duplicate(true),
				"score_delta": normalized.get("score_delta", 0),
				"combo_delta": normalized.get("combo_delta", 0),
				"accuracy_delta": normalized.get("accuracy_delta", 0.0),
				"judgement": normalized.get("judgement", "")
			})
	return events

static func _array_from(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []

static func _to_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	if value is RefCounted and value.has_method("to_dict"):
		return value.to_dict()
	return {}
