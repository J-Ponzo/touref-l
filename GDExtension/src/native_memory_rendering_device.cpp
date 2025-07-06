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
    std::optional<PackedByteArray> data = NativeMemoryManager::get_packed_byte_array(data_id);
    if (!data.has_value())
        return Error::ERR_INVALID_DATA;
    return rd->buffer_update(buffer, offset, size_bytes, data.value());
}

void NativeMemoryRenderingDevice::compute_list_set_push_constant(int compute_list, int buffer_id, int size_bytes) {
    std::optional<PackedByteArray> buffer = NativeMemoryManager::get_packed_byte_array(buffer_id);
    if (!buffer.has_value())
        return
    rd->compute_list_set_push_constant(compute_list, buffer.value(), size_bytes);
}

void NativeMemoryRenderingDevice::draw_list_set_push_constant(int draw_list,  int buffer_id, int size_bytes) {
    std::optional<PackedByteArray> buffer = NativeMemoryManager::get_packed_byte_array(buffer_id);
    if (!buffer.has_value())
        return
    rd->draw_list_set_push_constant(draw_list, buffer.value(), size_bytes);
}

RID NativeMemoryRenderingDevice::index_buffer_create(int size_indices, RenderingDevice::IndexBufferFormat format, int data_id, bool use_restart_indices, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
    std::optional<PackedByteArray> data = NativeMemoryManager::get_packed_byte_array(data_id);
    if (!data.has_value())
        return RID();
    return rd->index_buffer_create(size_indices, format, data.value(), use_restart_indices, creation_bits);
}

RID NativeMemoryRenderingDevice::storage_buffer_create(int size_indices, int data_id, BitField<RenderingDevice::StorageBufferUsage> usage, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
    std::optional<PackedByteArray> data = NativeMemoryManager::get_packed_byte_array(data_id);
    if (!data.has_value())
        return RID();
    return rd->storage_buffer_create(size_indices, data.value(), usage, creation_bits);
}

RID NativeMemoryRenderingDevice::texture_buffer_create(int size_bytes, RenderingDevice::DataFormat format, int data_id) {
    std::optional<PackedByteArray> data = NativeMemoryManager::get_packed_byte_array(data_id);
    if (!data.has_value())
        return RID();
    return rd->texture_buffer_create(size_bytes, format, data.value());
}

RID NativeMemoryRenderingDevice::uniform_buffer_create(int size_bytes, int data_id, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
    std::optional<PackedByteArray> data = NativeMemoryManager::get_packed_byte_array(data_id);
    if (!data.has_value())
        return RID();
    return rd->uniform_buffer_create(size_bytes, data.value(), creation_bits);
}

RID NativeMemoryRenderingDevice::vertex_buffer_create(int size_bytes, int data_id, BitField<RenderingDevice::BufferCreationBits> creation_bits) {
    std::optional<PackedByteArray> data = NativeMemoryManager::get_packed_byte_array(data_id);
    if (!data.has_value())
        return RID();
    return rd->vertex_buffer_create(size_bytes, data.value(), creation_bits);
}