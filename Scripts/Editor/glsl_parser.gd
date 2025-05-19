extends Object
class_name TL_GLSLParser

class SuperToken extends TL_GLSLTokenizer.Token:
	pass

class TypeSuperToken extends SuperToken:
	pass

class TokenGrpNode :
	var parent : TokenGrpBody = null
	var idx_in_parent : int = -1

	func remove() -> void:
		for i in range(idx_in_parent, parent._children.size()):
			parent._children[i].idx_in_parent -= 1

	func replace_with(new_grp_node : TokenGrpNode) -> bool:
		if parent == null:
			return false
		new_grp_node.parent = parent
		new_grp_node.idx_in_parent = idx_in_parent
		parent._children[idx_in_parent] = new_grp_node

		var prev_leaf : TokenGrpLeaf
		var next_leaf : TokenGrpLeaf
		if self is TokenGrpLeaf:
			var leaf : TokenGrpLeaf = self
			prev_leaf = leaf.prev_leaf
			next_leaf = leaf.next_leaf
		else :
			var body : TokenGrpBody = self
			prev_leaf = body.get_first_leaf().prev_leaf
			next_leaf = body.get_last_leaf().next_leaf

		if new_grp_node is TokenGrpLeaf:
			var leaf : TokenGrpLeaf = new_grp_node
			leaf.prev_leaf = prev_leaf
			leaf.next_leaf = next_leaf
		else :
			var body : TokenGrpBody = new_grp_node
			body.get_first_leaf().prev_leaf = prev_leaf
			body.get_last_leaf().next_leaf = next_leaf

		return true

enum EBodyType {
	Root,
	Square,
	Round,
	Curly
}

class TokenGrpBody extends TokenGrpNode :
	var type : EBodyType
	var _children : Array[TokenGrpNode] = []

	func get_first_leaf() -> TokenGrpLeaf:
		if _children[0] is TokenGrpLeaf:
			return _children[0]
		else :
			var body : TokenGrpBody = _children[0]
			return body.get_first_leaf()

	func get_last_leaf() -> TokenGrpLeaf:
		if _children[_children.size() - 1] is TokenGrpLeaf:
			return _children[_children.size() - 1]
		else :
			var body : TokenGrpBody = _children[_children.size() - 1]
			return body.get_last_leaf()
		
	func attach_child(child : TokenGrpNode) -> void:
		child.idx_in_parent = _children.size()
		_children.append(child)
		child.parent = self

	func remove() -> void:
		while _children.size() > 0:
			_children[0].remove()
		parent._children.remove_at(idx_in_parent)
		super.remove()

class TokenGrpLeaf extends TokenGrpNode :
	var tokens : Array[TL_GLSLTokenizer.Token]
	var prev_leaf : TokenGrpLeaf
	var next_leaf : TokenGrpLeaf

	func remove() -> void:
		if prev_leaf != null:
			prev_leaf.next_leaf = next_leaf
		if next_leaf != null:
			next_leaf.prev_leaf = prev_leaf
		parent._children.remove_at(idx_in_parent)
		super.remove()

	func _to_string() -> String:
		var parent_body_type : String = ""
		if parent.type == EBodyType.Curly:
			parent_body_type += "{}"
		elif parent.type == EBodyType.Square:
			parent_body_type += "[]"
		elif parent.type == EBodyType.Round:
			parent_body_type += "()"
		var str : String = parent_body_type + "|"
		for token in tokens:
			str += TL_GLSLParser._inline_str(token.data) + '|'
		return str

static func split_toks_line(toks_line : Array[TL_GLSLTokenizer.Token], type : TL_GLSLTokenizer.ETokenType, data : String):
	var result : Array[Array]
	var i : int = 0
	for tok : TL_GLSLTokenizer.Token in toks_line:
		if tok.type == type && tok.data == data:
			i += 1
		else :
			if result.size() < i + 1:
				result.append([])
			result[i].append(tok)
	return result

