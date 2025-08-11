class_name _TL_KeyGen

# TODO put in utils
func hash_int_to_bits(src_int : int, trg_nb_bits : int) -> int:
	var h = hash(src_int)
	var mask = (1 << trg_nb_bits) - 1
	return h & mask

func _generate(data : _TL_ProxyData) -> int:
	# TODO rise err if not overriden
	return -1
