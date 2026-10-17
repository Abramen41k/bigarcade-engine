#pragma once
#include "core/object/ref_counted.h"
#include "core/variant/dictionary.h"
#include "core/math/vector2i.h"
#include "core.hpp"

class BigArcadeRuntime : public RefCounted {
    GDCLASS(BigArcadeRuntime, RefCounted);
    bigarcade::FrameHistory history;
protected:
    static void _bind_methods();
public:
    String get_version() const;
    void reset_history(int capacity = 600);
    bool record_frame(double wall_ms, double process_ms, double physics_ms, double gpu_ms = -1, int64_t memory_bytes = 0);
    Dictionary get_frame_summary(int target_fps = 60) const;
    Dictionary generate_region(int64_t seed, Vector2i coordinate, int side = 16) const;
};
