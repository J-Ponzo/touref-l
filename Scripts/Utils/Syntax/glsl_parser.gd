class_name TL_GLSLParser

var _tokens : Array[TL_GLSLTokenizer.Token]
var _tok_idx : int = 0

var _tokens_accumulated : Array[TL_GLSLTokenizer.Token] = []

func parse(tokens : Array[TL_GLSLTokenizer.Token]) -> TL_GLSLParser_Model.TokenGrpNode:
	_tokens = tokens
	var clean_tokens : Array[TL_GLSLTokenizer.Token] = _clean_tokens(_tokens)
	var super_tokens : Array[TL_GLSLTokenizer.Token] = _identify_super_tokens(clean_tokens)

	# TODO remove this debug stub
	print("----- TOKENS -----")
	for tok : TL_GLSLTokenizer.Token in super_tokens:
		print(tok)
	# TODO

	_tokens = super_tokens
	var root : TL_GLSLParser_Model.TokenGrpBody = _rec_generate_token_grp(TL_GLSLParser_Model.EBodyType.Root)
	var leaf : TL_GLSLParser_Model.TokenGrpLeaf = _rec_link_leaves(root, null)

	# TODO remove this debug stub
	print("----- LEAVES -----")
	var linked_leaves : Array[TL_GLSLParser_Model.TokenGrpLeaf]
	var linked_leaf : TL_GLSLParser_Model.TokenGrpLeaf = leaf
	while linked_leaf != null:
		linked_leaves.insert(0, linked_leaf)
		linked_leaf = linked_leaf.prev_leaf
	for l in linked_leaves:
		print(l)
	# TODO

	_rec_identify_struct_and_func_in(root)
	_rec_identify_vars_in(root)
	_rec_identify_blocks_in(root)

	return root

func fill_super_token(super_token : TL_GLSLParser_Model.SuperToken, tokens_to_merge : Array[TL_GLSLTokenizer.Token]) -> TL_GLSLParser_Model.SuperToken:
	super_token.type = TL_GLSLTokenizer.ETokenType.Other
	super_token.pos = tokens_to_merge[0].pos
	super_token.line = tokens_to_merge[0].line
	super_token.col = tokens_to_merge[0].col
	var cummuled_data : String = ""
	for tok in tokens_to_merge:
		cummuled_data += tok.data
	super_token.data = cummuled_data
	return super_token

func create_type_super_token(tokens_to_merge : Array[TL_GLSLTokenizer.Token]) -> TL_GLSLParser_Model.TypeSuperToken:
	var result : TL_GLSLParser_Model.TypeSuperToken = TL_GLSLParser_Model.TypeSuperToken.new()
	fill_super_token(result, tokens_to_merge)
	return result

func create_ctrl_flow_head_super_token(tokens_to_merge : Array[TL_GLSLTokenizer.Token]) -> TL_GLSLParser_Model.CtrlFlowHeadSuperToken:
	var result : TL_GLSLParser_Model.CtrlFlowHeadSuperToken = TL_GLSLParser_Model.CtrlFlowHeadSuperToken.new()
	fill_super_token(result, tokens_to_merge)
	return result

