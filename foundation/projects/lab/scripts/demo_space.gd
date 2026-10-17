extends Node3D
@export_enum("isometric", "3d") var mode: String = "3d"
var streamer: BARegionStreamer
var regions: Dictionary = {}
var beacons: Dictionary = {}
var cycle: float = 0.0
var activated: int = 0
@onready var player: CharacterBody3D = $Player
@onready var sun: DirectionalLight3D = $Sun

func _ready() -> void:
	streamer = BARegionStreamer.new()
	streamer.seed = int(ProjectSettings.get_setting("bigarcade/world/seed", 20261016))
	streamer.region_ready.connect(_region_ready)
	streamer.region_removed.connect(_region_removed)
	add_child(streamer)
	streamer.restore_world("user://world-" + mode + ".json")
	streamer.update_position(player.position)
	for i in 3:
		var light := OmniLight3D.new()
		light.position = Vector3(5 + i * 4, 3.5, 8)
		light.light_color = Color("69dacb") if i % 2 == 0 else Color("f2ba79")
		light.light_energy = 3
		light.omni_range = 11
		light.shadow_enabled = true
		add_child(light)
	Telemetry.profile_changed.connect(_apply_profile)
	_apply_profile()

func _apply_profile() -> void:
	sun.shadow_enabled = Telemetry.quality != "low"
	for node in get_children():
		if node is OmniLight3D: node.shadow_enabled = Telemetry.quality == "high"
	var environment: Environment = $WorldEnvironment.environment
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.sdfgi_enabled = forward_plus and Telemetry.quality == "high"
	environment.volumetric_fog_enabled = forward_plus and Telemetry.quality == "high"

func _region_ready(key: Vector2i, data: Dictionary, state: Dictionary) -> void:
	if regions.has(key): return
	var node := Node3D.new()
	node.name = "Region_%d_%d" % [key.x, key.y]
	node.position = Vector3(key.x * streamer.side, 0, key.y * streamer.side)
	add_child(node)
	regions[key] = node
	var side := float(streamer.side)
	var ground := StaticBody3D.new()
	ground.position = Vector3(side / 2.0, -0.25, side / 2.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(side, 0.5, side)
	collision.shape = shape
	ground.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	mesh.material = BAArt.material(Color("263a40") if (key.x + key.y) % 2 == 0 else Color("2d4044"), 0.83)
	visual.mesh = mesh
	ground.add_child(visual)
	node.add_child(ground)
	var cells: PackedInt32Array = data["cells"]
	var positions: Array[Vector3] = []
	for z in streamer.side:
		for x in streamer.side:
			if cells[z * streamer.side + x] == 1:
				positions.append(Vector3(x + 0.5, 0.8, z + 0.5))
	var columns := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	var stone := BoxMesh.new()
	stone.size = Vector3(0.76, 1.6, 0.76)
	stone.material = BAArt.material(Color("607078"), 0.55, 0.2)
	multi.mesh = stone
	multi.instance_count = positions.size()
	var obstacles := StaticBody3D.new()
	for i in positions.size():
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
		multi.set_instance_color(i, Color(0.75 + float(i % 4) * 0.08, 0.87, 0.89))
		var solid := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = stone.size
		solid.shape = box
		solid.position = positions[i]
		obstacles.add_child(solid)
	columns.multimesh = multi
	node.add_child(columns)
	node.add_child(obstacles)
	var beacon := MeshInstance3D.new()
	beacon.position = Vector3(side / 2, 0.75, side / 2)
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.16
	beacon_mesh.bottom_radius = 0.36
	beacon_mesh.height = 1.4
	beacon.mesh = beacon_mesh
	var lit: bool = bool(state.get("beacon", {}).get("activated", false))
	var mat := BAArt.material(Color("d5ac69"), 0.26, 0.8)
	mat.emission_enabled = true
	mat.emission = Color("75f3cf") if lit else Color("5a4230")
	mat.emission_energy_multiplier = 2.0 if lit else 0.3
	beacon.material_override = mat
	node.add_child(beacon)
	beacons[key] = {"node": beacon, "id": data["id"], "activated": lit}

func _region_removed(key: Vector2i) -> void:
	if regions.has(key):
		regions[key].queue_free()
		regions.erase(key)
	beacons.erase(key)

func interact() -> bool:
	for key: Vector2i in beacons:
		var item: Dictionary = beacons[key]
		var node: MeshInstance3D = item["node"]
		if node.global_position.distance_to(player.global_position) < 2.3 and not item["activated"]:
			item["activated"] = true
			node.material_override.emission = Color("75f3cf")
			node.material_override.emission_energy_multiplier = 2
			streamer.set_object_state(item["id"], "beacon", {"activated": true})
			streamer.save_world("user://world-" + mode + ".json")
			activated += 1
			return true
	return false

func _physics_process(_delta: float) -> void:
	if streamer:
		streamer.update_position(player.global_position)
	if Input.is_action_just_pressed("ba_interact"): interact()

func _process(delta: float) -> void:
	cycle += delta
	sun.rotation_degrees = Vector3(-55 + sin(cycle * 0.035) * 15, -35 + cycle * 0.7, 0)

func _exit_tree() -> void:
	if streamer:
		streamer.save_world("user://world-" + mode + ".json")
