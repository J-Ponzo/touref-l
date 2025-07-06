#include "native_memory_rendering_device.h"
#include "native_memory_manager.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/classes/rendering_server.hpp>

using namespace godot;

void NativeMemoryRenderingDevice::_bind_methods() {
	ClassDB::bind_method(D_METHOD("buffer_update"), &NativeMemoryRenderingDevice::buffer_update);
	ClassDB::bind_method(D_METHOD("compute_list_set_push_constant"), &NativeMemoryRenderingDevice::compute_list_set_push_constant);
	ClassDB::bind_method(D_METHOD("draw_list_set_push_constant"), &NativeMemoryRenderingDevice::draw_list_set_push_constant);
	ClassDB::bind_method(D_METHOD("index_buffer_create"), &NativeMemoryRenderingDevice::index_buffer_create);
	ClassDB::bind_method(D_METHOD("storage_buffer_create"), &NativeMemoryRenderingDevice::storage_buffer_create);
	ClassDB::bind_method(D_METHOD("texture_buffer_create"), &NativeMemoryRenderingDevice::texture_buffer_create);
	ClassDB::bind_method(D_METHOD("uniform_buffer_create"), &NativeMemoryRenderingDevice::uniform_buffer_create);
	ClassDB::bind_method(D_METHOD("vertex_buffer_create"), &NativeMemoryRenderingDevice::vertex_buffer_create);
}

NativeMemoryRenderingDevice::NativeMemoryRenderingDevice() {
	rd = RenderingServer::get_singleton()->get_rendering_device();
}

NativeMemoryRenderingDevice::~NativeMemoryRenderingDevice() {
	// Add your cleanup here.
}

Error NativeMemoryRenderingDevice::buffer_update(RID buffer, int offset, int size_bytes, int data_id) {
    PackedByteArray* data = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(data_id));
    if (data == nullptr) {
        UtilityFunctions::push_error("NativeMemoryManager::buffer_update(RID buffer = ", buffer, ", int offset = ", offset, ", int size_bytes = ", size_bytes, ", int data_id = ", data_id);
        return Error::ERR_INVALID_DATA;
    }
    return rd->buffer_update(buffer, static_cast<uint32_t>(offset), static_cast<uint32_t>(size_bytes), *data);
}

void NativeMemoryRenderingDevice::compute_list_set_push_constant(int compute_list, int buffer_id, int size_bytes) {
    PackedByteArray* buffer = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(buffer_id));
    if (buffer == nullptr) {
        return;
    }
    rd->compute_list_set_push_constant(static_cast<uint64_t>(compute_list), *buffer, size_bytes);
}

void NativeMemoryRenderingDevice::draw_list_set_push_constant(int draw_list,  int buffer_id, int size_bytes) {
    PackedByteArray* buffer = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(buffer_id));
    if (buffer == nullptr) {
        return;
    }
    rd->draw_list_set_push_constant(static_cast<uint64_t>(draw_list), *buffer, size_bytes);
}

RID NativeMemoryRenderingDevice::index_buffer_create(int size_indices, RenderingDevice::IndexBufferFormat format, int data_id, bool use_restart_indices, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
     PackedByteArray* data = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(data_id));
    if (data == nullptr) {
        return RID();
    }
    return rd->index_buffer_create(static_cast<uint32_t>(size_indices), format, *data, use_restart_indices, creation_bits);
}

RID NativeMemoryRenderingDevice::storage_buffer_create(int size_indices, int data_id, BitField<RenderingDevice::StorageBufferUsage> usage, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
     PackedByteArray* data = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(data_id));
    if (data == nullptr) {
        return RID();
    }
    return rd->storage_buffer_create(static_cast<uint32_t>(size_indices), *data, usage, creation_bits);
}

RID NativeMemoryRenderingDevice::texture_buffer_create(int size_bytes, RenderingDevice::DataFormat format, int data_id) {
     PackedByteArray* data = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(data_id));
    if (data == nullptr) {
        return RID();
    }
    return rd->texture_buffer_create(static_cast<uint32_t>(size_bytes), format, *data);
}

RID NativeMemoryRenderingDevice::uniform_buffer_create(int size_bytes, int data_id, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
     PackedByteArray* data = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(data_id));
    if (data == nullptr) {
        UtilityFunctions::push_error("NativeMemoryManager::uniform_buffer_create(int size_bytes = ", size_bytes, ", int data_id = ", data_id, ", BitField<RenderingDevice::BufferCreationBits> creation_bits = ???");
        return RID();
    }
    return rd->uniform_buffer_create(static_cast<uint32_t>(size_bytes), *data, creation_bits);
}

RID NativeMemoryRenderingDevice::vertex_buffer_create(int size_bytes, int data_id, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
     PackedByteArray* data = NativeMemoryManager::get_packed_byte_array(static_cast<uint32_t>(data_id));
    if (data == nullptr) {
        return RID();
    }
    return rd->vertex_buffer_create(static_cast<uint32_t>(size_bytes), *data, creation_bits);
}