func _identify_super_tokens(tokens : Array[TL_GLSLTokenizer.Token]) -> Array[TL_GLSLTokenizer.Token]:
	var result : Array[TL_GLSLTokenizer.Token]

	var i : int = 0
	while i < tokens.size():
		var prev_token = null if i == 0 else tokens[i - 1]
		var cur_token = tokens[i]
		var next_token = null if i == tokens.size() - 1 else tokens[i + 1]

		if next_token != null && next_token.type == TL_GLSLTokenizer.ETokenType.Operator && next_token.data == '[':
			var j : int = i + 1
			var tokens_to_merge : Array[TL_GLSLTokenizer.Token]
			tokens_to_merge.append(cur_token)
			while tokens[j].type == TL_GLSLTokenizer.ETokenType.Operator && tokens[j].data == '[' && tokens[j + 1].type == TL_GLSLTokenizer.ETokenType.Integer && tokens[j + 2].type == TL_GLSLTokenizer.ETokenType.Operator && tokens[j + 2].data == ']':
				tokens_to_merge.append(tokens[j])
				tokens_to_merge.append(tokens[j + 1])
				tokens_to_merge.append(tokens[j + 2])
				j += 3
			var super_tok = create_type_super_token(tokens_to_merge)
			result.append(super_tok)
			i += tokens_to_merge.size()
		elif prev_token != null && prev_token.type == TL_GLSLTokenizer.ETokenType.Keyword && TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(prev_token.type):
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
		elif cur_token.type == TL_GLSLTokenizer.ETokenType.BuiltIn:
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
		elif next_token != null && cur_token.type == TL_GLSLTokenizer.ETokenType.Identifier && next_token.type == TL_GLSLTokenizer.ETokenType.Identifier:
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
		elif result.size() > 2 && cur_token.type == TL_GLSLTokenizer.ETokenType.Identifier && result[result.size() - 1].type == TL_GLSLTokenizer.ETokenType.Operator && result[result.size() - 1].data == ',' && result[result.size() - 2] is TL_GLSLParser_Model.TypeSuperToken:
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
		elif result.size() > 3 && cur_token.type == TL_GLSLTokenizer.ETokenType.Identifier && result[result.size() - 1].type == TL_GLSLTokenizer.ETokenType.Operator && result[result.size() - 1].data == '(' && result[result.size() - 2].type == TL_GLSLTokenizer.ETokenType.Identifier  && result[result.size() - 3] is TL_GLSLParser_Model.TypeSuperToken:
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
		elif is_ctrl_flow_head_token(cur_token):
			var super_tok = create_ctrl_flow_head_super_token([cur_token])
			result.append(super_tok)
			i += 1
		# elif cur_token.type == TL_GLSLTokenizer.ETokenType.Keyword && TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(cur_token.data):
		# 	var j : int = i + 1
		# 	var tokens_to_merge : Array[TL_GLSLTokenizer.Token]
		# 	tokens_to_merge.append(cur_token)
		# 	while j < tokens.size() &&  tokens[j].type == TL_GLSLTokenizer.ETokenType.Keyword && TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(tokens[j].data):
		# 		tokens_to_merge.append(tokens[j])
		# 		j += 1
		# 	var super_tok = create_qualifiers_super_token(tokens_to_merge)
		# 	result.append(super_tok)
		# 	i += tokens_to_merge.size()
		else:
			result.append(cur_token)
			i += 1

	return result

func _clean_tokens(tokens : Array[TL_GLSLTokenizer.Token]) -> Array[TL_GLSLTokenizer.Token]:
	var result : Array[TL_GLSLTokenizer.Token]
	for token in tokens:
		if not is_ignored_token_type(token.type):
			result.append(token)
	return result

func _rec_identify_vars_in(grp_node : TL_GLSLParser_Model.TokenGrpNode) -> int:
	if grp_node is TL_GLSLParser_Model.TokenGrpLeaf:
		return _identify_vars_in_leaf(grp_node)
	else :
		return _identify_vars_in_body(grp_node)

func _identify_vars_in_leaf(grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf) -> int:
	if grp_leaf is TL_GLSLParser_Model.TokenFuncHead:
		return 0

	var identified : TL_GLSLParser_Model.TokenGrpNode
	identified = TL_GLSLParser_Model.TokenVariableDecl.try_create_from(grp_leaf)
	if identified != null:
		grp_leaf.replace_with(identified)
	return 0

func _identify_vars_in_body(grp_body : TL_GLSLParser_Model.TokenGrpBody) -> int:
	var i : int = 0
	while i < grp_body._children.size():
		var grp_node : TL_GLSLParser_Model.TokenGrpNode = grp_body._children[i]
		var nb_remove_before = _rec_identify_vars_in(grp_node)
		i -= nb_remove_before
		i += 1
	return 0

func _rec_identify_blocks_in(grp_node : TL_GLSLParser_Model.TokenGrpNode) -> int:
	if grp_node is TL_GLSLParser_Model.TokenGrpLeaf:
		return _identify_blocks_in_leaf(grp_node)
	else :
		return _identify_blocks_in_body(grp_node)

