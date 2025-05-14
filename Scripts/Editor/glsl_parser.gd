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
var _token_grp_stack : Array[TokenGrpBody]

func parse(tokens : Array[TL_GLSLTokenizer.Token]) -> TokenGrpNode:
	_tokens = tokens

	var root : TokenGrpBody = _rec_generate_token_grp()
	print("ROOT")
	return root
	
func _rec_generate_token_grp() -> TokenGrpBody:
	var body : TokenGrpBody = TokenGrpBody.new()
	var tokens_accumulated : Array[TL_GLSLTokenizer.Token] = []
	while _tok_idx < _tokens.size():
		if _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Operator:
			if _tokens[_tok_idx].data == ';':
				tokens_accumulated.append(_tokens[_tok_idx])
				var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf(tokens_accumulated)
				body.token_grp_nodes.append(token_grp_leaf)
				tokens_accumulated.clear()
			elif _tokens[_tok_idx].data == '{':
				var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf(tokens_accumulated)
				body.token_grp_nodes.append(token_grp_leaf)
				tokens_accumulated.clear()
				_tok_idx += 1
				var token_grp_body = _rec_generate_token_grp()
				body.token_grp_nodes.append(token_grp_body)
			elif _tokens[_tok_idx].data == '}':
				break
			else :
				if not is_ignored_token_type(_tokens[_tok_idx].type):
					tokens_accumulated.append(_tokens[_tok_idx])
		elif _tokens[_tok_idx].type == TL_GLSLTokenizer.ETokenType.Preprocessor:
			if tokens_accumulated.size() > 0:
				var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf(tokens_accumulated)
				body.token_grp_nodes.append(token_grp_leaf)
				tokens_accumulated.clear()
			var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf([_tokens[_tok_idx]])
			body.token_grp_nodes.append(token_grp_leaf)
		else :
			if not is_ignored_token_type(_tokens[_tok_idx].type):
				tokens_accumulated.append(_tokens[_tok_idx])
		_tok_idx += 1

	if tokens_accumulated.size() > 0:
		var token_grp_leaf : TokenGrpLeaf = _create_token_grp_leaf(tokens_accumulated)
		body.token_grp_nodes.append(token_grp_leaf)
		# print(debug_token_grp_to_str(token_grp_leaf))

	return body

func is_ignored_token_type(type : TL_GLSLTokenizer.ETokenType) -> bool:
	return type == TL_GLSLTokenizer.ETokenType.BlockComment || type == TL_GLSLTokenizer.ETokenType.LineComment || type == TL_GLSLTokenizer.ETokenType.Whitespace || type == TL_GLSLTokenizer.ETokenType.EOF

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