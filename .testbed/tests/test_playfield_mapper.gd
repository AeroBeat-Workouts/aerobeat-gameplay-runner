extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const PlayfieldMapperScript := preload("res://scripts/playfield_mapper.gd")

func test_frozen_top_left_grid_semantics_and_godot_y_inversion() -> void:
	var mapper := PlayfieldMapperScript.new({})
	var cell_0 := mapper.cell_center_to_world(0)
	var cell_3 := mapper.cell_center_to_world(3)
	var cell_8 := mapper.cell_center_to_world(8)
	var cell_11 := mapper.cell_center_to_world(11)

	assert_lt(cell_0.x, 0.0, "Cell 0 should be visual upper-left X.")
	assert_gt(cell_0.y, 0.0, "Cell 0 should be visual upper-left Y after Godot Y inversion.")
	assert_gt(cell_3.x, 0.0, "Cell 3 should be upper-right X.")
	assert_gt(cell_3.y, 0.0, "Cell 3 should stay top row.")
	assert_lt(cell_8.x, 0.0, "Cell 8 should be lower-left X.")
	assert_lt(cell_8.y, 0.0, "Cell 8 should be lower row.")
	assert_gt(cell_11.x, 0.0, "Cell 11 should be lower-right X.")
	assert_lt(cell_11.y, 0.0, "Cell 11 should be lower row.")
	assert_eq(mapper.cell_to_row_col(0), Vector2i(0, 0))
	assert_eq(mapper.cell_to_row_col(3), Vector2i(3, 0))
	assert_eq(mapper.cell_to_row_col(8), Vector2i(0, 2))
	assert_eq(mapper.cell_to_row_col(11), Vector2i(3, 2))

func test_fallback_scale_uses_public_cell_dimensions() -> void:
	var mapper := PlayfieldMapperScript.new({})
	assert_true(mapper.is_fallback_scale())
	assert_eq(mapper.get_playfield_size(), Vector2(2.4, 1.5))
	assert_eq(mapper.get_cell_size(), Vector2(0.6, 0.5))

func test_athlete_height_scale_uses_height_ratio_and_cell_aspect() -> void:
	var mapper := PlayfieldMapperScript.new({"scale": {"athlete_height_m": 2.0}})
	assert_false(mapper.is_fallback_scale())
	assert_almost_eq(mapper.get_playfield_size().y, 1.9, 0.0001)
	assert_almost_eq(mapper.get_cell_size().y, 1.9 / 3.0, 0.0001)
	assert_almost_eq(mapper.get_cell_size().x, (1.9 / 3.0) * 1.2, 0.0001)

func test_clamped_continuous_nose_mapping() -> void:
	var mapper := PlayfieldMapperScript.new({})
	var inside := mapper.anchor_to_rig_position({"x": 0.25, "y": 0.75})
	var outside := mapper.anchor_to_rig_position({"x": -0.5, "y": 1.5})
	var upper_left_bound := mapper.normalized_to_world(Vector2(0.0, 1.0), 0.0)

	assert_almost_eq(inside.x, -0.6, 0.0001)
	assert_almost_eq(inside.y, -0.375, 0.0001)
	assert_almost_eq(outside.x, upper_left_bound.x, 0.0001)
	assert_almost_eq(outside.y, upper_left_bound.y, 0.0001)

func test_target_spawn_and_audio_clock_travel_rule() -> void:
	var mapper := PlayfieldMapperScript.new({})
	assert_almost_eq(mapper.target_spawn_z(), -13.0, 0.0001)
	assert_almost_eq(mapper.target_z_at_time(10.0, 8.5), -13.0, 0.0001)
	assert_almost_eq(mapper.target_z_at_time(10.0, 10.0), -1.0, 0.0001)
