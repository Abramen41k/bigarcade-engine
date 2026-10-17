extends Node
const SCENES := {"2d": "res://scenes/demo_2d.tscn", "isometric": "res://scenes/demo_isometric.tscn", "3d": "res://scenes/demo_3d.tscn"}
var active: Node
var info: Label
var status: Label
var fps_button: Button
var scene_key: String = "2d"
var benchmark: bool = false
var duration: float = 10.0
var output: String = ""
var capture: String = ""
var ending: bool = false
var wall_started: int = 0
var ui_accumulator: float = 0.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--benchmark": benchmark = true
		elif arg.begins_with("--scene="): scene_key = arg.trim_prefix("--scene=")
		elif arg.begins_with("--duration="): duration = maxf(3.0, float(arg.trim_prefix("--duration=")))
		elif arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--fps="): Telemetry.set_target(int(arg.trim_prefix("--fps=")))
		elif arg.begins_with("--screenshot="): capture = arg.trim_prefix("--screenshot=")
	if not SCENES.has(scene_key): scene_key = "2d"
	_create_ui()
	switch_scene(scene_key)
	wall_started = Time.get_ticks_msec()

func switch_scene(key: String) -> void:
	if active:
		remove_child(active)
		active.queue_free()
	Telemetry.reset(key)
	scene_key = key
	active = load(SCENES[key]).instantiate()
	add_child(active)
	active.get_node("Player").set("benchmark_motion", benchmark)
	status.text = "2D / DYNAMIC LIGHT + NORMALS" if key == "2d" else ("2.5D / ORTHOGRAPHIC + SPRITE IN 3D" if key == "isometric" else "3D / PBR + STREAMED REGIONS")

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 112
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.075, 0.95)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 15
	style.content_margin_bottom = 12
	style.border_width_bottom = 1
	style.border_color = Color("294149")
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	rows.add_child(header)
	var title := Label.new()
	title.text = "BIGARCADE  /  FOUNDATION LAB"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for key: String in SCENES:
		var button := Button.new()
		button.text = {"2d": "01 · 2D", "isometric": "02 · 2.5D", "3d": "03 · 3D"}[key]
		button.custom_minimum_size = Vector2(104, 38)
		button.pressed.connect(switch_scene.bind(key))
		header.add_child(button)
	fps_button = Button.new()
	fps_button.text = "%d FPS" % Telemetry.target_fps
	fps_button.pressed.connect(_toggle_fps)
	header.add_child(fps_button)
	var export_button := Button.new()
	export_button.text = "Export JSON"
	export_button.pressed.connect(_export)
	header.add_child(export_button)
	status = Label.new()
	status.add_theme_color_override("font_color", Color("7bd6c5"))
	rows.add_child(status)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 14)
	rows.add_child(info)
	var footer := Label.new()
	footer.text = "WASD / arrows · Move     E · Activate beacon     Space · Jump in 3D     Hold RMB · Camera     F6 · 60/120     F7 · Quality     F8 · Export"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 24
	footer.offset_top = -38
	footer.add_theme_font_size_override("font_size", 14)
	layer.add_child(footer)

func _toggle_fps() -> void:
	Telemetry.set_target(120 if Telemetry.target_fps == 60 else 60)
	fps_button.text = "%d FPS" % Telemetry.target_fps

func _export() -> void:
	var result := Telemetry.export_json()
	status.text = "Saved: " + ProjectSettings.globalize_path("user://performance.json") if result == OK else "Export failed: " + error_string(result)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6: _toggle_fps()
		elif event.keycode == KEY_F7:
			var profiles := ["low", "medium", "high"]
			Telemetry.apply_quality(profiles[(profiles.find(Telemetry.quality) + 1) % 3])
		elif event.keycode == KEY_F8: _export()

func _process(delta: float) -> void:
	ui_accumulator += delta
	if ui_accumulator >= 0.25:
		ui_accumulator = 0
		var stats := Telemetry.summary()
		if not stats.is_empty():
			var regions_count: int = active.regions.size() if active.get("regions") != null else 0
			info.text = "%.0f FPS  ·  frame p95 %.2f ms  ·  budget %.2f ms  ·  %s  ·  %d regions  ·  %.1f MiB  ·  0.2.0-dev" % [Engine.get_frames_per_second(), stats["p95_ms"], stats["budget_ms"], Telemetry.quality.to_upper(), regions_count, float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0]
	if benchmark and not ending and float(Time.get_ticks_msec() - wall_started) / 1000.0 >= duration:
		ending = true
		_finish_benchmark()

func _finish_benchmark() -> void:
	if capture != "" and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture)
	var result := Telemetry.export_json(output if output != "" else "user://benchmark.json")
	print("BIGARCADE_BENCHMARK ", JSON.stringify(Telemetry.summary()))
	get_tree().quit(0 if result == OK else 3)
