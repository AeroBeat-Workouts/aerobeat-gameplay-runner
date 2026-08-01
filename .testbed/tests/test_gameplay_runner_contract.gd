extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const GameplayRunConfig := preload("res://addons/aerobeat-gameplay-runner/src/data_types/gameplay_run_config.gd")
const GameplaySession := preload("res://addons/aerobeat-gameplay-runner/src/runtime/gameplay_session.gd")

class ContractModeRunner:
	extends RefCounted

	var started := false
	var stopped := false
	var tick_count := 0
	var completed := false

	func start(config: RefCounted) -> Dictionary:
		started = config != null
		return {"runner": "started"}

	func tick(delta_sec: float, input_frame: Dictionary) -> Array:
		tick_count += 1
		completed = tick_count >= 2
		return [
			{
				"type": "score_delta",
				"score": 25,
				"detail": {
					"delta_sec": delta_sec,
					"lane": input_frame.get("lane", "")
				}
			}
		]

	func is_complete() -> bool:
		return completed

	func stop(reason: String = "") -> Dictionary:
		stopped = not reason.is_empty()
		return {"reason": reason}

func test_session_runs_mode_contract_and_returns_result() -> void:
	var session := GameplaySession.new()
	var config := GameplayRunConfig.new({
		"mode_id": "contract_mode",
		"chart_id": "contract_chart"
	})
	var runner := ContractModeRunner.new()

	var state := session.start(config, runner)
	assert_eq(state, "running")
	assert_true(runner.started)

	session.tick(0.25, {"lane": "left"})
	session.tick(0.25, {"lane": "right"})

	assert_eq(session.get_state(), "completed")
	assert_eq(session.get_score(), 50)
	assert_eq(session.get_event_history().size(), 2)

	var result := session.stop("contract_test")
	assert_true(runner.stopped)
	assert_eq(result.state, "completed")
	assert_eq(result.score, 50)
	assert_eq(result.reason, "contract_test")
