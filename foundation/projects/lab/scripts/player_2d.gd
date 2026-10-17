extends CharacterBody2D
@export var speed: float = 220.0
var animation_time: float = 0.0
var frames: Array[AtlasTexture] = []
@onready var sprite: Sprite2D = $Sprite2D
var benchmark_motion: bool = false

func _ready() -> void:
	for i in 4:
		frames.append(BAArt.ranger_texture(i))
	sprite.texture = frames[0]
	sprite.scale = Vector2(0.28, 0.28)
	sprite.offset.y = -frames[0].get_height() * 0.48
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	var axis := Input.get_vector("ba_left", "ba_right", "ba_up", "ba_down")
	if benchmark_motion:
		axis = Vector2(cos(Telemetry.elapsed * 0.7), sin(Telemetry.elapsed * 0.7))
	velocity = axis * speed
	move_and_slide()
	animation_time += delta
	if axis.length_squared() > 0.01:
		Telemetry.input_steps += 1
		sprite.texture = frames[int(animation_time * 9.0) % 4]
		if absf(axis.x) > 0.05: sprite.flip_h = axis.x < 0
	else:
		sprite.texture = frames[0]
