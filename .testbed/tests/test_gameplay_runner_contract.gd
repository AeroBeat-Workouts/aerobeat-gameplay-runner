extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const GameplayInputStream := preload("res://addons/aerobeat-gameplay-runner/src/interfaces/gameplay_input_stream.gd")
const GameplayRunConfig := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_config.gd")
const GameplayRunState := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_state.gd")
const GameplaySession := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_session.gd")
const BoxingInput := preload("res://addons/aerobeat-input-core/src/interfaces/boxing_input.gd")
const BodyCellInput := preload("res://addons/aerobeat-input-core/src/interfaces/body_cell_input.gd")
const FlowInput := preload("res://addons/aerobeat-input-core/src/interfaces/flow_input.gd")
const ContentPackageValidator := preload("res://addons/aerobeat-content-core/validators/content_package_validator.gd")
const SimpleYamlParser := preload("res://addons/aerobeat-content-core/validators/simple_yaml_parser.gd")
const BoxingModeRunner := preload("res://addons/aerobeat-mode-boxing/src/boxing_mode_runner.gd")
const FlowModeRunner := preload("res://addons/aerobeat-mode-flow/src/flow_mode_runner.gd")
const FakeClock := preload("res://tests/support/fake_gameplay_clock.gd")
const FakeInputStream := preload("res://tests/support/fake_gameplay_input_stream.gd")
const ModeRunConfig := preload("res://addons/aerobeat-mode-core/src/data_types/mode_run_config.gd")
const ModeRunFragment := preload("res://addons/aerobeat-mode-core/src/data_types/mode_run_fragment.gd")
const ModeScoreDelta := preload("res://addons/aerobeat-mode-core/src/data_types/mode_score_delta.gd")
const ModeJudgementEvent := preload("res://addons/aerobeat-mode-core/src/data_types/mode_judgement_event.gd")

const BEATSAVER_CASES := [
	{"id": "29be2", "mode": "flow", "difficulty": "ExpertPlus"},
	{"id": "349f2", "mode": "flow", "difficulty": "ExpertPlus"},
	{"id": "2b4e6", "mode": "flow", "difficulty": "ExpertPlus"},
	{"id": "304ea", "mode": "flow", "difficulty": "ExpertPlus"},
	{"id": "48727", "mode": "flow", "difficulty": "Normal"},
	{"id": "48088", "mode": "flow", "difficulty": "Normal"},
	{"id": "48792", "mode": "flow", "difficulty": "Normal"},
	{"id": "47fb6", "mode": "flow", "difficulty": "Normal"},
	{"id": "3d44b", "mode": "boxing", "difficulty": "Normal"},
	{"id": "472d3", "mode": "boxing", "difficulty": "Normal"},
	{"id": "226e", "mode": "boxing", "difficulty": "Expert"},
	{"id": "2f3d7", "mode": "boxing", "difficulty": "Expert"},
	{"id": "4858", "mode": "boxing", "difficulty": "Expert"},
	{"id": "19e5e", "mode": "boxing", "difficulty": "Expert"},
]

class ContractModeRunner:
	extends RefCounted

	var started_with_mode_config := false
	var stopped := false
	var frames: Array = []
	var outputs_by_tick: Array = []
	var completed := false

	func start(config: RefCounted) -> RefCounted:
		started_with_mode_config = config is ModeRunConfig
		return ModeRunFragment.new({
			"fragment_type": ModeRunFragment.TYPE_STARTED,
			"mode_id": config.mode_id,
			"reason": "started"
		})

	func tick(frame: RefCounted) -> Array:
		frames.append(frame.to_dict())
		var index := frames.size() - 1
		if index < outputs_by_tick.size():
			return outputs_by_tick[index]
		return []

	func is_complete() -> bool:
		return completed

	func stop(reason: String = "") -> RefCounted:
		stopped = not reason.is_empty()
		return ModeRunFragment.new({
			"fragment_type": ModeRunFragment.TYPE_STOPPED,
			"mode_id": "contract_mode",
			"reason": reason
		})

