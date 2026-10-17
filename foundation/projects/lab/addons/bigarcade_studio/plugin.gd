@tool
extends EditorPlugin
var dock: VBoxContainer
var message: Label

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "BigArcade Studio"
	dock.custom_minimum_size.x = 260
	dock.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "BIGARCADE STUDIO"
	title.add_theme_font_size_override("font_size", 20)
	dock.add_child(title)
	var description := Label.new()
	description.text = "Godot Foundation · 0.2.0-dev\nTemplates / Rendering / Performance"
	dock.add_child(description)
	for key: String in ["2d", "isometric", "3d"]:
		var button := Button.new()
		button.text = "Create scene · " + key.to_upper()
		button.pressed.connect(_create_template.bind(key))
		dock.add_child(button)
	var fps := OptionButton.new()
	fps.add_item("60 FPS · 16.67 ms full frame", 60)
	fps.add_item("120 FPS · 8.33 ms full frame", 120)
	fps.select(1 if int(ProjectSettings.get_setting("bigarcade/performance/target_fps", 60)) == 120 else 0)
	fps.item_selected.connect(func(index: int):
		ProjectSettings.set_setting("bigarcade/performance/target_fps", fps.get_item_id(index))
		ProjectSettings.save()
		message.text = "Saved. The next game run uses this cap.")
	dock.add_child(fps)
	# Keep backend changes explicit: renderer switches require a restart.
	var renderer_info := Label.new()
	renderer_info.text = "Renderer: " + RenderingServer.get_current_rendering_method() + "\nUse Project Settings to switch renderer."
	dock.add_child(renderer_info)
	var native := Label.new()
	native.text = "Native module: " + ("loaded" if ClassDB.class_exists("BigArcadeRuntime") else "MISSING — rebuild fork")
	dock.add_child(native)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = "Scene tree, inspector and asset import use the inherited Godot editor."
	dock.add_child(message)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	print("BIGARCADE_STUDIO_READY: native=", ClassDB.class_exists("BigArcadeRuntime"), ", templates=3")

func _create_template(kind: String) -> void:
	var folder := "res://created_scenes"
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder + "/" + kind + "_" + str(Time.get_ticks_usec()) + ".tscn"
	var source := "res://scenes/demo_" + kind + ".tscn"
	var result := DirAccess.copy_absolute(source, path)
	if result != OK:
		message.text = "Could not create scene: " + error_string(result)
		return
	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.open_scene_from_path(path)
	message.text = "Created " + path + ". Run this scene with F6."

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()
