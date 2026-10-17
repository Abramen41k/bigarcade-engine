#pragma once
#include "../core.hpp"
#include "tests/test_macros.h"
#include <limits>
namespace TestBigArcade {
TEST_CASE("[BigArcade] bounded frame history keeps newest samples") {
    bigarcade::FrameHistory h(3);
    for (int i = 1; i <= 5; ++i) CHECK(h.push({double(i), 1, .2, -1, i * 100}));
    auto s = h.summarize(120);
    CHECK(s.samples == 3); CHECK(s.mean_ms == 4); CHECK(s.p95_ms == 5); CHECK(s.gpu_samples == 0);
}
TEST_CASE("[BigArcade] invalid samples and unknown GPU are not successful timings") {
    bigarcade::FrameHistory h;
    CHECK_FALSE(h.push({std::numeric_limits<double>::quiet_NaN(), 0, 0, -1, 0}));
    CHECK_FALSE(h.push({-1, 0, 0, -1, 0}));
    CHECK(h.push({17, 2, 1, -1, 1000}));
    auto s = h.summarize(60); CHECK(s.over_budget == 1); CHECK(s.gpu_ms == -1);
}
TEST_CASE("[BigArcade] regions are deterministic with negative coordinates") {
    const auto a = bigarcade::generate_cells(42, -2, 3, 16);
    CHECK(a == bigarcade::generate_cells(42, -2, 3, 16));
    CHECK(a != bigarcade::generate_cells(43, -2, 3, 16));
    CHECK(bigarcade::floor_region(-.01, 16) == -1);
    CHECK(bigarcade::floor_region(-16, 16) == -1);
    for (int i = 0; i < 16; ++i) { CHECK(a[7 * 16 + i] == 0); CHECK(a[i * 16 + 8] == 0); }
}
}
