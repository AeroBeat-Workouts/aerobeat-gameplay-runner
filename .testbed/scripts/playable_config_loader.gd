extends RefCounted

const SimpleYamlParserScript := preload("res://addons/aerobeat-content-core/validators/simple_yaml_parser.gd")

func load_config(path: String = "res://addons/aerobeat-gameplay-runner/assets/playable_testbed.yaml") -> Dictionary:
	var resolved := path
	if path.begins_with("res://"):
		resolved = ProjectSettings.globalize_path(path)
	var parsed: Variant = SimpleYamlParserScript.new().parse_file(resolved)
	return parsed.duplicate(true) if parsed is Dictionary else {}
