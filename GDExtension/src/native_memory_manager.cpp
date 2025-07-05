#include "native_memory_manager.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

using namespace godot;

void NativeMemoryManager::_bind_methods() {
	ClassDB::bind_method(D_METHOD("proj_to_bytes"), &NativeMemoryManager::proj_to_bytes);
	// ClassDB::bind_method(D_METHOD("get_amplitude"), &GDExample::get_amplitude);
	// ClassDB::bind_method(D_METHOD("set_amplitude", "p_amplitude"), &GDExample::set_amplitude);

	// ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "amplitude"), "set_amplitude", "get_amplitude");
}

NativeMemoryManager::NativeMemoryManager() {
	// Initialize any variables here.
}

NativeMemoryManager::~NativeMemoryManager() {
	// Add your cleanup here.
}

constexpr int SIZEOF_MAT4 = 16 * sizeof(float);

PackedByteArray NativeMemoryManager::proj_to_bytes(const Projection proj) {
	PackedByteArray byteArray;
	byteArray.resize(SIZEOF_MAT4);

	uint8_t* p_byteArray = byteArray.ptrw();
	memcpy(p_byteArray, proj.columns, SIZEOF_MAT4);

	return byteArray;
}