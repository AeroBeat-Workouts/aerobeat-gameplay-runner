extends Node

const AeroEnvironmentLoaderScript := preload("res://addons/aerobeat-environment-loader/src/AeroEnvironmentLoader.gd")
const AeroEnvironmentConstants := preload("res://addons/aerobeat-environment-core/src/contracts/globals/aero_environment_constants.gd")

signal status_changed(message: String)

var loader: Node = null

func setup(canvas_root: Control, world_root: Node3D) -> void:
	if loader == null:
		loader = AeroEnvironmentLoaderScript.new()
		loader.name = "AeroEnvironmentLoader"
		loader.create_default_roots = false
		add_child(loader)
	loader.canvas_root_path = loader.get_path_to(canvas_root)
	loader.world_root_path = loader.get_path_to(world_root)
	loader.environment_load_started.connect(func(request: Dictionary) -> void:
		status_changed.emit("Environment loading: %s" % request.get("asset_path", ""))
	)
	loader.environment_load_succeeded.connect(func(result: Dictionary) -> void:
		status_changed.emit("Environment ready: %s" % result.get("kind", ""))
	)
	loader.environment_load_failed.connect(func(error: Dictionary) -> void:
		status_changed.emit("Environment failed: %s" % error.get("message", error.get("error_code", "")))
	)

func load_environment_file(path: String) -> void:
	if loader == null:
		status_changed.emit("Environment loader unavailable")
		return
	var kind := _kind_for_path(path)
	if kind.is_empty():
		status_changed.emit("Unsupported environment format. Supported: %s" % JSON.stringify(AeroEnvironmentConstants.OFFICIAL_FORMATS))
		return
	loader.load_environment({
		"request_id": "runner_testbed_%d" % Time.get_ticks_msec(),
		"kind": kind,
		"asset_path": path,
		"fit_mode": AeroEnvironmentConstants.FIT_MODE_COVER,
		"metadata": {"owner": "runner_testbed"}
	})

func _kind_for_path(path: String) -> String:
	var lower := path.to_lower()
	for kind in AeroEnvironmentConstants.SUPPORTED_KINDS:
		var format := String(AeroEnvironmentConstants.OFFICIAL_FORMATS.get(kind, ""))
		if not format.is_empty() and lower.ends_with(format):
			return String(kind)
	return ""
