extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const TargetRegions := preload("res://scripts/playable_target_regions.gd")

func test_flow_cells_include_all_authored_multi_placements() -> void:
	var regions := TargetRegions.new(4, 3)
	assert_eq(regions.flow_cells_for_target({"type": "burst", "placement": 1, "tailPlacement": 5}), [1, 5])
	assert_eq(regions.flow_cells_for_target({"type": "arc", "startPlacement": 2, "endPlacement": 10}), [2, 10])
	assert_eq(regions.flow_cells_for_target({"type": "obstacle", "cells": [0, 1, 4, 5]}), [0, 1, 4, 5])

func test_flow_cells_dedupe_and_clamp_authored_cells() -> void:
	var regions := TargetRegions.new(4, 3)
	assert_eq(regions.flow_cells_for_target({"placement": 5, "tailPlacement": 5, "cells": [12, -1]}), [5, 11, 0])

func test_boxing_punches_remain_semantic_center_cells() -> void:
	var regions := TargetRegions.new(4, 3)
	assert_eq(regions.boxing_cells_for_target({"type": "straight_left"}), [5])
	assert_eq(regions.boxing_cells_for_target({"type": "hook_right"}), [6])

func test_boxing_transition_regions_use_center_and_blocked_regions() -> void:
	var regions := TargetRegions.new(4, 3)
	assert_eq(regions.boxing_cells_for_target({"event": "guard_enabled"}), [1, 2, 5, 6, 9, 10])
	assert_eq(regions.boxing_cells_for_target({"event": "squat_enabled"}), [0, 1, 2, 3, 4, 5, 6, 7])
	assert_eq(regions.boxing_cells_for_target({"event": "weave_left_enabled"}), [0, 1, 4, 5, 8, 9])
	assert_eq(regions.boxing_cells_for_target({"event": "weave_right_disabled"}), [2, 3, 6, 7, 10, 11])

func test_debug_overlay_toggles_are_independent() -> void:
	var regions := TargetRegions.new(4, 3)
	var debug_config := {
		"show_body_pose_overlay": false,
		"show_body_grid_overlay": false,
		"show_nose_marker": true,
		"show_left_wrist_marker": false,
		"show_right_wrist_marker": true,
	}
	assert_true(regions.debug_pose_overlay_visible(debug_config, 1500, 2000), "fade window should keep pose overlay visible")
	assert_false(regions.debug_pose_overlay_visible(debug_config, 2500, 2000), "pose overlay toggle should not force visibility after fade")
	assert_false(regions.debug_grid_visible(debug_config), "grid visibility should obey its own toggle")
	assert_true(regions.debug_marker_enabled(debug_config, "nose"))
	assert_false(regions.debug_marker_enabled(debug_config, "left_wrist"))
	assert_true(regions.debug_marker_enabled(debug_config, "right_wrist"))
