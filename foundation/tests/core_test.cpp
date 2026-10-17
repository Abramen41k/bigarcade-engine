#include "../modules/bigarcade/core.hpp"
#include <chrono>
#include <iostream>
#include <limits>
#include <stdexcept>

int checks = 0;
void check(bool value, const char *name) { ++checks; if (!value) throw std::runtime_error(name); }
int main() {
    bigarcade::FrameHistory h(3);
    check(h.summarize().samples == 0, "empty history");
    check(!h.push({0,0,0,-1,0}), "zero wall frame rejected");
    check(!h.push({std::numeric_limits<double>::quiet_NaN(),0,0,-1,0}), "NaN rejected");
    check(!h.push({1,-1,0,-1,0}), "negative CPU rejected");
    for (int i=1;i<=5;++i) h.push({double(i),1,.2,-1,i*100});
    auto s=h.summarize(120);
    check(s.samples==3 && s.mean_ms==4 && s.p95_ms==5,"ring keeps latest frames");
    check(s.gpu_samples==0 && s.gpu_ms==-1,"unknown GPU is missing");
    check(s.peak_memory_bytes==500,"memory peak");
    h.reset(); h.push({16,2,1,3,100}); h.push({17,3,1,5,200});
    s=h.summarize(60);
    check(s.over_budget==1,"60 FPS full-frame budget");
    check(h.summarize(120).over_budget==2,"120 FPS full-frame budget");
    check(s.gpu_samples==2 && s.gpu_ms==4,"GPU samples independently averaged");
    check(bigarcade::floor_region(-.01,16)==-1,"negative boundary regression");
    check(bigarcade::floor_region(-16,16)==-1 && bigarcade::floor_region(-16.01,16)==-2,"exact negative boundaries");
    auto a=bigarcade::generate_cells(42,-2,3,16);
    check(a==bigarcade::generate_cells(42,-2,3,16),"same seed identical");
    check(a!=bigarcade::generate_cells(43,-2,3,16),"seed changes region");
    for(int i=0;i<16;++i) check(a[7*16+i]==0 && a[i*16+8]==0,"connecting corridors");
    check(bigarcade::generate_cells(1,0,0,0).size()==16,"lower size clamp");
    check(bigarcade::generate_cells(1,0,0,10000).size()==4096,"upper size clamp");
    const auto start=std::chrono::steady_clock::now();
    uint64_t checksum=0;
    for(int i=0;i<10000;++i) { const auto cells=bigarcade::generate_cells(42,i-5000,i/3,16); for (const auto c:cells) checksum+=c; }
    const auto us=std::chrono::duration<double,std::micro>(std::chrono::steady_clock::now()-start).count();
    std::cout<<"{\"checks\":"<<checks<<",\"cpp\":"<<__cplusplus<<",\"region_iterations\":10000,\"region_mean_us\":"<<us/10000<<",\"checksum\":"<<checksum<<"}\n";
}
