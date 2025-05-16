extends Object
class_name TL_GLSLParser

class TokenGrpNode :
	var parent : TokenGrpBody = null
	var idx_in_parent : int = -1
	func replace_with(new_grp_node : TokenGrpNode) -> bool:
		if parent == null:
			return false
		new_grp_node.parent = parent
		parent._children[idx_in_parent] = new_grp_node
		return true

class TokenGrpBody extends TokenGrpNode :
	var _children : Array[TokenGrpNode] = []
	func attach_child(child : TokenGrpNode) -> void:
		child.idx_in_parent = _children.size()
		_children.append(child)
		child.parent = self

class TokenGrpLeaf extends TokenGrpNode :
	var tokens : Array[TL_GLSLTokenizer.Token]
	func _to_string() -> String:
		var str : String = "|"
		for token in tokens:
			str += TL_GLSLParser._inline_str(token.data) + '|'
		return str

static func split_toks_line(toks_line : Array[TL_GLSLTokenizer.Token], type : TL_GLSLTokenizer.ETokenType):
	var result : Array[Array]
	var i : int = 0
	for tok : TL_GLSLTokenizer.Token in toks_line:
		if tok.type == type:
			i += 1
		else :
			if result.size() < i + 1:
				result.append([])
			result[i].append(tok)
	return result

# TODO make this work with func qualifiers (inline)
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
		var result : TokenFuncHead = TokenFuncHead.new()

		var identifier_idx : int = -1
		for i in range(0, leaf.tokens.size()):
			if leaf.tokens[i].type == TL_GLSLTokenizer.ETokenType.Identifier:
				identifier_idx = i
				result.name = leaf.tokens[identifier_idx].data
				break
		if identifier_idx == -1:
			return null

		if leaf.tokens[identifier_idx - 1].type != TL_GLSLTokenizer.ETokenType.BuiltIn || not TL_GLSLSyntax.GLSL_BASE_TYPES.has(leaf.tokens[identifier_idx - 1].data):
			return null
		else:
			result.return_type = leaf.tokens[identifier_idx - 1].data

		for i : int in range(0, identifier_idx - 1):
			result.qualifiers.append(leaf.tokens[i].data)

		if leaf.tokens.size() <= identifier_idx + 1 or leaf.tokens[identifier_idx + 1].type != TL_GLSLTokenizer.ETokenType.Operator or leaf.tokens[identifier_idx + 1].data != '(':
			return null
		
		var last_token : TL_GLSLTokenizer.Token = leaf.tokens[leaf.tokens.size() - 1]
		if last_token.type != TL_GLSLTokenizer.ETokenType.Operator or last_token.data != ')':
			return null

		var params_toks_line : Array[TL_GLSLTokenizer.Token] = []
		for i in range(identifier_idx + 2, leaf.tokens.size() - 1):
			params_toks_line.append(leaf.tokens[i])
		var split_toks = TL_GLSLParser.split_toks_line(params_toks_line,  TL_GLSLTokenizer.ETokenType.Operator)
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
			if toks_line[i].type == TL_GLSLTokenizer.ETokenType.BuiltIn && TL_GLSLSyntax.GLSL_BASE_TYPES.has(toks_line[i].data):
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

func parse(tokens : Array[TL_GLSLTokenizer.Token]) -> TokenGrpNode:
	_tokens = tokens

	var root : TokenGrpBody = _rec_generate_token_grp()
	_rec_identify_grps_in(root)

	return root

func _rec_identify_grps_in(grp_node : TokenGrpNode) -> void:
	if grp_node is TokenGrpLeaf:
		_identify_grp_leaf(grp_node)
	else :
		_identify_grp_body(grp_node)

func _identify_grp_leaf(grp_leaf : TokenGrpLeaf) -> void:
	var identified : TokenGrpNode
	identified = TokenFuncHead.try_create_from(grp_leaf)
	if identified != null:
		grp_leaf.replace_with(identified)

func _identify_grp_body(grp_body : TokenGrpBody) -> void:
	for grp_node : TokenGrpNode in grp_body._children:
		_rec_identify_grps_in(grp_node)

func _rec_generate_token_grp() -> TokenGrpBody:
	var body : TokenGrpBody = TokenGrpBody.new()
	while _tok_idx < _tokens.size():
		if _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Operator:
			if _tokens[_tok_idx].data == ';':
				# _accumulate(_tokens[_tok_idx])
				_fill_with_accumulated(body)
			elif _tokens[_tok_idx].data == '{':
				_fill_with_accumulated(body)
				_tok_idx += 1
				var token_grp_body = _rec_generate_token_grp()
				body.attach_child(token_grp_body)
			elif _tokens[_tok_idx].data == '}':
				break
			else :
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
