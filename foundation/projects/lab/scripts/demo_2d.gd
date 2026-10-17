extends Node2D
var moving_light: PointLight2D
var phase: float = 0.0

func _ready() -> void:
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = BAArt.floor_texture()
	floor_sprite.region_enabled = true
	floor_sprite.region_rect = Rect2(0, 0, 2400, 1800)
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.z_index = -5
	add_child(floor_sprite)
	for pos: Vector2 in [Vector2(-700, 0), Vector2(700, 0), Vector2(0, -500), Vector2(0, 500), Vector2(-210, -120), Vector2(260, 150), Vector2(70, -260)]:
		var size := Vector2(88, 88)
		if absf(pos.x) == 700: size = Vector2(50, 1050)
		elif absf(pos.y) == 500: size = Vector2(1450, 50)
		_wall(pos, size)
	for pos: Vector2 in [Vector2(-380, -220), Vector2(350, 220), Vector2(160, -200)]:
		var light := PointLight2D.new()
		light.position = pos
		light.texture = BAArt.light_texture()
		light.texture_scale = 4
		light.color = Color("71e4cf") if pos.x < 0 else Color("edb778")
		light.energy = 1.4
		light.shadow_enabled = true
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF13
		add_child(light)
		moving_light = light

func _wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	var polygon := PackedVector2Array([-size / 2, Vector2(size.x, -size.y) / 2, size / 2, Vector2(-size.x, size.y) / 2])
	visual.polygon = polygon
	visual.color = Color("42525b")
	body.add_child(visual)
	var shadow := LightOccluder2D.new()
	var occluder := OccluderPolygon2D.new()
	occluder.polygon = polygon
	shadow.occluder = occluder
	body.add_child(shadow)
	add_child(body)

func _process(delta: float) -> void:
	phase += delta
	if moving_light:
		moving_light.position = Vector2(170 + sin(phase * 0.45) * 260, -180 + cos(phase * 0.45) * 110)
