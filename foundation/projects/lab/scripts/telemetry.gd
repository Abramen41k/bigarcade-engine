extends Node
## Full-frame intervals, CPU monitors and optional GPU timings are separate channels.
signal profile_changed
var native: RefCounted
var target_fps: int = 60
var quality: String = "medium"
var automatic: bool = false
var samples: Array[Dictionary] = []
var last_tick: int = 0
var elapsed: float = 0.0
var quality_window: float = 0.0
var warmup_frames: int = 45
var scene_name: String = "2d"
var input_steps: int = 0

func _ready() -> void:
	if not ClassDB.class_exists("BigArcadeRuntime"):
		push_error("This project requires the BigArcade Foundation C++ module.")
		get_tree().quit(2)
		return
	native = ClassDB.instantiate("BigArcadeRuntime")
	native.call("reset_history", 6000)
	Engine.physics_ticks_per_second = 60
	set_target(int(ProjectSettings.get_setting("bigarcade/performance/target_fps", 60)))
	apply_quality(str(ProjectSettings.get_setting("bigarcade/performance/quality", "medium")))
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_ensure_inputs()

func _ensure_inputs() -> void:
	var actions := {"ba_left": [KEY_A, KEY_LEFT], "ba_right": [KEY_D, KEY_RIGHT], "ba_up": [KEY_W, KEY_UP], "ba_down": [KEY_S, KEY_DOWN], "ba_jump": [KEY_SPACE], "ba_interact": [KEY_E]}
	for action: String in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code: int in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func reset(scene: String) -> void:
	scene_name = scene
	samples.clear()
	last_tick = 0
	elapsed = 0
	input_steps = 0
	warmup_frames = 45
	quality_window = 0
	if native:
		native.call("reset_history", 6000)

func set_target(value: int) -> void:
	target_fps = 120 if value == 120 else 60
	Engine.max_fps = target_fps
	profile_changed.emit()

func apply_quality(value: String) -> void:
	quality = value if value in ["low", "medium", "high"] else "medium"
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality != "high" else Viewport.MSAA_2X
	get_viewport().scaling_3d_scale = 0.75 if quality == "low" else 1.0
	profile_changed.emit()

func _process(delta: float) -> void:
	if not native:
		return
	var now := Time.get_ticks_usec()
	var wall_ms := float(now - last_tick) / 1000.0 if last_tick != 0 else 0.0
	last_tick = now
	elapsed += delta
	if warmup_frames > 0:
		warmup_frames -= 1
		return
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	# A zero returned by an unsupported/dummy renderer is not evidence of free rendering.
	if gpu <= 0.0 or DisplayServer.get_name() == "headless":
		gpu = -1.0
	var process_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	if native.call("record_frame", wall_ms, process_ms, physics_ms, gpu, memory):
		samples.append({"wall_ms": wall_ms, "process_cpu_ms": process_ms, "physics_cpu_ms": physics_ms, "gpu_ms": gpu if gpu >= 0.0 else null, "static_memory_bytes": memory})
		if samples.size() > 6000:
			samples.pop_front()
	quality_window += delta
	if automatic and quality_window >= 5.0 and samples.size() >= 120:
		quality_window = 0.0
		var stats := summary()
		# Conservative degradation only; no oscillation or claim of GPU utilization.
		if float(stats["p95_ms"]) > float(stats["budget_ms"]) * 1.35:
			if quality == "high": apply_quality("medium")
			elif quality == "medium": apply_quality("low")

func summary() -> Dictionary:
	return native.call("get_frame_summary", target_fps) if native else {}

func report() -> Dictionary:
	return {"bigarcade": "0.2.0-dev", "godot": Engine.get_version_info(), "scene": scene_name, "date_utc": Time.get_datetime_string_from_system(true), "os": OS.get_name(), "cpu": OS.get_processor_name(), "logical_cpus": OS.get_processor_count(), "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "viewport": [get_viewport().size.x, get_viewport().size.y], "target_fps": target_fps, "quality": quality, "automatic": automatic, "physics_hz": Engine.physics_ticks_per_second, "physics_interpolation": ProjectSettings.get_setting("physics/common/physics_interpolation"), "input_steps": input_steps, "timing_scope": "Wall frame intervals include pacing; CPU monitors and viewport GPU timings are not additive. GPU null means unavailable.", "summary": summary(), "samples": samples}

func export_json(path: String = "user://performance.json") -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(report(), "\t"))
	return OK
