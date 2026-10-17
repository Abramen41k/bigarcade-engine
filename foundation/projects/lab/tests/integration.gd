extends SceneTree
var checks: int = 0
var failed: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failed.append(description)
		push_error("FAILED: " + description)

func frames(count: int) -> void:
	for i in count: await physics_frame

func _run() -> void:
	await process_frame
	verify(ClassDB.class_exists("BigArcadeRuntime"), "native module registered")
	if not ClassDB.class_exists("BigArcadeRuntime"):
		quit(1)
		return
	var runtime: RefCounted = ClassDB.instantiate("BigArcadeRuntime")
	verify(runtime.call("get_version") == "0.2.0-dev", "fork version")
	var a: Dictionary = runtime.call("generate_region", 42, Vector2i(-1, 1), 16)
	var b: Dictionary = runtime.call("generate_region", 42, Vector2i(-1, 1), 16)
	verify(a["cells"] == b["cells"], "native generation deterministic through binding")
	verify(BAArt.ranger_texture(0).get_width() > 100, "0.1 atlas imported")
	var world := BARegionStreamer.new()
	root.add_child(world)
	world.update_position(Vector3(-0.1, 0, -0.1))
	for i in 240:
		if world.loaded.size() == 9: break
		await process_frame
	verify(world.loaded.size() == 9, "nine regions stream in")
	verify(world.center == Vector2i(-1, -1), "negative coordinates use floor")
	var region_id := "ba:%d:-1:-1" % world.seed
	world.set_object_state(region_id, "beacon", {"activated": true})
	verify(world.save_world("user://integration-world.json") == OK, "world save")
	world.states.clear()
	verify(world.restore_world("user://integration-world.json") == OK, "world restore")
	verify(world.states[region_id]["beacon"]["activated"], "object state restored")
	var malformed := FileAccess.open("user://integration-malformed.json", FileAccess.WRITE)
	malformed.store_string(JSON.stringify({"schema": 1, "generator": 1, "seed": world.seed, "states": {region_id: {"beacon": "invalid object state"}}}))
	malformed.close()
	verify(world.restore_world("user://integration-malformed.json") == ERR_INVALID_DATA, "malformed nested state is rejected")
	verify(world.states.get(region_id, {}).get("beacon", {}) is Dictionary, "failed restore preserves existing state")
	world.restore_world("user://integration-world.json")
	for i in 16:
		world.update_position(Vector3(i * 160, 0, i * 160))
	verify(world.pending.size() <= 9, "rapid teleports keep pending generation bounded")
	world.update_position(Vector3(96, 0, 96))
	for i in 240:
		if world.loaded.size() == 9 and world.pending.is_empty(): break
		await process_frame
	verify(world.loaded.size() <= 9 and not world.loaded.has(Vector2i(-1,-1)), "distant regions unloaded")
	world.queue_free()
	await process_frame
	for kind: String in ["2d", "isometric", "3d"]:
		var scene: Node = load("res://scenes/demo_" + kind + ".tscn").instantiate()
		root.add_child(scene)
		await frames(90)
		var player: Node = scene.get_node("Player")
		var start: Variant = player.position
		Input.action_press("ba_right")
		await frames(25)
		Input.action_release("ba_right")
		verify(player.position.distance_to(start) > 0.1, kind + " moves with normal physics")
		if kind != "2d":
			verify(player.position.y > -0.2, kind + " collides with ground")
			verify(scene.regions.size() > 0 and scene.regions.size() <= 9, kind + " bounded visible regions")
		else:
			player.position = Vector2(610, 0)
			player.reset_physics_interpolation()
			Input.action_press("ba_right")
			await frames(90)
			Input.action_release("ba_right")
			verify(player.position.x < 665, "2D wall prevents penetration")
		root.remove_child(scene)
		scene.queue_free()
		await process_frame
	var report := {"checks": checks, "failed": failed, "godot": Engine.get_version_info(), "display": DisplayServer.get_name()}
	var file := FileAccess.open("user://integration-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("BIGARCADE_INTEGRATION ", JSON.stringify(report))
	quit(0 if failed.is_empty() else 1)