func _identify_blocks_in_leaf(grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf) -> int:
	var identified : TL_GLSLParser_Model.TokenGrpNode
	identified = TL_GLSLParser_Model.TokenBaseControlFlow.try_create_from(grp_leaf)
	if identified != null:
		identified.remove_pendings()
		if identified.parent_ctrl_flow != null:
			identified.parent_ctrl_flow.attach_child(identified)
			grp_leaf.remove()
			return 2
		else:
			grp_leaf.replace_with(identified) 
			return 1

	identified = TL_GLSLParser_Model.TokenElse.try_create_from(grp_leaf)
	if identified != null:
		if identified.parent_ctrl_flow != null:
			identified.parent_ctrl_flow.attach_child(identified)
			grp_leaf.remove()
			return 2
		else:
			grp_leaf.replace_with(identified) 
			return 1

	identified = TL_GLSLParser_Model.TokenDoWhile.try_create_from(grp_leaf)
	if identified != null:
		identified.remove_pendings()
		if identified.parent_ctrl_flow != null:
			identified.parent_ctrl_flow.attach_child(identified)
			grp_leaf.remove()
			return 2
		else:
			grp_leaf.replace_with(identified) 
			return 1

	identified = TL_GLSLParser_Model.TokenFor.try_create_from(grp_leaf)
	if identified != null:
		identified.remove_pendings()
		if identified.parent_ctrl_flow != null:
			identified.parent_ctrl_flow.attach_child(identified)
			grp_leaf.remove()
			return 2
		else:
			grp_leaf.replace_with(identified) 
			return 1

	return 0

func _identify_blocks_in_body(grp_body : TL_GLSLParser_Model.TokenGrpBody) -> int:
	var identified : TL_GLSLParser_Model.TokenGrpNode
	identified = TL_GLSLParser_Model.TokenFuncBody.try_create_from(grp_body)
	if identified != null:
		grp_body.replace_with(identified)

	var i : int = 0
	while i < grp_body._children.size():
		var child : TL_GLSLParser_Model.TokenGrpNode = grp_body._children[i]
		var nb_remove_before = _rec_identify_blocks_in(child)
		i -= nb_remove_before
		i += 1
	
	return 0

func _rec_identify_struct_and_func_in(grp_node : TL_GLSLParser_Model.TokenGrpNode) -> int:
	if grp_node is TL_GLSLParser_Model.TokenGrpLeaf:
		return _identify_func_in_leaf(grp_node)
	else :
		return _identify_struct_and_func_in_body(grp_node)

func _identify_func_in_leaf(grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf) -> int:
	var identified : TL_GLSLParser_Model.TokenGrpNode
	identified = TL_GLSLParser_Model.TokenFuncHead.try_create_from(grp_leaf)
	if identified != null:
		var params_body : TL_GLSLParser_Model.TokenGrpBody = grp_leaf.parent._children[grp_leaf.idx_in_parent + 1]
		params_body.remove()
		grp_leaf.replace_with(identified)
	return 0

func _identify_struct_and_func_in_body(grp_body : TL_GLSLParser_Model.TokenGrpBody) -> int:
	var nb_removed_before : int = 0
	var identified : TL_GLSLParser_Model.TokenGrpNode
	identified = TL_GLSLParser_Model.TokenStruct.try_create_from(grp_body)
	if identified != null:
		var struct_grp : TL_GLSLParser_Model.TokenStruct = identified
		nb_removed_before = identified.remove_pendings()
		grp_body.replace_with(struct_grp)
		return nb_removed_before

	var i : int = 0
	while i < grp_body._children.size():
		var grp_node : TL_GLSLParser_Model.TokenGrpNode = grp_body._children[i]
		var nb_remove_before = _rec_identify_struct_and_func_in(grp_node)
		i -= nb_remove_before
		i += 1
	
	return 0

func _rec_link_leaves(grp_node : TL_GLSLParser_Model.TokenGrpNode, last_leaf : TL_GLSLParser_Model.TokenGrpLeaf) -> TL_GLSLParser_Model.TokenGrpLeaf:
	if grp_node is TL_GLSLParser_Model.TokenGrpLeaf:
		var leaf : TL_GLSLParser_Model.TokenGrpLeaf = grp_node
		leaf.prev_leaf = last_leaf
		if last_leaf != null:
			last_leaf.next_leaf = leaf
		return leaf
	if grp_node is TL_GLSLParser_Model.TokenGrpBody:
		var body : TL_GLSLParser_Model.TokenGrpBody = grp_node
		for node_grp : TL_GLSLParser_Model.TokenGrpNode in body._children:
			last_leaf = _rec_link_leaves(node_grp, last_leaf)
	return last_leaf

