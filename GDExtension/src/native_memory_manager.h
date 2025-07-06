#ifndef TL_NATIVEMEMORY_MANAGER_H
#define TL_NATIVEMEMORY_MANAGER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <optional>

namespace godot {

constexpr uint32_t INVALID_ID = UINT32_MAX;

class NativeMemoryManager : public RefCounted {
	GDCLASS(NativeMemoryManager, RefCounted)

private:
	static std::unordered_map<uint32_t, PackedByteArray> packed_byte_arrays;
	static uint32_t last_id_dealt;

protected:
	static void _bind_methods();

public:
	static PackedByteArray* get_packed_byte_array(uint32_t id);

	NativeMemoryManager();
	~NativeMemoryManager();

	PackedByteArray proj_to_bytes(const Projection proj);
	int create_packed_byte_array(int size = 0);
	void fill_packed_byte_array_with_projections(int array_id, int offset, TypedArray<Projection> projections);
};

}

#endif