#ifndef TL_NATIVEMEMORY_RENDERINGDEVICE_H
#define TL_NATIVEMEMORY_RENDERINGDEVICE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/rendering_device.hpp>

namespace godot {

class NativeMemoryRenderingDevice : public RefCounted {
	GDCLASS(NativeMemoryRenderingDevice, RefCounted)

private:
    RenderingDevice* rd;

protected:
	static void _bind_methods();

public:
	NativeMemoryRenderingDevice();
	~NativeMemoryRenderingDevice();

    Error buffer_update(RID buffer, int offset, int size_bytes, int data_id);
    void compute_list_set_push_constant(int compute_list,  int buffer_id, int size_bytes);
    void draw_list_set_push_constant(int draw_list,  int buffer_id, int size_bytes);
    RID index_buffer_create(int size_indices, RenderingDevice::IndexBufferFormat format, int data_id, bool use_restart_indices = false, BitField<RenderingDevice::BufferCreationBits> creation_bits = ((BitField<RenderingDevice::BufferCreationBits>)(0)));
    RID storage_buffer_create(int size_indices, int data_id, BitField<RenderingDevice::StorageBufferUsage> usage = ((BitField<RenderingDevice::StorageBufferUsage>)(0)), BitField<RenderingDevice::BufferCreationBits> creation_bits = ((BitField<RenderingDevice::BufferCreationBits>)(0)));
    RID texture_buffer_create(int size_bytes, RenderingDevice::DataFormat format, int data_id);
    RID uniform_buffer_create(int size_bytes, int data_id, BitField<RenderingDevice::BufferCreationBits> creation_bits = ((BitField<RenderingDevice::BufferCreationBits>)(0)));
    RID vertex_buffer_create(int size_bytes, int data_id, BitField<RenderingDevice::BufferCreationBits> creation_bits = ((BitField<RenderingDevice::BufferCreationBits>)(0)));
};

}

#endif