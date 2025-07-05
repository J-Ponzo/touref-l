#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class NativeMemoryManager : public RefCounted {
	GDCLASS(NativeMemoryManager, RefCounted)

private:

protected:
	static void _bind_methods();

public:
	NativeMemoryManager();
	~NativeMemoryManager();

	PackedByteArray proj_to_bytes(const Projection proj);
};

}

#endif