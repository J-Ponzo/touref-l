class_name TL_GLSLParser_Model

class SuperToken extends TL_GLSLTokenizer.Token:
	pass

class TypeSuperToken extends SuperToken:
	pass

# class QualifierSuperToken extends SuperToken:
# 	pass

class TokenGrpNode :
	var parent : TokenGrpBody = null
	var idx_in_parent : int = -1
	var pending_remove_before : Array[TokenGrpNode]
	var pending_remove_after : Array[TokenGrpNode]

	func remove_pendings() -> int:
		var nb_removed_before : int = pending_remove_before.size()

		while pending_remove_before.size() > 0:
			pending_remove_before[0].remove()
			pending_remove_before.remove_at(0)

		while pending_remove_after.size() > 0:
			pending_remove_after[0].remove()
			pending_remove_after.remove_at(0)

		return nb_removed_before

	func remove() -> void:
		# TODO remobe debug stub
		print("Removing " + to_string())
		# TODO

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
			var body_first_leaf = body.get_first_leaf()
			var body_last_leaf = body.get_last_leaf()
			if body_first_leaf != null:
				prev_leaf = body_first_leaf.prev_leaf
			if body_last_leaf != null:
				next_leaf = body_last_leaf.next_leaf

		if new_grp_node is TokenGrpLeaf:
			var leaf : TokenGrpLeaf = new_grp_node
			leaf.prev_leaf = prev_leaf
			leaf.next_leaf = next_leaf
		else :
			var body : TokenGrpBody = new_grp_node
			var body_first_leaf = body.get_first_leaf()
			var body_last_leaf = body.get_last_leaf()
			if body_first_leaf != null:
				body_first_leaf.prev_leaf = prev_leaf
			if body_last_leaf != null:
				body_last_leaf.next_leaf = next_leaf

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
		if _children.size() == 0:
			return null

		if _children[0] is TokenGrpLeaf:
			return _children[0]
		else :
			var body : TokenGrpBody = _children[0]
			return body.get_first_leaf()

	func get_last_leaf() -> TokenGrpLeaf:
		if _children.size() == 0:
			return null

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

	func _to_string() -> String:
		var str : String = "ROOT"
		if type == EBodyType.Curly:
			str = "{}"
		elif type == EBodyType.Square:
			str = "[]"
		elif type == EBodyType.Round:
			str = "()"
		return str

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
		var str : String = "|"
		for token in tokens:
			str += TL_GLSLParser_Model._inline_str(token.data) + '|'
		return str

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
			result.pending_remove_before.append(struct_head)
			result.name = struct_head.tokens[1].data
		
		for child in body._children:
			if not child is TokenGrpLeaf:
				return null

			var leaf_child : TokenGrpLeaf = child
			if leaf_child.tokens.size() < 2:
				return null

			var member :StructMember = StructMember.new()
			var first_type_idx : int = -1
			for i in range(0, leaf_child.tokens.size()):
				if leaf_child.tokens[i] is TypeSuperToken:
					first_type_idx = i
					member.type = leaf_child.tokens[first_type_idx].data
					break
			if first_type_idx == -1:
				return null

			if first_type_idx + 1 >= leaf_child.tokens.size() || leaf_child.tokens[first_type_idx + 1].type != TL_GLSLTokenizer.ETokenType.Identifier:
				return null
			else:
				member.name = leaf_child.tokens[first_type_idx + 1].data

			var qualifier_idx = first_type_idx - 1 
			while qualifier_idx >= 0 && leaf_child.tokens[qualifier_idx].type == TL_GLSLTokenizer.ETokenType.Keyword && TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(leaf_child.tokens[qualifier_idx].data):
				member.qualifiers.append(leaf_child.tokens[qualifier_idx].data)
				qualifier_idx -= 1
			
			result.members.append(member)

		var struct_variable : TokenGrpLeaf
		if body.idx_in_parent + 1 < body.parent._children.size() && body.parent._children[body.idx_in_parent + 1] is TokenGrpLeaf:
			struct_variable = body.parent._children[body.idx_in_parent + 1]
			if struct_variable.tokens.size() == 1 && struct_variable.tokens[0].type == TL_GLSLTokenizer.ETokenType.Identifier:
				result.pending_remove_after.append(struct_variable)
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
	var qualifiers : Array[String]
	var type : String
	var name : String

	func _to_string() -> String:
		var str : String = ""
		for qualifier in qualifiers:
			str += qualifier + " "
		str += type + " " + name
		return str;

