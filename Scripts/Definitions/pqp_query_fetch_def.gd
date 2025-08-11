extends TL_ProxyQueueProcessorDef
class_name TL_PQPQueryFetchDef

@export var type : StringName
@export var query_def : TL_FeatureFlagQueryDef

var _query : _TL_FeatureFlagManager.FeatureFlagQuery

func _setup(proxy_model : _TL_ProxyModel) -> void:
	_query = proxy_model.renderer.feature_flag_manager.build_query_from_def(query_def)

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
	var processed_array = []
	processed_array.append_array(proxy_model.renderer.scene_proxy.get_data_from_query(_query))
	return processed_array
