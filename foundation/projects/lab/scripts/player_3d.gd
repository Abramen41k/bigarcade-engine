extends CharacterBody3D
@export var speed: float = 5.5
@export var isometric: bool = false
var benchmark_motion: bool = false
var phase: float = 0.0
var frames: Array[AtlasTexture] = []
var sprite: Sprite3D
var yaw: float = 0.0
var pitch: float = -0.3
@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	if isometric:
		$Body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		sprite = Sprite3D.new()
		for i in 4: frames.append(BAArt.ranger_texture(i))
		sprite.texture = frames[0]
		sprite.pixel_size = 0.007
		sprite.position.y = 0.95
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = true
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		add_child(sprite)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 18
		camera.position = Vector3(12, 15, 12)
		camera.look_at(global_position)
	else:
		camera.position = Vector3(0, 3.1, 6.7)
		camera.rotation_degrees.x = -15
	reset_physics_interpolation()

func _unhandled_input(event: InputEvent) -> void:
	if isometric: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.003
		pivot.rotation.y = yaw

func _physics_process(delta: float) -> void:
	phase += delta
	var axis := Input.get_vector("ba_left", "ba_right", "ba_up", "ba_down")
	if benchmark_motion: axis = Vector2(0, -1)
	var basis := camera.global_basis
	var direction := basis.x * axis.x + basis.z * axis.y
	direction.y = 0
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor(): velocity.y -= 18 * delta
	elif Input.is_action_just_pressed("ba_jump") and not isometric: velocity.y = 7
	move_and_slide()
	if axis.length_squared() > 0.01:
		Telemetry.input_steps += 1
	if sprite:
		sprite.texture = frames[int(phase * 9) % 4] if axis.length_squared() > 0.01 else frames[0]
		if absf(axis.x) > 0.05: sprite.flip_h = axis.x < 0

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
