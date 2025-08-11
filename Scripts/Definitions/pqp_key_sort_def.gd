extends TL_ProxyQueueProcessorDef
class_name TL_PQPKeySortDef

@export var keygen_script : GDScript
@export var reverse_order : bool = false

var keygen : _TL_KeyGen
var keys : Dictionary[_TL_ProxyData, int]

func _setup(proxy_model : _TL_ProxyModel) -> void:
	keygen = keygen_script.new()

func is_before(data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return keys[data_1] < keys[data_2]

func is_after(data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return keys[data_1] > keys[data_2]

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
	# TODO might not be that efficient. consider storing keys in a manager like flags
	keys.clear()
	for item : _TL_ProxyData in data:
		keys[item] = keygen._generate(item)
	var callable : Callable = is_before
	if reverse_order:
		callable = is_after
	data.sort_custom(callable)

	return data