class TokenStruct extends TokenGrpLeaf:
	var name : String
	var members : Array[StructMember]
	var variable_name : String

	static func try_create_from(body : TokenGrpBody) -> TokenStruct:
		if body.parent == null || body.idx_in_parent == 0 || body.parent.type != EBodyType.Root:
			return null;

		var result : TokenStruct = TokenStruct.new()

		var struct_head : TokenGrpLeaf
		if (not body.parent._children[body.idx_in_parent - 1] is TokenGrpLeaf) || body.parent._children[body.idx_in_parent - 1] is TokenStruct :	# for some reason get_class() returns RefCounted(). So we can't check the specific class instead
			return null
		else :
			struct_head = body.parent._children[body.idx_in_parent - 1]

		if struct_head.tokens[0].type != TL_GLSLTokenizer.ETokenType.Keyword || struct_head.tokens[0].data != "struct":
			return null
		
		if struct_head.tokens[1].type != TL_GLSLTokenizer.ETokenType.Identifier:
			return null
		else:
			result.name = struct_head.tokens[1].data
		
		for child in body._children:
			if not child is TokenGrpLeaf:
				return null

			var leaf_child : TokenGrpLeaf = child
			if leaf_child.tokens.size() < 2:
				return null

			var member :StructMember = StructMember.new()
			if not leaf_child.tokens[0] is TypeSuperToken:
				return null
			else:
				member.type = leaf_child.tokens[0].data

			if leaf_child.tokens[1].type != TL_GLSLTokenizer.ETokenType.Identifier:
				return null
			else:
				member.name = leaf_child.tokens[1].data
			
			result.members.append(member)

		var struct_variable : TokenGrpLeaf
		if body.idx_in_parent + 1 < body.parent._children.size() && body.parent._children[body.idx_in_parent + 1] is TokenGrpLeaf:
			struct_variable = body.parent._children[body.idx_in_parent + 1]
			if struct_variable.tokens.size() == 1 && struct_variable.tokens[0].type == TL_GLSLTokenizer.ETokenType.Identifier:
				result.variable_name = struct_variable.tokens[0].data

		return result

	func _to_string() -> String:
		var str : String = "<STRUCT>|struct "
		str += name + "{"
		var members_str : String = ""
		for member in members:
			members_str += member.to_string() + "; "
		members_str = members_str.substr(0, members_str.length() - 2)
		str += members_str + "}"
		if variable_name != "":
			str += " " + variable_name
		return str

class StructMember :
	var type : String
	var name : String

	func _to_string() -> String:
		var str : String = type + " " + name
		return str;

class TokenFuncHead extends TokenGrpLeaf:
	var qualifiers : Array[String]
	var return_type : String
	var name : String
	var params : Array[FuncParam] 

	func _to_string() -> String:
		var str : String = "<FUNC_HEAD>|"
		for qualifier in qualifiers:
			str += qualifier + " "
		str += return_type + " " + name + "("
		var params_str : String = ""
		for param in params:
			params_str += param.to_string() + ", "
		params_str += params_str.substr(0, params_str.length() - 2)
		str += params_str + ")|"

		return str

	static func try_create_from(leaf : TokenGrpLeaf) -> TokenFuncHead:
		if leaf.parent.type != EBodyType.Root:
			return null;

		var result : TokenFuncHead = TokenFuncHead.new()

		var first_type_idx : int = -1
		for i in range(0, leaf.tokens.size()):
			if leaf.tokens[i] is TypeSuperToken:
				first_type_idx = i
				result.return_type = leaf.tokens[first_type_idx].data
				break
		if first_type_idx == -1:
			return null

		if leaf.tokens.size() < first_type_idx + 2 || leaf.tokens[first_type_idx + 1].type != TL_GLSLTokenizer.ETokenType.Identifier:
			return null
		else:
			result.name = leaf.tokens[first_type_idx + 1].data

		for i : int in range(0, first_type_idx):
			result.qualifiers.append(leaf.tokens[i].data)

		if leaf.idx_in_parent + 1 >= leaf.parent._children.size():
			return null
		var next_sibling : TokenGrpNode = leaf.parent._children[leaf.idx_in_parent + 1]
		if not next_sibling is TokenGrpBody:
			return null
		else:
			var sibling_body : TokenGrpBody = next_sibling
			if sibling_body.type != EBodyType.Round || sibling_body._children.size() > 1:
				return null;
			
			if sibling_body._children.size() == 1:
				var params_leaf : TokenGrpLeaf = sibling_body._children[0]
				var split_toks = TL_GLSLParser.split_toks_line(params_leaf.tokens,  TL_GLSLTokenizer.ETokenType.Operator, ',')
				for param_toks in split_toks:
					var param : FuncParam = FuncParam.parse_param_toks_line(param_toks)
					if param != null:
						result.params.append(param)

		var params_toks_line : Array[TL_GLSLTokenizer.Token] = []
		for i in range(first_type_idx + 3, leaf.tokens.size() - 1):
			params_toks_line.append(leaf.tokens[i])
		var split_toks = TL_GLSLParser.split_toks_line(params_toks_line,  TL_GLSLTokenizer.ETokenType.Operator, ',')
		for param_toks in split_toks:
			var param : FuncParam = FuncParam.parse_param_toks_line(param_toks)
			if param != null:
				result.params.append(param)

		result.tokens.append_array(leaf.tokens)
		return result

