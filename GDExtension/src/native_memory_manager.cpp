#include "native_memory_manager.h"
#include "native_memory_rendering_device.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

std::unordered_map<uint32_t, PackedByteArray> NativeMemoryManager::packed_byte_arrays;
uint32_t NativeMemoryManager::last_id_dealt = UINT32_MAX;

std::optional<PackedByteArray> NativeMemoryManager::get_packed_byte_array(uint32_t id) {
	if (NativeMemoryManager::packed_byte_arrays.find(id) != NativeMemoryManager::packed_byte_arrays.end())
		return NativeMemoryManager::packed_byte_arrays[id];
	return std::nullopt;
}

void NativeMemoryManager::_bind_methods() {
	ClassDB::bind_method(D_METHOD("proj_to_bytes"), &NativeMemoryManager::proj_to_bytes);
	ClassDB::bind_method(D_METHOD("create_packed_byte_array"), &NativeMemoryManager::create_packed_byte_array);
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

int NativeMemoryManager::create_packed_byte_array(int size) {
	uint32_t id = last_id_dealt++;
	packed_byte_arrays[id] = PackedByteArray();
	packed_byte_arrays[id].resize(size);
	return id;
}