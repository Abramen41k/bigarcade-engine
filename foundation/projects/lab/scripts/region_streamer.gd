class_name BARegionStreamer
extends Node
## Worker tasks produce pure region data. SceneTree mutations stay on the main thread.
signal region_ready(key: Vector2i, data: Dictionary, state: Dictionary)
signal region_removed(key: Vector2i)
@export var seed: int = 20261016
@export var side: int = 16
@export var radius: int = 1
var wanted: Dictionary = {}
var loaded: Dictionary = {}
var states: Dictionary = {}
var pending: Dictionary = {}
var completed: Array[Dictionary] = []
var mutex := Mutex.new()
var epoch: int = 0
var native: RefCounted
var center := Vector2i(2147483647, 2147483647)

func _ready() -> void:
	native = ClassDB.instantiate("BigArcadeRuntime")

func update_position(position: Vector3) -> void:
	var next := Vector2i(floori(position.x / side), floori(position.z / side))
	if next == center:
		return
	center = next
	wanted.clear()
	for z in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var key := Vector2i(x, z)
			wanted[key] = true
	for key: Vector2i in loaded.keys():
		if not wanted.has(key):
			loaded.erase(key)
			region_removed.emit(key)
	_schedule_missing()

func _schedule_missing() -> void:
	# Teleports can change demand faster than tasks finish. Bound work in flight,
	# and refill after stale results have been consumed, even if the player stops.
	var limit := (radius * 2 + 1) * (radius * 2 + 1)
	var keys: Array = wanted.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(center) < b.distance_squared_to(center))
	for key: Vector2i in keys:
		if pending.size() >= limit: break
		if not loaded.has(key) and not pending.has(key):
			pending[key] = WorkerThreadPool.add_task(_generate.bind(key, seed, epoch), false, "BigArcade region")

func _generate(key: Vector2i, task_seed: int, task_epoch: int) -> void:
	var data: Dictionary = native.call("generate_region", task_seed, key, side)
	mutex.lock()
	completed.append({"key": key, "data": data, "epoch": task_epoch})
	mutex.unlock()

func _process(_delta: float) -> void:
	mutex.lock()
	var ready := completed.duplicate()
	completed.clear()
	mutex.unlock()
	# Budget one region instantiation per rendered frame; retain other results.
	var applied := false
	for item: Dictionary in ready:
		var key: Vector2i = item["key"]
		if applied:
			mutex.lock()
			completed.append(item)
			mutex.unlock()
			continue
		if pending.has(key):
			WorkerThreadPool.wait_for_task_completion(int(pending[key]))
			pending.erase(key)
		if int(item["epoch"]) != epoch or not wanted.has(key):
			continue
		loaded[key] = item["data"]
		var id: String = item["data"]["id"]
		region_ready.emit(key, item["data"], states.get(id, {}))
		applied = true
	_schedule_missing()

func set_object_state(region_id: String, object_id: String, state: Dictionary) -> void:
	if not states.has(region_id): states[region_id] = {}
	states[region_id][object_id] = state.duplicate(true)

func save_world(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema": 1, "generator": 1, "seed": seed, "states": states}, "\t"))
	return OK

func restore_world(path: String) -> Error:
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema") != 1 or data.get("generator") != 1 or data.get("seed") != seed or not data.get("states") is Dictionary:
		return ERR_INVALID_DATA
	# Validate the entire candidate before modifying live state. Scene consumers
	# require region -> object -> Dictionary, not just a top-level Dictionary.
	for region: Variant in data["states"].values():
		if not region is Dictionary: return ERR_INVALID_DATA
		for object_state: Variant in region.values():
			if not object_state is Dictionary: return ERR_INVALID_DATA
	# JSON only: no deserialization of executable Godot Objects or resources.
	states = data["states"].duplicate(true)
	return OK

func _exit_tree() -> void:
	epoch += 1
	for task: int in pending.values():
		WorkerThreadPool.wait_for_task_completion(task)
	pending.clear()