class FuncParam :
	var qualifiers : Array[String]
	var type : String
	var name : String
	func _to_string() -> String:
		var str : String = ""
		for qualifier in qualifiers:
			str += qualifier + " "
		str += type 
		if name != "":
			str += " " + name
		return str

	# static func parse_param_toks_line(toks_line :  Array[TL_GLSLTokenizer.Token]) -> FuncParam:
	static func parse_param_toks_line(toks_line :  Array) -> FuncParam:
		var param : FuncParam = FuncParam.new()
		var type_idx : int = -1
		for i in range(0, toks_line.size()):
			if toks_line[i] is TypeSuperToken:
				type_idx = i
				param.type = toks_line[type_idx].data
				break
		if type_idx == -1:
			return null
		
		for i : int in range(0, type_idx - 1):
			param.qualifiers.append(toks_line[i])

		if toks_line.size() > type_idx + 1:
			param.name = toks_line[type_idx + 1].data

		return param

var _tokens : Array[TL_GLSLTokenizer.Token]
var _tok_idx : int = 0

var _tokens_accumulated : Array[TL_GLSLTokenizer.Token] = []

func create_type_super_token(tokens_to_merge : Array[TL_GLSLTokenizer.Token]) -> TypeSuperToken:
	var result : TypeSuperToken = TypeSuperToken.new()
	result.type = TL_GLSLTokenizer.ETokenType.Other
	result.pos = tokens_to_merge[0].pos
	result.line = tokens_to_merge[0].line
	result.col = tokens_to_merge[0].col
	var cummuled_data : String = ""
	for tok in tokens_to_merge:
		cummuled_data += tok.data
	result.data = cummuled_data

	return result

func _identify_type_super_tokens(tokens : Array[TL_GLSLTokenizer.Token]) -> Array[TL_GLSLTokenizer.Token]:
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
		elif result.size() > 2 && cur_token.type == TL_GLSLTokenizer.ETokenType.Identifier && result[result.size() - 1].type == TL_GLSLTokenizer.ETokenType.Operator && result[result.size() - 1].data == ',' && result[result.size() - 2] is TypeSuperToken:
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
		elif result.size() > 3 && cur_token.type == TL_GLSLTokenizer.ETokenType.Identifier && result[result.size() - 1].type == TL_GLSLTokenizer.ETokenType.Operator && result[result.size() - 1].data == '(' && result[result.size() - 2].type == TL_GLSLTokenizer.ETokenType.Identifier  && result[result.size() - 3] is TypeSuperToken:
			var super_tok = create_type_super_token([cur_token])
			result.append(super_tok)
			i += 1
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

func parse(tokens : Array[TL_GLSLTokenizer.Token]) -> TokenGrpNode:
	_tokens = tokens
	var clean_tokens : Array[TL_GLSLTokenizer.Token] = _clean_tokens(_tokens)
	var super_tokens : Array[TL_GLSLTokenizer.Token] = _identify_type_super_tokens(clean_tokens)
	# TODO remove this debug stub
	# for token in super_tokens:
	# 	var other_mark = ""
	# 	if token.type == TL_GLSLTokenizer.ETokenType.Other:
	# 		other_mark = "=> "
	# 	print(other_mark + token.data)
	# TODO

	# TODO remove this debug stub
	# print("----- TOKENS -----")
	# for tok in _tokens:
	# 	print(tok.data)
	# TODO

	_tokens = super_tokens
	var root : TokenGrpBody = _rec_generate_token_grp(EBodyType.Root)
	var leaf : TokenGrpLeaf = _rec_link_leaves(root, null)
	var linked_leaves : Array[TokenGrpLeaf]
	
	# TODO remove this debug stub
	print("----- LEAVES -----")
	while leaf != null:
		linked_leaves.insert(0, leaf)
		leaf = leaf.prev_leaf
	for linked_leaf in linked_leaves:
		print(linked_leaf)
	# TODO

	_rec_identify_grps_in(root)

	return root

func _rec_link_leaves(grp_node : TokenGrpNode, last_leaf : TokenGrpLeaf) -> TokenGrpLeaf:
	if grp_node is TokenGrpLeaf:
		var leaf : TokenGrpLeaf = grp_node
		leaf.prev_leaf = last_leaf
		if last_leaf != null:
			last_leaf.next_leaf = leaf
		return leaf
	if grp_node is TokenGrpBody:
		var body : TokenGrpBody = grp_node
		for node_grp : TokenGrpNode in body._children:
			last_leaf = _rec_link_leaves(node_grp, last_leaf)
	return last_leaf

func _rec_identify_grps_in(grp_node : TokenGrpNode) -> int:
	if grp_node is TokenGrpLeaf:
		return _identify_grp_leaf(grp_node)
	else :
		return _identify_grp_body(grp_node)

func _identify_grp_leaf(grp_leaf : TokenGrpLeaf) -> int:
	var identified : TokenGrpNode
	identified = TokenFuncHead.try_create_from(grp_leaf)
	if identified != null:
		var params_body : TokenGrpBody = grp_leaf.parent._children[grp_leaf.idx_in_parent + 1]
		params_body.remove()
		grp_leaf.replace_with(identified)
	return 0