class TokenVariableDecl extends TokenGrpLeaf:
	var qualifiers : Array[String]
	var type : String
	var name : String 
	var r_value : Array[TL_GLSLTokenizer.Token]

	func _to_string() -> String:
		var str : String = "<VAR_DECL>|"
		for qualifier in qualifiers:
			str += qualifier + " "
		str += type + " " + name
		if r_value.size() > 0:
			str += "=|"
			for tok in r_value:
				str += tok.data + "|"
		else:
			str += "|"

		return str

	static func try_create_from(leaf : TokenGrpLeaf) -> TokenVariableDecl:
		var result : TokenVariableDecl = TokenVariableDecl.new()

		var first_type_idx : int = -1
		for i in range(0, leaf.tokens.size()):
			if leaf.tokens[i] is TypeSuperToken:
				first_type_idx = i
				result.type = leaf.tokens[first_type_idx].data
				break
		if first_type_idx == -1:
			return null

		if first_type_idx + 1 >= leaf.tokens.size() || leaf.tokens[first_type_idx + 1].type != TL_GLSLTokenizer.ETokenType.Identifier:
			return null
		else:
			result.name = leaf.tokens[first_type_idx + 1].data

		var qualifier_idx = first_type_idx - 1 
		while qualifier_idx >= 0 && leaf.tokens[qualifier_idx].type == TL_GLSLTokenizer.ETokenType.Keyword && TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(leaf.tokens[qualifier_idx].data):
			result.qualifiers.append(leaf.tokens[qualifier_idx].data)
			qualifier_idx -= 1

		var i = first_type_idx + 2
		while i < leaf.tokens.size():
			result.r_value.append(leaf.tokens[i])
			i += 1

		result.tokens.append_array(leaf.tokens)
		return result

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
		params_str = params_str.substr(0, params_str.length() - 2)
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
				var split_toks = TL_GLSLParser_Model.split_toks_line(params_leaf.tokens,  TL_GLSLTokenizer.ETokenType.Operator, ',')
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
		
		for i : int in range(0, type_idx):
			param.qualifiers.append(toks_line[i].data)

		if toks_line.size() > type_idx + 1:
			param.name = toks_line[type_idx + 1].data

		return param

class TokenFuncBody extends TokenGrpBody:
	var func_head : TokenFuncHead

	func _to_string() -> String:
		var str : String = super._to_string() + "<FUNC_BODY>"
		return str
	
	static func try_create_from(body : TokenGrpBody) -> TokenFuncBody:
		var result : TokenFuncBody = TokenFuncBody.new()

		if body.idx_in_parent - 1 < 0 || body.parent == null || not body.parent._children[body.idx_in_parent - 1] is TokenFuncHead:
			return null
		result.func_head = body.parent._children[body.idx_in_parent - 1]

		result.type = EBodyType.Curly
		result._children = body._children
		return result

class TokenBaseControlFlow extends TokenGrpBody:
	var condition : Array[TL_GLSLTokenizer.Token]
	var keyword : String

	func _to_string() -> String:
		var str : String = super._to_string() + "<" + keyword + ">|"
		for tok in condition:
			str += tok.data + "|"
		return str
	
	static func try_create_from(leaf : TokenGrpLeaf) -> TokenBaseControlFlow:
		var result : TokenBaseControlFlow = TokenBaseControlFlow.new()

		if leaf.tokens.size() == 0:
			return null

		if leaf.tokens[0].type != TL_GLSLTokenizer.ETokenType.Keyword || not (leaf.tokens[0].data == "if" || leaf.tokens[0].data == "while" || leaf.tokens[0].data == "switch"):
			return null
		else:
			result.keyword = leaf.tokens[0].data

		if leaf.idx_in_parent + 2 >= leaf.parent._children.size():
			return null

		var next_sibling : TokenGrpNode = leaf.parent._children[leaf.idx_in_parent + 1]
		if not next_sibling is TokenGrpBody:
			return null
		else:
			var sibling_body : TokenGrpBody = next_sibling
			if sibling_body.type != EBodyType.Round || sibling_body._children.size() != 1 || not sibling_body._children[0] is TokenGrpLeaf:
				return null;
			var condition_leaf : TokenGrpLeaf =  sibling_body._children[0]
			result.condition = condition_leaf.tokens

		var next_next_sibling : TokenGrpNode = leaf.parent._children[leaf.idx_in_parent + 2]
		if next_next_sibling is TokenGrpBody:
			var sibling_body : TokenGrpBody = next_next_sibling
			if sibling_body.type != EBodyType.Curly:
				return null
			result._children = next_next_sibling._children
		else :
			result._children.append(next_next_sibling)

		result.type = EBodyType.Curly
		return result

class TokenElse extends TokenGrpBody:
	func _to_string() -> String:
		var str : String = super._to_string() + "<else>"
		return str
	
	static func try_create_from(leaf : TokenGrpLeaf) -> TokenElse:
		var result : TokenElse = TokenElse.new()

		if leaf.tokens.size() == 0:
			return null

		if leaf.tokens[0].type != TL_GLSLTokenizer.ETokenType.Keyword ||  leaf.tokens[0].data != "else":
			return null

		if leaf.idx_in_parent + 1 < leaf.parent._children.size():
			var next_sibling : TokenGrpNode = leaf.parent._children[leaf.idx_in_parent + 1]
			if next_sibling is TokenGrpBody:
				var sibling_body : TokenGrpBody = next_sibling
				if sibling_body.type != EBodyType.Curly:
					return null
				result._children = next_sibling._children
		else :
			var unique_instr_leaf : TokenGrpLeaf = TokenGrpLeaf.new()
			for i in range(1, leaf.tokens.size()):
				unique_instr_leaf.tokens.append(leaf.tokens[i])
			result._children.append(unique_instr_leaf)

		result.type = EBodyType.Curly
		return result

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

static func _inline_str(str : String) -> String:
	return str.replace('\n', '\\n')