func test_session_dispatches_mode_core_frames_in_timeline_order() -> void:
	var session := GameplaySession.new()
	var config := GameplayRunConfig.new({
		"mode_id": "contract_mode",
		"chart_id": "contract_chart",
		"timeline": {
			"chart_events": [
				{"id": "target_1", "position_sec": 0.25},
				{"id": "target_2", "position_sec": 0.50}
			]
		}
	})
	var runner := ContractModeRunner.new()
	runner.outputs_by_tick = [
		[
			ModeJudgementEvent.new({
				"mode_id": "contract_mode",
				"judgement": ModeJudgementEvent.RESULT_HIT,
				"position_sec": 0.25,
				"accuracy": 1.0
			}),
			ModeScoreDelta.new({
				"mode_id": "contract_mode",
				"position_sec": 0.25,
				"score_delta": 25,
				"combo_delta": 1,
				"accuracy_delta": 1.0
			})
		],
		[
			ModeScoreDelta.new({
				"mode_id": "contract_mode",
				"position_sec": 0.50,
				"score_delta": 50,
				"combo_delta": 1,
				"accuracy_delta": 0.5
			})
		]
	]
	var clock := FakeClock.new()
	var stream := FakeInputStream.new([
		FakeInputStream.boxing("straight_left", 0.25),
		FakeInputStream.body_cell("right_wrist_cell_entered", 0.50, 6, 3)
	])

	assert_eq(session.start(config, runner, clock, stream), GameplayRunState.RUNNING)
	assert_true(runner.started_with_mode_config)
	assert_eq(clock.reset_count, 1)
	assert_eq(stream.reset_count, 1)

	clock.set_position(0.25)
	var first_events := session.tick(0.25)
	clock.set_position(0.50)
	var second_events := session.tick(0.25)

	assert_false(clock.advance_called)
	assert_eq(runner.frames[0].chart_events[0].id, "target_1")
	assert_eq(runner.frames[0].input_events[0].event, "straight_left")
	assert_eq(runner.frames[0].input_events[0].args.size(), 0)
	assert_eq(runner.frames[1].chart_events[0].id, "target_2")
	assert_eq(runner.frames[1].input_events[0].event, "right_wrist_cell_entered")
	assert_eq(runner.frames[1].input_events[0].args, [6, 3])
	assert_eq(first_events[0].event_type, "judgement")
	assert_eq(first_events[1].event_type, "score_delta")
	assert_eq(second_events[0].event_type, "score_delta")
	assert_eq(session.get_score(), 75)
	assert_eq(session.get_score_summary().max_combo, 2)

func test_clock_or_mode_completion_sets_terminal_state_without_stopping_mode() -> void:
	var session := GameplaySession.new()
	var config := GameplayRunConfig.new({"mode_id": "contract_mode"})
	var runner := ContractModeRunner.new()
	var clock := FakeClock.new()
	clock.duration_sec = 1.0

	assert_eq(session.start(config, runner, clock), GameplayRunState.RUNNING)
	clock.set_position(1.0)
	session.tick(0.1)

	assert_eq(session.get_state(), GameplayRunState.COMPLETED)
	var result := session.stop("after_completion")
	assert_false(runner.stopped)
	assert_eq(result.state, GameplayRunState.COMPLETED)
	assert_eq(result.duration_sec, 1.0)

func test_fragments_judgements_and_score_deltas_are_aggregated_into_result() -> void:
	var session := GameplaySession.new()
	var config := GameplayRunConfig.new({"mode_id": "contract_mode"})
	var runner := ContractModeRunner.new()
	runner.outputs_by_tick = [
		[
			ModeRunFragment.new({
				"fragment_type": ModeRunFragment.TYPE_SUMMARY,
				"mode_id": "contract_mode",
				"judgements": [
					ModeJudgementEvent.new({
						"mode_id": "contract_mode",
						"judgement": ModeJudgementEvent.RESULT_MISS,
						"position_sec": 0.40,
						"accuracy": 0.0
					})
				],
				"score_deltas": [
					ModeScoreDelta.new({
						"mode_id": "contract_mode",
						"position_sec": 0.42,
						"score_delta": 100,
						"combo_delta": 1,
						"accuracy_delta": 0.5
					})
				]
			})
		]
	]

	session.start(config, runner)
	session.tick(0.5)
	var summary := session.get_score_summary()
	var result := session.stop("summary")

	assert_eq(summary.score, 100)
	assert_eq(summary.hits, 1)
	assert_eq(summary.misses, 1)
	assert_eq(session.get_judgements().size(), 1)
	assert_eq(session.get_score_deltas().size(), 1)
	assert_eq(result.mode_fragments.size(), 3)
	assert_eq(result.judgements[0].judgement, ModeJudgementEvent.RESULT_MISS)
	assert_eq(result.score_deltas[0].score_delta, 100)

