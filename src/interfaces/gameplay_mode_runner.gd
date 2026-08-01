extends RefCounted
## Interface documentation for concrete gameplay mode runners.
##
## Expected methods:
## - start(config: GameplayRunConfig) -> Dictionary
## - tick(delta_sec: float, input_frame: Dictionary) -> Array[Dictionary]
## - is_complete() -> bool
## - stop(reason: String = "") -> Dictionary

func start(_config: RefCounted) -> Dictionary:
	return {}

func tick(_delta_sec: float, _input_frame: Dictionary) -> Array:
	return []

func is_complete() -> bool:
	return false

func stop(_reason: String = "") -> Dictionary:
	return {}
