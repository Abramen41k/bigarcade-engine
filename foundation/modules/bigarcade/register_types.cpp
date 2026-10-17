#include "register_types.h"
#include "bigarcade_runtime.h"
#include "core/object/class_db.h"
void initialize_bigarcade_module(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(BigArcadeRuntime);
}
void uninitialize_bigarcade_module(ModuleInitializationLevel) {}
