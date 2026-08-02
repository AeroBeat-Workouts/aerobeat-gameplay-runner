extends RefCounted
## Deprecated runner-local bridge. Concrete modes should implement ModeRunner
## from aerobeat-mode-core.
##
## Expected methods:
## - start(config: ModeRunConfig) -> ModeRunFragment
## - tick(frame: ModeTickFrame) -> Array
## - is_complete() -> bool
## - stop(reason: String = "") -> ModeRunFragment

func start(_config: RefCounted) -> RefCounted:
	return null

func tick(_frame: RefCounted) -> Array:
	return []

func is_complete() -> bool:
	return false

func stop(_reason: String = "") -> RefCounted:
	return null
