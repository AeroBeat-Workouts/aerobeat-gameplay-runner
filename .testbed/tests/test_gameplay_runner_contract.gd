extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const GameplayInputStream := preload("res://addons/aerobeat-gameplay-runner/src/interfaces/gameplay_input_stream.gd")
const GameplayRunConfig := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_config.gd")
const GameplayRunState := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_state.gd")
const GameplaySession := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_session.gd")
const FakeClock := preload("res://tests/support/fake_gameplay_clock.gd")
const FakeInputStream := preload("res://tests/support/fake_gameplay_input_stream.gd")
const ModeRunConfig := preload("res://addons/aerobeat-mode-core/src/data_types/mode_run_config.gd")
const ModeRunFragment := preload("res://addons/aerobeat-mode-core/src/data_types/mode_run_fragment.gd")
const ModeScoreDelta := preload("res://addons/aerobeat-mode-core/src/data_types/mode_score_delta.gd")
const ModeJudgementEvent := preload("res://addons/aerobeat-mode-core/src/data_types/mode_judgement_event.gd")

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
