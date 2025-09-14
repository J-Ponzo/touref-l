class_name _TL_FeatureFlagManager

class QueryCache:
	var buckets : Dictionary[int, DataBucket]

class FeatureFlagQuery:
	var mask : int
	var set_name : StringName
	var relevant_flags_mask : int
	var set_flags_mask : int

class Name_Mask_Pair:
	var set_name : StringName
	var flags_mask : int
	
class Data_NameMask_Pair:
	var data : _TL_ProxyData
	var name_mask : Name_Mask_Pair

class Masks_Dictionnary:
	var masks : Dictionary[StringName, int]

var feature_flag_manager_def : TL_FeatureFlagManager_Def
var proxy_data_lookup : Dictionary[_TL_ProxyObject, DataBucket]
var data_mask_lookup : Dictionary[_TL_ProxyData, Masks_Dictionnary]
var query_caches : Dictionary[StringName, QueryCache]
var main_buckets : Dictionary[StringName, DataBucket]

# TODO user TL_ProxyData instead of Object
func get_flags_mask(set_name : StringName, data : _TL_ProxyData) -> int:
	if data_mask_lookup.has(data):
		return data_mask_lookup[data].masks[set_name]
	return 0

func get_flags(set_name : StringName, data : _TL_ProxyData) -> Array[StringName]:
	if data_mask_lookup.has(data):
		return _get_flags_from_name_and_mask(set_name, data_mask_lookup[data].masks[set_name])
	return []

func _get_flags_from_name_and_mask(set_name : StringName, flags_mask : int) -> Array[StringName]:
	var flags : Array[StringName]

	var flags_set : Array[StringName] = feature_flag_manager_def.feature_sets[set_name].flags
	for i in range(0, flags_set.size()):
		if (flags_mask & 1 << i) > 0:
			flags.append(flags_set[i])

	return flags

func _build_flags_mask(set_name : StringName, flags : Array[StringName]) -> int:
	var set : Array[StringName] = feature_flag_manager_def.feature_sets[set_name].flags
	var mask : int = 0
	for flag in flags:
		var idx : int  = set.find(flag)
		mask |= 1 << idx
	return mask

func build_query_from_def(query_def : TL_FeatureFlagQueryDef) -> FeatureFlagQuery:
	return build_query(query_def.set_name, query_def.relevant_flags, query_def.set_flags)

func build_query(set_name : StringName, relevant_flags : Array[StringName], set_flags : Array[StringName]) -> FeatureFlagQuery:
	var query : FeatureFlagQuery = FeatureFlagQuery.new()
	query.set_name = set_name
	query.relevant_flags_mask = _build_flags_mask(set_name, relevant_flags)
	query.set_flags_mask = _build_flags_mask(set_name, set_flags)

	var query_mask : int = query.relevant_flags_mask
	query_mask |= query.set_flags_mask << 32
	query.mask = query_mask

	return query

func _build_query_from_query_mask(set_name : StringName, query_mask : int) -> FeatureFlagQuery:
	var query : FeatureFlagQuery = FeatureFlagQuery.new()
	query.mask = query_mask
	query.set_name = set_name
	query.relevant_flags_mask = query_mask & 0xFFFFFFFF
	query.set_flags_mask = (query_mask >> 32) & 0xFFFFFFFF

	return query

func query_data(query : FeatureFlagQuery) -> Array[_TL_ProxyData]:
	if !query_caches[query.set_name].buckets.has(query.mask):
		_create_bucket(query)
	return query_caches[query.set_name].buckets[query.mask].data

func match_query(flags_mask : int, query_mask : FeatureFlagQuery) -> bool:
	var data_relevant_flags : int = flags_mask & query_mask.relevant_flags_mask
	return data_relevant_flags == query_mask.set_flags_mask

func _create_bucket(query : FeatureFlagQuery) -> void:
	var bucket : DataBucket = DataBucket.new()
	for data in main_buckets[query.set_name].data:
		var flags_mask : int = data_mask_lookup[data].masks[query.set_name]
		if match_query(flags_mask, query):
			bucket.data.append(data)
	query_caches[query.set_name].buckets[query.mask] = bucket

func _register(proxy_object : _TL_ProxyObject) -> void:
	if proxy_data_lookup.has(proxy_object):
		return

	# TODO make this block more readable
	var flagged_items : Array[Data_NameMask_Pair] = _extract_flagged_data(proxy_object)
	var items_bucket : DataBucket = DataBucket.new()
	for flagged_item : Data_NameMask_Pair in flagged_items:
		items_bucket.data.append(flagged_item.data)
		if !data_mask_lookup.has(flagged_item.data):
			data_mask_lookup[flagged_item.data] = Masks_Dictionnary.new()
		data_mask_lookup[flagged_item.data].masks[flagged_item.name_mask.set_name] = flagged_item.name_mask.flags_mask
		if !main_buckets.has(flagged_item.name_mask.set_name):
			main_buckets[flagged_item.name_mask.set_name] = DataBucket.new()
		main_buckets[flagged_item.name_mask.set_name].data.append(flagged_item.data)
		if !query_caches.has(flagged_item.name_mask.set_name):
			query_caches[flagged_item.name_mask.set_name] = QueryCache.new()
		for query_mask : int in query_caches[flagged_item.name_mask.set_name].buckets.keys():
			var query : FeatureFlagQuery = _build_query_from_query_mask(flagged_item.name_mask.set_name, query_mask)
			if match_query(flagged_item.name_mask.flags_mask, query):
				query_caches[flagged_item.name_mask.set_name].buckets[query_mask].data.append(flagged_item.data)

	proxy_data_lookup[proxy_object] = items_bucket

func _unregister(proxy_object : _TL_ProxyObject) -> void:
	if !proxy_data_lookup.has(proxy_object):
		return
	
	# TODO make this block more readable
	for data in proxy_data_lookup[proxy_object].data:
		if !data_mask_lookup.has(data):
			continue
		var masks : Dictionary[StringName, int] = data_mask_lookup[data].masks
		data_mask_lookup.erase(data)
		for set_name : StringName in masks.keys():
			var idx = main_buckets[set_name].data.find(data)
			main_buckets[set_name].data.remove_at(idx)
			for query_mask : int in query_caches[set_name].buckets.keys():
				var query : FeatureFlagQuery = _build_query_from_query_mask(set_name, query_mask)
				if match_query(masks[set_name], query):
					idx = query_caches[set_name].buckets[query_mask].data.find(data)
					query_caches[set_name].buckets[query_mask].data.remove_at(idx)
		masks.clear()

	proxy_data_lookup.erase(proxy_object)

func _extract_flagged_data(proxy_object : _TL_ProxyObject) -> Array[Data_NameMask_Pair]:
	return []