func _identify_grp_body(grp_body : TokenGrpBody) -> int:
	var nb_removed : int = 0
	var identified : TokenGrpNode
	identified = TokenStruct.try_create_from(grp_body)
	if identified != null:
		var struct_grp : TokenStruct = identified
		var head_leaf : TokenGrpLeaf = grp_body.parent._children[grp_body.idx_in_parent - 1]
		head_leaf.remove()
		nb_removed += 1
		if struct_grp.variable_name != "":
			var var_leaf : TokenGrpLeaf = grp_body.parent._children[grp_body.idx_in_parent + 1]
			var_leaf.remove()
			# nb_removed += 1
		grp_body.replace_with(struct_grp)
		return nb_removed

	var i : int = 0
	while i < grp_body._children.size():
		# TODO remove this debug stub
		# print(i)
		# var str : String = str(grp_body._children.size()) + " : "
		# for j : int in range(0, grp_body._children.size()):
		# 	str += str(grp_body._children[j].idx_in_parent) + ", "
		# print(str)
		# TODO

		var grp_node : TokenGrpNode = grp_body._children[i]
		var nb_remove_before = _rec_identify_grps_in(grp_node)
		i -= nb_remove_before
		i += 1
	
	return 0

func _rec_generate_token_grp(type : EBodyType) -> TokenGrpBody:
	var body : TokenGrpBody = TokenGrpBody.new()
	body.type = type
	while _tok_idx < _tokens.size():
		if _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Operator:
			if _tokens[_tok_idx].data == ';':
				# _accumulate(_tokens[_tok_idx])
				_fill_with_accumulated(body)
			elif _tokens[_tok_idx].data == '{' || _tokens[_tok_idx].data == '[' || _tokens[_tok_idx].data == '(':
				var child_type : EBodyType = EBodyType.Curly
				if _tokens[_tok_idx].data == '[':
					child_type = EBodyType.Square
				elif _tokens[_tok_idx].data == '(':
					child_type = EBodyType.Round
				_fill_with_accumulated(body)
				_tok_idx += 1
				var token_grp_body = _rec_generate_token_grp(child_type)
				body.attach_child(token_grp_body)
			elif (type == EBodyType.Curly && _tokens[_tok_idx].data == '}') || (type == EBodyType.Square && _tokens[_tok_idx].data == ']') || (type == EBodyType.Round && _tokens[_tok_idx].data == ')'):
				break
			else:
				_accumulate(_tokens[_tok_idx])
		elif _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Preprocessor:
			_fill_with_accumulated(body)
			var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf([_tokens[_tok_idx]])
			body.attach_child(token_grp_leaf)
		else :
			_accumulate(_tokens[_tok_idx])
		_tok_idx += 1

	_fill_with_accumulated(body)

	return body

func is_ignored_token_type(type : TL_GLSLTokenizer.ETokenType) -> bool:
	return type == TL_GLSLTokenizer.ETokenType.BlockComment || type == TL_GLSLTokenizer.ETokenType.LineComment || type == TL_GLSLTokenizer.ETokenType.Whitespace || type == TL_GLSLTokenizer.ETokenType.EOF

func _accumulate(token : TL_GLSLTokenizer.Token):
	if not is_ignored_token_type(token.type):
		_tokens_accumulated.append(token)
	# TODO Remove debug stub
	# else:
	# 	print("ignored : " + token.data)
	# TODO

func _fill_with_accumulated(body : TokenGrpBody):
	if _tokens_accumulated.size() > 0:
		var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf(_tokens_accumulated)
		_tokens_accumulated.clear()
		body.attach_child(token_grp_leaf)

func _create_token_grp_leaf(tokens : Array[TL_GLSLTokenizer.Token]) -> TokenGrpLeaf:
	var token_grp_leaf : TokenGrpLeaf = TokenGrpLeaf.new()
	token_grp_leaf.tokens.append_array(tokens)
	return token_grp_leaf

static func debug_token_grp_to_str(token_grp_node : TokenGrpNode) -> String:
	return _rec_debug_token_grp_to_str(token_grp_node, 0)

static func _rec_debug_token_grp_to_str(token_grp_node : TokenGrpNode, depth : int) -> String:
	var str : String = ""
	var indent : String = ""
	for i in range(0, depth):
		indent += "\t"
	if token_grp_node is TokenGrpLeaf:
		var leaf : TokenGrpLeaf = token_grp_node
		str += indent + leaf.to_string() + "\n"
	else :
		var body : TokenGrpBody = token_grp_node
		for child in body._children:
			str += _rec_debug_token_grp_to_str(child , depth + 1)
	
	return str

static func _inline_str(str : String) -> String:
	return str.replace('\n', '\\n')
