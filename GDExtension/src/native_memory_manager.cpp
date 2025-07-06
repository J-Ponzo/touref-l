#include "native_memory_manager.h"
#include "native_memory_rendering_device.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

std::unordered_map<uint32_t, PackedByteArray> NativeMemoryManager::packed_byte_arrays;
uint32_t NativeMemoryManager::last_id_dealt = 0;

PackedByteArray* NativeMemoryManager::get_packed_byte_array(uint32_t id) {
	if (NativeMemoryManager::packed_byte_arrays.find(id) != NativeMemoryManager::packed_byte_arrays.end())
		return &NativeMemoryManager::packed_byte_arrays[id];
	return nullptr;
}

void NativeMemoryManager::_bind_methods() {
	ClassDB::bind_method(D_METHOD("proj_to_bytes"), &NativeMemoryManager::proj_to_bytes);
	ClassDB::bind_method(D_METHOD("create_packed_byte_array"), &NativeMemoryManager::create_packed_byte_array);
	ClassDB::bind_method(D_METHOD("fill_packed_byte_array_with_projections"), &NativeMemoryManager::fill_packed_byte_array_with_projections);
}

NativeMemoryManager::NativeMemoryManager() {
	// Initialize any variables here.
}

NativeMemoryManager::~NativeMemoryManager() {
	// Add your cleanup here.
}

constexpr size_t SIZEOF_MAT4 = 16 * sizeof(float);

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
	packed_byte_arrays[id].resize(static_cast<uint64_t>(size));
	return id;
}

void NativeMemoryManager::fill_packed_byte_array_with_projections(int array_id, int offset, TypedArray<Projection> projections) {
	PackedByteArray* byteArray = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(array_id));
    if (byteArray == nullptr) {
		UtilityFunctions::push_error("NativeMemoryManager::fill_packed_byte_array_with_projections(int array_id = ", array_id , ", int offset = ", offset, ", TypedArray<Projection> projections = ", projections,") FAILED : There is no packed_byte_array with this id");
        return;
	}

	uint8_t* p_byteArray = byteArray->ptrw();
	p_byteArray += static_cast<size_t>(offset);

	for (Projection proj : projections) {
		memcpy(p_byteArray, proj.columns, SIZEOF_MAT4);
		p_byteArray += SIZEOF_MAT4;
	}
}