func test_fake_input_envelopes_mirror_input_core_signal_contracts() -> void:
	var punch_events := [
		"straight_left",
		"straight_right",
		"uppercut_left",
		"uppercut_right",
		"hook_left",
		"hook_right"
	]
	for event in punch_events:
		var envelope := FakeInputStream.boxing(event, 1.25)
		assert_eq(envelope.contract, GameplayInputStream.CONTRACT_BOXING_V1)
		assert_eq(envelope.args, [])
		assert_true(GameplayInputStream.is_valid_envelope(envelope))

	assert_true(GameplayInputStream.is_valid_envelope(FakeInputStream.body_cell("left_wrist_cell_entered", 1.5, 3, -1)))
	assert_true(GameplayInputStream.is_valid_envelope(FakeInputStream.flow("squat_enabled", 1.75)))
	assert_false(GameplayInputStream.is_valid_envelope(GameplayInputStream.make_envelope(GameplayInputStream.CONTRACT_BOXING_V1, "straight_left", 2.0, [0.8])))

func test_testbed_composes_input_core_contracts_with_real_mode_engines() -> void:
	var boxing_input := BoxingInput.new()
	var body_cell_input := BodyCellInput.new()
	var flow_input := FlowInput.new()

	for event in GameplayInputStream.BOXING_PUNCH_EVENTS:
		assert_true(boxing_input.has_signal(event), "BoxingInput should expose %s" % event)
	for event in GameplayInputStream.BOXING_STATE_EVENTS:
		assert_true(boxing_input.has_signal(event), "BoxingInput should expose %s" % event)
	for event in ["left_wrist_cell_entered", "right_wrist_cell_entered", "nose_cell_entered"]:
		assert_true(body_cell_input.has_signal(event), "BodyCellInput should expose %s" % event)
	for event in GameplayInputStream.FLOW_EVENTS:
		assert_true(flow_input.has_signal(event), "FlowInput should expose %s" % event)

	assert_eq(BoxingModeRunner.new().get_descriptor().mode_id, "boxing")
	assert_eq(FlowModeRunner.new().get_descriptor().mode_id, "flow")
	boxing_input.free()
	body_cell_input.free()
	flow_input.free()

func test_full_run_regressions_run_tiny_fixtures_before_beatsaver_pool() -> void:
	var tiny_boxing := _run_full_session("tiny_boxing", "boxing", [
		{"id": "tiny_straight", "type": "straight_left", "position_sec": 0.25},
		{"id": "tiny_guard", "type": "guard_enabled", "position_sec": 0.50},
	], [
		FakeInputStream.boxing("straight_left", 0.25),
		FakeInputStream.boxing("guard_enabled", 0.50),
	])
	var tiny_flow := _run_full_session("tiny_flow", "flow", [
		{"id": "tiny_left", "type": "note", "hand": "left", "placement": 2, "position_sec": 0.25, "requiresDirection": false},
		{"id": "tiny_squat", "type": "squat", "event": "squat_enabled", "position_sec": 0.50},
	], [
		FakeInputStream.body_cell("left_wrist_cell_entered", 0.25, 2, -1),
		FakeInputStream.flow("squat_enabled", 0.50),
	])

	assert_eq(tiny_boxing.state, GameplayRunState.COMPLETED)
	assert_eq(tiny_flow.state, GameplayRunState.COMPLETED)
	assert_eq(tiny_boxing.judgements.size(), 2)
	assert_eq(tiny_flow.judgements.size(), 2)

	var parser := SimpleYamlParser.new()
	var validator := ContentPackageValidator.new()
	var fixture_root := ProjectSettings.globalize_path("res://addons/aerobeat-content-core/fixtures/beatsaver_regression_pool")
	var completed_ids: Array = []
	for case in BEATSAVER_CASES:
		var package_dir := fixture_root.path_join(String(case.id))
		var validation := validator.validate_song_package_yaml_package(package_dir)
		assert_true(validation.is_valid(), "BeatSaver fixture should validate through content-core: %s" % case.id)

		var root := Dictionary(parser.parse_file(package_dir.path_join("song.package.yaml")))
		var chart_descriptor := _chart_descriptor_for(root, String(case.mode), String(case.difficulty))
		var chart := Dictionary(parser.parse_file(package_dir.path_join(String(chart_descriptor.path))))
		var normalized_chart := _runtime_chart_from_content_chart(chart)
		var inputs := _perfect_inputs_for_chart(String(case.mode), normalized_chart.beats)
		var result := _run_full_session(String(chart.chartId), String(case.mode), normalized_chart.beats, inputs)

		assert_eq(result.state, GameplayRunState.COMPLETED, "BeatSaver run should complete: %s" % case.id)
		assert_eq(result.judgements.size(), normalized_chart.expected_judgements, "BeatSaver run should judge expected targets: %s" % case.id)
		assert_true(result.score > 0, "BeatSaver run should produce score: %s" % case.id)
		completed_ids.append(case.id)

	assert_eq(completed_ids.size(), BEATSAVER_CASES.size())

