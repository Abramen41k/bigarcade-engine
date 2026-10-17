class_name BAArt
extends RefCounted

static func material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

static func light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0)
	texture.width = 256
	texture.height = 256
	return texture

static func floor_texture() -> CanvasTexture:
	var diffuse := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var normal := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var edge := minf(minf(x, 63 - x), minf(y, 63 - y))
			var shade := 0.16 + float((x * 13 + y * 7) % 17) * 0.001
			if edge < 2: shade *= 0.5
			diffuse.set_pixel(x, y, Color(shade * 0.8, shade, shade * 1.08))
			var nx := -0.45 if x < 4 else (0.45 if x > 59 else 0.0)
			var ny := -0.45 if y < 4 else (0.45 if y > 59 else 0.0)
			var n := Vector3(nx, ny, 1).normalized()
			normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	var texture := CanvasTexture.new()
	texture.diffuse_texture = ImageTexture.create_from_image(diffuse)
	texture.normal_texture = ImageTexture.create_from_image(normal)
	texture.specular_color = Color(0.35, 0.4, 0.45)
	texture.specular_shininess = 0.3
	return texture

static func ranger_texture(frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/rpg.png")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg.json"))
	var names := ["ranger-idle", "ranger-step-a", "ranger-idle", "ranger-step-b"]
	var rect: Dictionary = data["frames"][names[frame % 4]]["frame"]
	atlas.region = Rect2(rect["x"], rect["y"], rect["w"], rect["h"])
	return atlas
