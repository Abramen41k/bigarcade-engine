// BigArcade Foundation. See foundation/LICENSE.txt.
#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace bigarcade {
struct Frame {
    double wall_ms = 0.0, process_ms = 0.0, physics_ms = 0.0, gpu_ms = -1.0;
    int64_t memory_bytes = 0;
};
struct Summary {
    size_t samples = 0, over_budget = 0, gpu_samples = 0;
    double mean_ms = 0, p50_ms = 0, p95_ms = 0, p99_ms = 0, max_ms = 0;
    double process_ms = 0, physics_ms = 0, gpu_ms = -1, budget_ms = 0;
    int64_t peak_memory_bytes = 0;
};
// A bounded history: no allocation on the hot sampling path.
class FrameHistory {
    std::vector<Frame> data;
    size_t cursor = 0, count = 0;
public:
    explicit FrameHistory(size_t capacity = 600) { reset(capacity); }
    void reset(size_t capacity = 600) {
        data.assign(std::clamp<size_t>(capacity, 1, 36000), {});
        cursor = count = 0;
    }
    bool push(const Frame &f) {
        if (!std::isfinite(f.wall_ms) || f.wall_ms <= 0 ||
            !std::isfinite(f.process_ms) || f.process_ms < 0 ||
            !std::isfinite(f.physics_ms) || f.physics_ms < 0 ||
            !std::isfinite(f.gpu_ms) || f.gpu_ms < -1 || f.memory_bytes < 0) return false;
        data[cursor] = f;
        cursor = (cursor + 1) % data.size();
        count = std::min(count + 1, data.size());
        return true;
    }
    Summary summarize(int fps = 60) const {
        Summary s; s.samples = count; s.budget_ms = 1000.0 / std::clamp(fps, 1, 1000);
        if (count == 0) return s;
        std::vector<double> times; times.reserve(count);
        double gpu_sum = 0;
        for (size_t i = 0; i < count; ++i) {
            const auto &f = data[i]; times.push_back(f.wall_ms);
            s.mean_ms += f.wall_ms; s.process_ms += f.process_ms; s.physics_ms += f.physics_ms;
            s.over_budget += f.wall_ms > s.budget_ms;
            s.peak_memory_bytes = std::max(s.peak_memory_bytes, f.memory_bytes);
            if (f.gpu_ms >= 0) { gpu_sum += f.gpu_ms; ++s.gpu_samples; }
        }
        std::sort(times.begin(), times.end());
        const auto percentile = [&](double p) { return times[static_cast<size_t>(std::ceil(p * count)) - 1]; };
        s.mean_ms /= count; s.process_ms /= count; s.physics_ms /= count;
        s.p50_ms = percentile(.50); s.p95_ms = percentile(.95); s.p99_ms = percentile(.99); s.max_ms = times.back();
        if (s.gpu_samples) s.gpu_ms = gpu_sum / s.gpu_samples;
        return s;
    }
};
inline uint32_t mix32(uint32_t value) {
    value ^= value >> 16; value *= 0x7feb352du;
    value ^= value >> 15; value *= 0x846ca68bu;
    return value ^ (value >> 16);
}
// All arithmetic is unsigned: deterministic wraparound, including negative coordinates.
inline uint32_t cell_hash(uint32_t seed, int32_t x, int32_t z) {
    return mix32(seed ^ mix32(static_cast<uint32_t>(x) + 0x9e3779b9u) ^ mix32(static_cast<uint32_t>(z) + 0x85ebca6bu));
}
inline int32_t floor_region(double coordinate, double width) {
    return static_cast<int32_t>(std::floor(coordinate / width));
}
inline std::vector<int32_t> generate_cells(uint32_t seed, int32_t cx, int32_t cz, int side) {
    side = std::clamp(side, 4, 64);
    std::vector<int32_t> cells(static_cast<size_t>(side * side));
    for (int z = 0; z < side; ++z) for (int x = 0; x < side; ++x) {
        // Two-cell corridors remain open across adjacent region borders.
        const bool corridor = x == side / 2 || x == side / 2 - 1 || z == side / 2 || z == side / 2 - 1;
        const auto wx = static_cast<int32_t>(static_cast<uint32_t>(cx) * side + x);
        const auto wz = static_cast<int32_t>(static_cast<uint32_t>(cz) * side + z);
        cells[static_cast<size_t>(z * side + x)] = !corridor && cell_hash(seed, wx, wz) % 100 < 16 ? 1 : 0;
    }
    return cells;
}
} // namespace bigarcade
