extends Object
class_name TL_GLSLParser

class TokenGrpNode :
	pass

class TokenGrpBody extends TokenGrpNode :
	var token_grp_nodes : Array[TokenGrpNode]

class TokenGrpLeaf extends TokenGrpNode :
	var tokens : Array[TL_GLSLTokenizer.Token]

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
	pass

func _identify_grp_body(grp_body : TokenGrpBody) -> void:
	pass

func _rec_generate_token_grp() -> TokenGrpBody:
	var body : TokenGrpBody = TokenGrpBody.new()
	while _tok_idx < _tokens.size():
		if _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Operator:
			if _tokens[_tok_idx].data == ';':
				_accumulate(_tokens[_tok_idx])
				_fill_with_accumulated(body)
			elif _tokens[_tok_idx].data == '{':
				_fill_with_accumulated(body)
				_tok_idx += 1
				var token_grp_body = _rec_generate_token_grp()
				body.token_grp_nodes.append(token_grp_body)
			elif _tokens[_tok_idx].data == '}':
				break
			else :
				_accumulate(_tokens[_tok_idx])
		elif _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Preprocessor:
			_fill_with_accumulated(body)
			var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf([_tokens[_tok_idx]])
			body.token_grp_nodes.append(token_grp_leaf)
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
		body.token_grp_nodes.append(token_grp_leaf)

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
		str += indent + "|"
		for token in leaf.tokens:
			str += _inline_str(token.data) + '|'
		str += "\n"
	else :
		var body : TokenGrpBody = token_grp_node
		for child in body.token_grp_nodes:
			str += _rec_debug_token_grp_to_str(child , depth + 1)
	
	return str

static func _inline_str(str : String) -> String:
	return str.replace('\n', '\\n')