func _rec_generate_token_grp(type : TL_GLSLParser_Model.EBodyType) -> TL_GLSLParser_Model.TokenGrpBody:
	var body : TL_GLSLParser_Model.TokenGrpBody = TL_GLSLParser_Model.TokenGrpBody.new()
	body.type = type
	while _tok_idx < _tokens.size():
		if _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Operator:
			if _tokens[_tok_idx].data == ';':
				# _accumulate(_tokens[_tok_idx])
				_fill_with_accumulated(body)
			elif _tokens[_tok_idx].data == '{' || _tokens[_tok_idx].data == '[' || _tokens[_tok_idx].data == '(':
				var child_type : TL_GLSLParser_Model.EBodyType = TL_GLSLParser_Model.EBodyType.Curly
				if _tokens[_tok_idx].data == '[':
					child_type = TL_GLSLParser_Model.EBodyType.Square
				elif _tokens[_tok_idx].data == '(':
					child_type = TL_GLSLParser_Model.EBodyType.Round
				_fill_with_accumulated(body)
				_tok_idx += 1
				var token_grp_body = _rec_generate_token_grp(child_type)
				body.attach_child(token_grp_body)
			elif (type == TL_GLSLParser_Model.EBodyType.Curly && _tokens[_tok_idx].data == '}') || (type == TL_GLSLParser_Model.EBodyType.Square && _tokens[_tok_idx].data == ']') || (type == TL_GLSLParser_Model.EBodyType.Round && _tokens[_tok_idx].data == ')'):
				break
			else:
				_accumulate(_tokens[_tok_idx])
		elif _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Preprocessor:
			_fill_with_accumulated(body)
			var token_grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf = _create_token_grp_leaf([_tokens[_tok_idx]])
			body.attach_child(token_grp_leaf)
		elif _tokens[_tok_idx] is TL_GLSLParser_Model.CtrlFlowHeadSuperToken:
			_fill_with_accumulated(body)
			var token_grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf = _create_token_grp_leaf([_tokens[_tok_idx]])
			body.attach_child(token_grp_leaf)
		else :
			_accumulate(_tokens[_tok_idx])
		_tok_idx += 1

	_fill_with_accumulated(body)

	return body

func is_ignored_token_type(type : TL_GLSLTokenizer.ETokenType) -> bool:
	return type == TL_GLSLTokenizer.ETokenType.BlockComment || type == TL_GLSLTokenizer.ETokenType.LineComment || type == TL_GLSLTokenizer.ETokenType.Whitespace || type == TL_GLSLTokenizer.ETokenType.EOF

func is_ctrl_flow_head_token(token : TL_GLSLTokenizer.Token) -> bool:
	if token.type != TL_GLSLTokenizer.ETokenType.Keyword:
		return false
	return token.data == "if" || token.data == "else" || token.data == "do" || token.data == "while" || token.data == "for" || token.data == "switch"

func _accumulate(token : TL_GLSLTokenizer.Token):
	if not is_ignored_token_type(token.type):
		_tokens_accumulated.append(token)

func _fill_with_accumulated(body : TL_GLSLParser_Model.TokenGrpBody):
	if _tokens_accumulated.size() > 0:
		var token_grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf = _create_token_grp_leaf(_tokens_accumulated)
		_tokens_accumulated.clear()
		body.attach_child(token_grp_leaf)

func _create_token_grp_leaf(tokens : Array[TL_GLSLTokenizer.Token]) -> TL_GLSLParser_Model.TokenGrpLeaf:
	var token_grp_leaf : TL_GLSLParser_Model.TokenGrpLeaf = TL_GLSLParser_Model.TokenGrpLeaf.new()
	token_grp_leaf.tokens.append_array(tokens)
	return token_grp_leaf

static func debug_token_grp_to_str(token_grp_node : TL_GLSLParser_Model.TokenGrpNode) -> String:
	return _rec_debug_token_grp_to_str(token_grp_node, 0)

static func _rec_debug_token_grp_to_str(token_grp_node : TL_GLSLParser_Model.TokenGrpNode, depth : int) -> String:
	var str : String = ""
	var indent : String = ""
	for i in range(0, depth):
		indent += "\t"
	if token_grp_node is TL_GLSLParser_Model.TokenGrpLeaf:
		var leaf : TL_GLSLParser_Model.TokenGrpLeaf = token_grp_node
		str += indent + leaf.to_string() + "\n"
	else :
		var body : TL_GLSLParser_Model.TokenGrpBody = token_grp_node
		str += indent + body.to_string() + "\n"
		for child in body._children:
			str += _rec_debug_token_grp_to_str(child , depth + 1)
	
	return str
