#include "bigarcade_runtime.h"
#include "core/object/class_db.h"

void BigArcadeRuntime::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_version"), &BigArcadeRuntime::get_version);
    ClassDB::bind_method(D_METHOD("reset_history", "capacity"), &BigArcadeRuntime::reset_history, DEFVAL(600));
    ClassDB::bind_method(D_METHOD("record_frame", "wall_ms", "process_ms", "physics_ms", "gpu_ms", "memory_bytes"), &BigArcadeRuntime::record_frame, DEFVAL(-1.0), DEFVAL(0));
    ClassDB::bind_method(D_METHOD("get_frame_summary", "target_fps"), &BigArcadeRuntime::get_frame_summary, DEFVAL(60));
    ClassDB::bind_method(D_METHOD("generate_region", "seed", "coordinate", "side"), &BigArcadeRuntime::generate_region, DEFVAL(16));
}
String BigArcadeRuntime::get_version() const { return "0.2.0-dev"; }
void BigArcadeRuntime::reset_history(int capacity) { history.reset(std::clamp(capacity, 1, 36000)); }
bool BigArcadeRuntime::record_frame(double wall_ms, double process_ms, double physics_ms, double gpu_ms, int64_t memory_bytes) {
    return history.push({wall_ms, process_ms, physics_ms, gpu_ms, memory_bytes});
}
Dictionary BigArcadeRuntime::get_frame_summary(int target_fps) const {
    const auto s = history.summarize(target_fps); Dictionary d;
    d["samples"] = static_cast<int64_t>(s.samples); d["mean_ms"] = s.mean_ms;
    d["p50_ms"] = s.p50_ms; d["p95_ms"] = s.p95_ms; d["p99_ms"] = s.p99_ms; d["max_ms"] = s.max_ms;
    d["process_cpu_mean_ms"] = s.process_ms; d["physics_cpu_mean_ms"] = s.physics_ms;
    d["gpu_samples"] = static_cast<int64_t>(s.gpu_samples); d["gpu_mean_ms"] = s.gpu_samples ? Variant(s.gpu_ms) : Variant();
    d["budget_ms"] = s.budget_ms; d["over_budget"] = static_cast<int64_t>(s.over_budget);
    d["peak_static_memory_bytes"] = s.peak_memory_bytes;
    return d;
}
Dictionary BigArcadeRuntime::generate_region(int64_t seed, Vector2i coordinate, int side) const {
    side = std::clamp(side, 4, 64);
    const auto cells = bigarcade::generate_cells(static_cast<uint32_t>(seed), coordinate.x, coordinate.y, side);
    PackedInt32Array packed; packed.resize(static_cast<int>(cells.size()));
    for (size_t i = 0; i < cells.size(); ++i) packed.set(static_cast<int>(i), cells[i]);
    Dictionary d; d["coordinate"] = coordinate; d["side"] = side; d["cells"] = packed;
    d["id"] = "ba:" + String::num_int64(seed) + ":" + String::num_int64(coordinate.x) + ":" + String::num_int64(coordinate.y);
    d["generator_version"] = 1;
    return d;
}