func _run_full_session(chart_id: String, mode_id: String, chart_events: Array, input_events: Array) -> RefCounted:
	var session := GameplaySession.new()
	var clock := FakeClock.new()
	clock.duration_sec = _chart_duration(chart_events)
	var config := GameplayRunConfig.new({
		"mode_id": mode_id,
		"chart_id": chart_id,
		"chart_data": _mode_chart_data(mode_id, chart_events),
		"metadata": {
			"testbed_full_run": true
		}
	})
	var runner: Variant = BoxingModeRunner.new() if mode_id == "boxing" else FlowModeRunner.new()
	var stream := FakeInputStream.new(input_events)

	assert_eq(session.start(config, runner, clock, stream), GameplayRunState.RUNNING)
	for position_sec in _positions_for(chart_events):
		clock.set_position(position_sec)
		session.tick(0.0)
	clock.set_position(clock.duration_sec)
	session.tick(0.0)
	return session.stop("full_run_complete")

func _mode_chart_data(mode_id: String, chart_events: Array) -> Dictionary:
	if mode_id == "boxing":
		return {"targets": chart_events.duplicate(true)}
	return {"beats": chart_events.duplicate(true)}

func _chart_duration(chart_events: Array) -> float:
	var duration := 0.0
	for event in chart_events:
		if event is Dictionary:
			duration = maxf(duration, float(event.get("end_sec", event.get("end", event.get("position_sec", 0.0)))))
	return duration + 0.75

func _positions_for(chart_events: Array) -> Array:
	var positions := {}
	for event in chart_events:
		if event is Dictionary:
			positions[float(event.get("position_sec", 0.0))] = true
			if event.has("end_sec") or event.has("end"):
				positions[float(event.get("end_sec", event.get("end", event.get("position_sec", 0.0)))) + 0.25] = true
	var ordered := positions.keys()
	ordered.sort()
	return ordered

func _chart_descriptor_for(root: Dictionary, mode_id: String, difficulty: String) -> Dictionary:
	for descriptor in Array(root.get("charts", [])):
		if descriptor is Dictionary and descriptor.get("mode", "") == mode_id and descriptor.get("difficulty", "") == difficulty:
			return descriptor
	return {}

func _runtime_chart_from_content_chart(chart: Dictionary) -> Dictionary:
	var beats: Array = []
	var expected_judgements := 0
	for raw_beat in Array(chart.get("beats", [])):
		if not raw_beat is Dictionary:
			continue
		var beat := Dictionary(raw_beat).duplicate(true)
		beat["position_sec"] = float(beat.get("position_sec", beat.get("start", 0.0)))
		beat["id"] = String(beat.get("id", "%s_%03d" % [chart.get("chartId", "chart"), beats.size()]))
		if chart.get("mode", "") == "boxing":
			beat["type"] = _boxing_runtime_event(String(beat.get("type", "")))
		if chart.get("mode", "") == "flow" and String(beat.get("type", "")) == "bomb":
			beat["cells"] = [int(beat.get("placement", -1))]
			beat["end_sec"] = float(beat.get("end_sec", beat.get("end", beat.position_sec + 0.25)))
		beats.append(beat)
		expected_judgements += 1
	return {
		"beats": beats,
		"expected_judgements": expected_judgements
	}

func _boxing_runtime_event(content_type: String) -> String:
	match content_type:
		"guard":
			return "guard_enabled"
		"squat":
			return "squat_enabled"
		"weave_left":
			return "weave_left_enabled"
		"weave_right":
			return "weave_right_enabled"
		_:
			return content_type

func _perfect_inputs_for_chart(mode_id: String, beats: Array) -> Array:
	var inputs: Array = []
	for beat in beats:
		if not beat is Dictionary:
			continue
		var position_sec := float(beat.get("position_sec", 0.0))
		if mode_id == "boxing":
			inputs.append(FakeInputStream.boxing(String(beat.get("type", "")), position_sec))
		elif String(beat.get("type", "")) == "note" or String(beat.get("type", "")) == "burst" or String(beat.get("type", "")) == "arc":
			var hand := String(beat.get("hand", "left"))
			var event_name := "%s_wrist_cell_entered" % hand
			var direction := int(beat.get("direction", -1))
			inputs.append(FakeInputStream.body_cell(event_name, position_sec, int(beat.get("placement", beat.get("startPlacement", 0))), direction))
		elif String(beat.get("type", "")) == "squat":
			inputs.append(FakeInputStream.flow(String(beat.get("event", "squat_enabled")), position_sec))
	return inputs
