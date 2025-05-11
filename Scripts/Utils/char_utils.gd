extends Object
class_name TL_CharUtils

const CHAR_TO_UNICODE = {
	'\t': 9,
	'\n': 10,
	'\r': 13,
	' ': 32,
	'!': 33,
	'"': 34,
	'#': 35,
	'*': 42,
	'.': 46,
	'/': 47,
	'0': 48,
	'9': 57,
	':': 58,
	'@': 64,
	'A': 65,
	'Z': 90,
	'[': 91,
	'_': 95,
	'`': 96,
	'a': 97,
	'z': 122,
	'{': 123,
	'~': 126,
	'f': 202
}

static func is_digit(unicode : int) -> bool:
	return (unicode >= CHAR_TO_UNICODE['0'] && unicode <= CHAR_TO_UNICODE['9']);;

static func is_symbol(unicode : int) -> bool:
	return unicode != CHAR_TO_UNICODE['_'] && ((unicode >= CHAR_TO_UNICODE['!'] && unicode <= CHAR_TO_UNICODE['/']) || (unicode >= CHAR_TO_UNICODE[':'] && unicode <= CHAR_TO_UNICODE['@']) || (unicode >= CHAR_TO_UNICODE['['] && unicode <= CHAR_TO_UNICODE['`']) || (unicode >= CHAR_TO_UNICODE['{'] && unicode <= CHAR_TO_UNICODE['~']) || unicode == CHAR_TO_UNICODE['\t'] || unicode == CHAR_TO_UNICODE[' ']);

static func is_whitespace(unicode : int) -> bool:
	return (unicode == CHAR_TO_UNICODE[' ']) || (unicode == 0x00a0) || (unicode == 0x1680) || (unicode >= 0x2000 && unicode <= 0x200b) || (unicode == 0x202f) || (unicode == 0x205f) || (unicode == 0x3000) || (unicode == 0x2028) || (unicode == 0x2029) || (unicode >= 0x0009 && unicode <= 0x000d) || (unicode == 0x0085)

static func is_identifier_head(unicode : int) -> bool:
	return unicode == CHAR_TO_UNICODE['_'] || unicode >= CHAR_TO_UNICODE['a'] && unicode <= CHAR_TO_UNICODE['z'] || unicode >= CHAR_TO_UNICODE['A'] && unicode <= CHAR_TO_UNICODE['Z']

static func is_identifier_tail(unicode : int) -> bool:
	return is_digit(unicode) || is_identifier_head(unicode)
