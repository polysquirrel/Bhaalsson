# Bhaal's son

## About
*Bhaal's son* (or *bhaalsson* in file names) is a parser and formatter
of `Json` data for *WeiDU*, the scripting language of Infinity Engine mods.
Its creation was motivated by very limited flexibility of 2da configuration
files supported by WeiDU out of the box and the lack of any data structures.
This library aims to allow mods much more complex configuration files, possibly
converting some data - such as game items and spells - from their binary files
(or weidu code creating it) to a format easily readable by humans, making
it possible to precisely tweak a mod's effects even by end users. For example,
a mod which changes the class and statistics of any game NPCs could have 
all its data in Json files, easily modifiable and extendedable by players
to suit their needs.

Aside from reading Json data from files and converting it to WeiDU variables 
and arrays, there are functions for retrieving nested subexpressions, 
performing complex transformations (like functor's 'map' in functional 
languages) and treating Json data as a basis for more complex data structures, 
such as stacks.



## Usage
Unpack the archive in your mod's directory and simply include the files with 
the functions you'd like to use in your mod's `tp2` file like any other `tpa` 
file. If you'd rather place the files in some other directory under your mod's
structure, declare a `BHAALSSON_DIR` variable with the path to the folder with
the files before the include directrive, so they are able to find themselves.



## Performance
*WeiDU* was never meant to be treated as a programming language or used to the
extent it is used now; this unexpected popularity means many of language 
features are grossly inefective, from string concatenation to simple argument
passing between functions. Care has been taken to avoid the most common 
pitfalls and pick always the faster rather than simpler solution, but 
ultimately, all data is stored inside string variables, forcing parsing and
copying of the whole string whenever a structure is modified. This library is
no substitute for true native data structures from the performance standpoint
and some experimenting may be necessary to verify if it is suitable for your
needs.



## Whose son?
Json is a simple, but very flexible data format commonly used on the internet
to exchange data or provide configuration. A json expression can be one of the
following:

#### Json string
A json string is quoted within a pair of `'"'`, with the `'\'` and `'"'` 
characters preceded by an additional, otherwise ignored `\`:

	"the name of our favourity psycho is \"Imoen\""
	"this \"string\" does not contain any '\\' characters"
Functions for converting between a raw expression and its unquoted, real
values are provided.

#### Json number
As Weidu has no support for fractions, only integral values are supported. 
To compensate, the value can be in any of the formats accepted by Weidu:

	42
	-42
	0xff
	0o766
	+0x80

#### Json Boolean
A json Boolean value is simply one of:

	false
	true
Booleans are converted when their value is requested to integers `0` and `1`
respectively, exactly as integer expressions can appear as conditions in
WeiDU code.

#### Json array
A json array is a sequence of any numer of json expressions, separated by the
`','` character and surrounded in a pair of brackets `'['`/`']'`:

	[]
	[1, "two" , {"three": 3}]

#### Json object
A json object is a map/dictionary simmilar to WeiDU arrays indexed by arbirary 
strings. It is a sequence of any number of entries/fields separated by `','`
and surrounded in a pair of braces `'{'`/`'}'`. Each entry consists of 
a key/name, which must be a json string, followed by a `':'` and and any json 
expression as its value:

	{}
	{ "name": "Imoen", "abilities": {"DEX": 18, "INT": 17}}
	
### Unsupported features
As WeiDU does not have a concept of null values or any practical means of 
implementing rational fractions, there is no support for the `null` expression
and rational numbers.

### Extensions
*Bhaal's son* aims to extend the Json standard with domain specific expressions
such as named constants for commonly used values. This support is currently
very limited, but it is hoped to grow as the library becomes used.

#### Translation reference
A WeiDU literal for a translation string reference is honored as a json 
expression. It is resolved whenever a json expression is converted to
a weidu variable (at the exact places where a quoted string would be converted
to its unquoted value):
	
	@42


#### Regular expression
A regular expression is a Json string preceded immediately by a `'R'` or `'r'`
character:

	r"Xzar\|Montaron"

The regular expression format is that of WeiDU. In general, regular expressions
in input are treated as standard json strings, converted automatically to
their values usable in WeiDU. In its raw form however, it is possible to query
if a value is a regular expression or a string, and the distinction can be used
for example to switch between `EXACT_MATCH` and `EVALUATE_REGEXP` behaviour of
a mod.



## API
The list of functions defined in this library. It is provided here mainly
as a feature list and very well may be somewhat out of date with the
current implementation - consult the documentation in the code for a particular
function to be sure.

### String utilities
The following variables and functions are located in the `stringutil.tpa` 
include file of weidu actions:

#### Constants
A string with all whitespace characters:	

	OUTER_TEXT_SPRINT WHITESPACE_CHARS ~ %WNL%%TAB%~

A regular expression character class matching whitespace permitted in json:
	
	OUTER_TEXT_SPRINT WHITESPACE_RX ~\([%WHITESPACE_CHARS%]*\)~

A regular expression character class matching all non-whitespace characters:
	
	OUTER_TEXT_SPRINT BLACKSPACE_RX ~\([^%WHITESPACE_CHARS%]*\)~

#### Functions
Escape REGEXP special characters in a string with a '\', so that it can 
be safely used inside a regular expression for verbatim matching. 
 					
	DEFINE_ACTION/PATCH_FUNCTION regexp_escape	
		STR_VAR	str = ~~
		RET regexp


Writes the given string variable at the end of the current patch buffer, 
extending it by the length of the string. Additionally, end of line characters 
can be inserted before or after the string.

	DEFINE_PATCH_FUNCTION append_string
		INT_VAR 
			/** If `1`, a new line character %WNL% is written immediately after %string%. Defaults to `0`. */
			newline = 0
			/** If `1`, a new line character %WNL% is written immediately before and after %string%.
		  	  * The preceding %WNL% is not written if the buffer is empty or already ends with a new line
			  * character %LNL%. */
			fullline = 0
		STR_VAR 
			/** The string to append at the end of the current path buffer. */
			string = ~~
		RET
			/** The size of the buffer when the function returns. */
			srclength


Concatenates elements of an array into a single string in a more efficient 
manner than recursive 'TEXT_SPRINT'. Optional prefix and suffix can be provided 
for wrapping around the elements, as well an optional separator inserted 
between each pair of array elements (the separator is not printed between 
the prefix and the first element or the last element and the suffix).
  
	DEFINE_ACTION/PATCH_FUNCTION concat
		INT_VAR 
			/** If specified, only that many first elements  of the array are used.
			  * Useful when another function returns a non-empty array due to the weidu
			  * limitation of array initialization, while simultaneously specifying zero size.
			*/
			size = 2147483647
		STR_VAR 
			/** Name of the array which values are concatenated together. */
			array = ~~
			/** Optional prefix of the returned string (printed before array elements). */
			prefix = ~~
			/** Optional suffix of the returned string (printed after all array elements). */
			suffix = ~~
			/** Optional separators string inserted between each pair of included array elements. */
			separator = ~~
		RET 
			/** String in the format: '[<prefix>][<item>[<separator><item>]*][<suffix>]. */
			res

Splits the given `%string%` argument into several substrings around separator 
characters, returning all chunks in the `%res%` array. Aside from the input 
`%string%` argument, exactly one of `%separator%`, `%separators%` or `%regexp%`
variable must be passed to the function, depending on how the string should be 
cut. Regardless of the manner in which fragments of `%string%` are interpreted 
as separator substrings, the splitting is done as follows: when a separator 
substring is found, the input string is cut before its start and after its end 
(such that the prefix ends with the last character before the separator and 
the suffix starts with the first character after the separator). All characters
before the separator down to the previous separator occurence or string start 
are treated as a single chunk, while all characters following the spearator 
until the next separator occurence or end of the string are treated as another. 
The substrings are returned in the array in order in which they appear in 
the input string and, optionally, empty strings can be ommited (so two or more 
consecutive separators found immediately one after another do not result
in including an empty string for every such pair).

	DEFINE_ACTION/PATCH_FUNCTION split_string
		INT_VAR 
			/** If non-zero, empty strings are not included in the returned array. */
			nonempty = 0
		STR_VAR
			/** Input string argument. */
			string = ~~
			/** A string literal to be used as a separator. Each exact occurence in the input
			  * string is treated as a separator. */
			separator = ~~
			/** A string which characters are treated as individual separator strings of length 1.
			  * Equivalent to passing regexp = ~[%separators%]~ (but slightly faster). */
			separators = ~~
			/** A regular expression matching the separators in the input string. It is matched
			  * repeatedly against the input string, each time the search starting from the first 
			  * character after the last occurence. The substrings which do not match (in between
			  * each disjoint occurence of the regexp) are retruend as the chunks in the array. */
			regexp = ~~
		RET 
			/** Number of returned chunks after the splitting. If zero (possible when the flag nonempty is set)
			  * the returned array $res will contain a single synthetic element forced by the weidu 
			  * requirement of initializing returned arrays.
			  */
			size
		RET_ARRAY 
			/** The array containing all individual chunks split from the input string. Returned %size%
			  * specifies the number of elements in the array. If zero, the array will contain a single
			  * synthetic element which is not considered part of the 'real' result. */
			res 

Calculates the length of the longest segment of the patched buffer which starts at the given offset and in which all characters match the given regexp 
(or character list). If neither `%chars%` nor `%char_rx%` argument is specified,
the length of the longest whitespace segment is calculated.

	DEFINE_PATCH_FUNCTION buffer_segment_length
		INT_VAR 
			/** Offset in the buffer marking the start of the calculated segment. */
			offset = 0 
			/** If non-zero, reading happens in the reverse direction:
			    the calculated segment must preceed %offset%, rather than follow it. */
			backwards = 0
		STR_VAR
			/** A string treated as a list of individual characters allowed in the segment. */
			chars = ~~
			/** Regular expression which all characters in the segment must match (if specified). */
			char_rx = ~~
		RET
			/** Length of the longest segment starting with %offset% in which all characters 
			  * match %chars%/%char_rx%. */ 
			length
			/** Length of the input buffer, returned here simply for convenience, as the caller will
			  * almost always want to compare the prefix length with the total length of the string. */
			srclength
			/** First character in the buffer after offset which does not match %char_rx%/%chars%
			  * (at offset offset + %length%). If %length% == %srclength% then peek == ~~. */
			peek


Calculates the length of the longest segment in the input string which starts 
at the given offset and in which all characters match the given regexp 
(or character list). If neither `%chars%` nor `%char_rx%` argument is specified,
the length of the longest whitespace segment is calculated.
 
	DEFINE_ACTION/PATCH_FUNCTION string_segment_length
		INT_VAR 
			/** Offset in the %string% marking the start of the calculated segment. */
			offset = 0 
			/** If non-zero, reading happens in the reverse direction:
			  * the calculated segment must preceed %offset%, rather than follow it. */
			backwards = 0
		STR_VAR
			/** The input string on which the function operates. */
			string = ~~
			/** A string treated as a list of individual characters allowed in the segment. */
			chars = ~~
			/** Regular expression which all characters in the segment must match (if specified). */
			char_rx = ~~
		RET
			/** Length of the longest segment starting with %offset% in which all characters 
			  * match %chars%/%char_rx%. */ 
			length
			/** Length of the input buffer, returned here simply for convenience, as the caller will
			  * almost always want to compare the prefix length with the total length of the string. */
			srclength
			/** First character in the buffer after offset which does not match %char_rx%/%chars%
			  * (at offset offset + %length%). If %length% == %srclength% then peek == ~~. */
			peek

Removes all leading whitespace from a given string. 

	DEFINE_ACTION/PATCH_FUNCTION trim_string_front 
		STR_VAR string = ~~
		RET res 

Removes all trailing whitespace from a given string.
	
	DEFINE_ACTION/PATCH_FUNCTION trim_string_back 
		STR_VAR string = ~~
		RET res 

Removes all leading and trailing whitespace from a given string. 
	
	DEFINE_ACTION/PATCH_FUNCTION trim_string 
		STR_VAR string = ~~
		RET res




### Json support
The following constants and functions are provided in the `json.tpa` 
WeiDU include file.

#### Constants
	
	/** The character used to separate individual keys/indexing in complex properties forming
	  * paths to deeply nested elements. See get_json/set_json.
	  */
	OUTER_TEXT_SPRINT JSON_PROPERTY_SEPARATOR ~.~


	/** Regexp matching any sequence of '\' terminated by a character other than '"' and '\', 
	  * or an odd sequence of '\' terminated by '"'. */
	OUTER_TEXT_SPRINT JSON_STRING_ATOM_RX ~\(\\*[^\"]\|\([^\]\\\(\\\\\)*"\)\)~

	/** Any string surrounded by a pair of '"' characters, in which all '"' are escaped with a '\'.*/
	OUTER_TEXT_SPRINT JSON_STRING_RX ~"\(\(\\\(\\\\\)*"\)?\(%JSON_STRING_ATOM_RX%*\)\(\(\\\\\)*\)\)"~ 
	/** A regular expression string in the format of [rR]"json string", where `"json_string"` is
	  * a valid json string. */
	OUTER_TEXT_SPRINT JSON_REGEXP_RX ~[rR]%JSON_STRING_RX%~

	OUTER_TEXT_SPRINT JSON_NULL ~null~

	OUTER_TEXT_SPRINT JSON_TRUE ~true~
	OUTER_TEXT_SPRINT JSON_FALSE ~false~

	OUTER_SET MAX_INT = BIT31 - 1 //2147483647


#### Writing to the patch buffer
The following functions write values in the json format at the given offset 
in the implicit patch buffer.

	/** Inserts the given boolean value in the json format (true|false) into the currently patched
	  * buffer at the given offset, pushing back any existing data. The value can be given either
	  * as an integer %boolean% and interpreted as by WeiDU, or as an (unquoted) string %json%: 
	  * 'true' or 'false'. The latter parameter, if not empty, takes precedence.
	  * If the %offset% parameter is not specified or is negative, the value will be appended to the buffer. 
	  * Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_boolean
		INT_VAR 
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
			/** Integer value to write as json; 0 results in writing 'false', any other value in 'true' */
			boolean = 0
		STR_VAR
			/** Boolean to write in the string format: either 'true' or 'false'. 
			  * If empty, the %boolean% parameter will be used instead. */
			json = ~~
		RET 
			/** Offset in the patched buffer immediately after the written value. */
			offset


	/** Inserts the given string into the currently patched buffer at the given offset, 
	  * pushing back any existing data. The value can be given either as an ordinary string %string%,
	  * or as an already quoted value %json% (surrounded in '"' with any '"' inside escaped with '\').
	  * The latter parameter, if not empty, takes precedence.
	  * If the %offset% parameter is not specified or is negative, the value will be appended to the buffer. 
	  * Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_string
		INT_VAR 
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
		STR_VAR
			/** String value to format as a json string and write into the buffer. */
			string = ~~
			/** A string to write in valid json format: quoted with '"', with any '"' and '\' preceded by a'\'. */
			json = ~~
			RET 
			/** Offset in the patched buffer immediately after the written value. */
			offset

	/** Inserts the given regular expression into the currently patched buffer at the given offset, 
	  * pushing back any existing data. The value can be given either as an ordinary string %regexp%,
	  * or as an already quoted value %json% (in the `r"..."` format).
	  * The latter parameter, if not empty, takes precedence.
	  * If the %offset% parameter is not specified or is negative, the value will be appended 
	  * to the buffer. Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_regexp
		INT_VAR
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
		STR_VAR
			/** Regular expression as a normal string to format as a bhaalsson expression. 
			  * Checked if the %json% argument is empty. */
			regexp = ~~
			/** Regular expression in the bhaalsson format to write in the buffer. */
			json = ~~
		RET
			/** The offset in the buffer immediately after the last written character. */
			offset

	/** Inserts the given translation string reference into the currently patched buffer 
	  * at the given offset, pushing back any existing data. The value can be given either 
	  * as a numeric key %key%, or a ready literal %json% in the form of `@<number>`.
	  * The latter parameter, if not empty, takes precedence. The translation reference is always
	  * written as itself, without resolving it to string. However, if %validate% parameter is
	  * set to `1` (default), it is resolved before writing solely to ensure that it points 
	  * to an existing translation string.
	  * If the %offset% parameter is not specified or is negative, the value will be appended 
	  * to the buffer. Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_translation
		INT_VAR 
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
			/** If non-zero (default), the reference is resolved before writing to ensure its validity. */
			validate = 1
		STR_VAR
			/** A string consisting of a positive number of digits forming the translation string key. 
			  * Used only if the %json% parameter is empty. */
			key = ~~
			/** A valid translation string reference literal. If empty/omitted the %key% parameter will be used. */
			json = ~~
	

	/** Inserts the given value into the currently patched buffer at the given offset, 
	  * pushing back any existing data. The value, given as a string parameter %value%, is
	  * written as a json string, unless it is a valid integer as returned by WeiDU's IS_AN_INT function,
	  * or a translation string reference, in which case it is written as-is.
	  * If the %offset% parameter is not specified or is negative, the value will be appended to the buffer. 
	  * Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_atom
		INT_VAR 
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
		STR_VAR
			/** The value to convert to json and write into the buffer. */
			value = ~~
		RET 
			/** Offset in the patched buffer immediately after the written value. */
			offset


	/**  Writes the contents of a given array at the given offset in the currently patched buffer
	  *  as a json array. If the %rawarray% parameter is not empty, it assumed to be the name
	  *  of an existing weidu array construct, which elements are all already valid json values.
	  *  Otherwise, the %array% parameter is assumed to be the name of a WeiDU array which contents
	  *  must yet be formatted as json values. If an element can be parsed as a number, it will be
	  *  written as such; otherwise it will be formatted as a json string.
	  *  If the %offset% parameter is not specified or is negative, the value will be appended to the buffer. 
	  *  Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_array 
		INT_VAR
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
			/** If the %size% parameter is specified, only that many first elements of the array will be written. */
			size = 2147483647
		STR_VAR
			/** Name of an array containing valid json values. */
			rawarray = ~~
			/** Name of an array containing values to be formatted as json; checked only 
			  * if the %rawarray% parameter is an empty string. */
			array = ~~
		RET
			/** Offset in the patched buffer immediately after the written value. */
			offset

	/**  Writes the contents of a given array at the given offset in the currently patched buffer
	  *  as a json object. The keys in the array are used as field names for their associated values.
	  *  If the %rawfields% parameter is not empty, it assumed to be the name of an existing weidu array, 
	  *  which keys are valid (quoted) json strings and elements are all already valid json values.
	  *  Otherwise, if the %fields% parameter is not empty, it assumed to be the name of an existing array,
	  *  which keys are arbitrary string values and need quoting before writing, but values are already
	  *  formatted json. Lastly, the %dict% parameter is assumed to be the name of a WeiDU array which both
	  *  keys and values need converting to json before writing. Keys are always formatted as strings; 
	  *  if a value can be parsed as a number, it will be written as such; otherwise it will be quoted as astring.
	  *  If the %offset% parameter is not specified or is negative, the value will be appended to the buffer. 
	  *  Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json_object
		INT_VAR
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
			/** If the %size% parameter is specified, only that many first elements of the array will be written. */
			size = 2147483647
		STR_VAR
			/** Name of an array which keys are quoted strings and values are valid json. */
			rawfields = ~~
			/** Name of an array which keys are arbitrary strings and values are valid json. 
			  * Checked only if the %rawfields% parameter is an empty string. */
			fields = ~~		
			/** Name of an array which both keys and values need formatting as json. 
			  * Checked only if both the %rawfields% and %fields% parameters are empty strings. */
			dict = ~~		
		RET
			/** Offset in the patched buffer immediately after the written value. */
			offset

	/**  Writes given json data at the specified offset in the currently patched buffer.
	  *  The argument must be in valid json format.
	  *  If the %offset% parameter is not specified or is negative, the value will be appended to the buffer. 
	  *  Offset larger than the length of the buffer will result in an error.
	  */
	DEFINE_PATCH_FUNCTION write_json
		INT_VAR 
			/** Offset in the buffer after which the value will be written. */
			offset = 0 - 1
		STR_VAR
			/** Formatted json data to write. */
			json = ~~
		RET 
			/** Offset in the patched buffer immediately after the written value. */
			offset


#### Json formatting
The following functions take as argument values in the normal, weidu-friendly
form and convert them to strings in the json format.


	/** Returns json boolean representation ('true'/'false') based on whether the given int is non-zero. */
	DEFINE_ACTION/PATCH_FUNCTION json_boolean
		INT_VAR boolean = 0
		RET res

	/** Returns json number representation of an integer. This is most basic string formatting. */	
	DEFINE_ACTION/PATCH_FUNCTION json_number
		INT_VAR number = 0
		RET res

	/** Formats the given string variable %string% for inclusion in json data. All '"' and '\'	
	  * characters are preceeded by a '\' and the whole string is surrounded in a pair of '"'.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_string
		STR_VAR string = ~~
		RET res

	/** Formats the given value as json. If it is a valid integer, it is left intact.
	  * If it is a valid translation string reference, it is resolved to the associated string
	  * value for the appropriate languague. Otherwise it is quoted as a json string. 
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_atom
		STR_VAR value = ~~
		RET res 
		
		
	/** Formats the given weidu array $%array% or $%rawarray% for inclusion in json data. Elements of 
	  * the array must be valid json strings themselves, which are concatenated, separated by
	  * ', ' and surrounded by a matching pair of brackets '[' and ']'.
	  * Use the %rawarray% argument for arrays which elements already are json values (including composites) 
	  * themselves and %array% for arrays of weidu strings (and ints) which need converting to json before
	  * formatting.
	  */	
	DEFINE_ACTION/PATCH_FUNCTION json_array
		INT_VAR 
			/** If specified, only that many first elements of the array are included.
			  * Useful when other functions return non-empty arrays with explicitly specified
			  * zero size due to the weidu limitation on array initialization.
			  */
			size = 2147483647
		STR_VAR 
			/** Name of an array construct containing the json elements to include. */
			rawarray = ~~
			/** Name of an array construct containing the values to include. 
			  * All elements will be converted to json as per json_atom. */
			array = ~~
		RET 
			/** A string containing a json array with the given elements. */	
			res

	/** Formats an associative array as a json object. The keys are names of the fields of
	  * the object while their associated values the field values. The exacTheir
	  * handling depends on which of the input parameters %rawfields%, %fields% and %dict% is specified. 
	  * Any parameter, when present, must contain a name of a json weidu construct. The keys of %rawfields%
	  * must be valid json strings ready to include verbatim in the result; the keys of %fields% and %dict%
	  * are treated as string values and formatted as json strings as per json_string before writing.
	  * The values of %rawfields% and %fields% must be valid json values (including composites), while
	  * the values of %dict% are treated as weidu values (strings or ints) and formatted accordingly:
	  * if an element is a valid integer, it is written as a number. Otherwise it is formatted as a json
	  * string value.
	  */  
	DEFINE_ACTION/PATCH_FUNCTION json_object
		INT_VAR 
			/** If specified, only that many first fields from the array are included.
			  * Useful when another function returns a non-empty array with explicitly 
			  * specified zero length due to the weidu limitation on array initialization.
			  */
			size = 2147483647
		STR_VAR 
			/** Name of a weidu array containing key-value pairs matching field names (as valid json strings)
			  * with their json values. */
			rawfields = ~~
			/** Name of a weidu array containing key-value pairs matching field names (as weidu strings)
			  * with their json values. */
			fields = ~~
			/** Name of a weidu array containing key-value pairs matching fields names (as weidu strings)
			  * with their weidu values. */
			dict = ~~
		RET 
			/** Returned string representation of the formatted json object. */
			res	


#### Reading json from the buffer
The following patch functions start reading contents of the patch buffer
at the given offset and consume the whole next json expression, converting
it to a format usable in weidu.

	/** Reads the json boolean value following the given offset in the current patch buffer.
	  * Any leading whitespace is ignored. If the following content is not a 'true' or 'false' string,
	  * or the offset is larger than buffer length, an error is raised.
	  */
	DEFINE_PATCH_FUNCTION read_json_boolean
		INT_VAR	
			/** Offset from which reading starts. If omitted, it defaults to zero. If negative,
			  * the value of %cursor% variable is used instead.
			  */
			offset = 0
		RET 
			/** Offset in the buffer immediately after the read data. */
			offset 
			/** Read boolean value as an integer: 0 for false, 1 for true. */
			res

	/** Reads the json number following the given offset in the current patch buffer.
	  * Any leading whitespace is ignored. If the following content is not a valid integer,
	  * or the offset is larger than buffer length, an error is raised.
	  */ 
	DEFINE_PATCH_FUNCTION read_json_number
		INT_VAR	
			/** Offset from which reading starts. If omitted, it defaults to zero. If negative,
			  * the value of %cursor% variable is used instead.
			  */
			offset = 0
		RET 
			/** Offset in the buffer immediately after the read data. */
			offset 
			/** Read integer value. */
			res

	/** Reads the json string following the given offset in the current patch buffer.
	  * Any leading whitespace is ignored. If the following content is not a valid string,
	  * or the offset is larger than buffer length, an error is raised.
	  * The string is returned exactly as read, without unquoting.
	  */ 
	DEFINE_PATCH_FUNCTION read_raw_json_string
		INT_VAR	
			/** Offset from which reading starts. If omitted, it defaults to zero. If negative,
			  * the value of %cursor% variable is used instead.
			  */
			offset = 0
		RET 
			/** Offset in the buffer immediately after the read data. */
			offset 
			/** Read string in the json format without any conversion. */
			res

	/** Reads the json string following the given offset in the current patch buffer.
	  * Any leading whitespace is ignored. If the following content is not a valid string,
	  * or the offset is larger than buffer length, an error is raised.
	  * The string is converted to a standard weidu string by unquoting and unescaping.
	  */ 
	DEFINE_PATCH_FUNCTION read_json_string
		INT_VAR	
			/** Offset from which reading starts. If omitted, it defaults to zero. If negative,
			  * the value of %cursor% variable is used instead.
			  */
			offset = 0
		RET 
			/** Offset in the buffer immediately after the read data. */
			offset 
		/** Read string after conversion from json. */
			res

	/** Reads a regular expression string from the input. The regular expression must be a
	  *	string in '"' quotes, preceded directly by a 'r' or 'R' character. The value is
	  * returned exactly as it appears in the buffer after %offset%, only any leading whitespace
	  * is ignored.
	  */
	DEFINE_PATCH_FUNCTION read_raw_json_regexp
		INT_VAR
			/** The offset in the patch buffer where the reading starts. First non-white characters
			  * following %offset% must be the start of a regular expression: 'r' or 'R'. */
			offset = 0
		RET
			/** The offset immediately after the closing '"' of the read regular expression. */
			offset
			/** The unquoted value of the regular expression. */
			res

	/** Reads a regular expression string from the input. The regular expression must be a
	  * string in '"' quotes, preceded directly by a 'r' or 'R' character. The result is
	  * otherwise the same as with `read_json_string`, with the function returning the 
	  * value of the unquoted string. Wherever the function `read_json_atom` (and `read_json`)
	  * encounters a regular expression in this format, it is parsed as a regular string.
	  * This extension of the json format is simply used to mark a string as a regular expression, 
	  * to distinguish between `EXACT_MATCH` and `EVALUATE_REGEXP` behaviour.
	  */
	DEFINE_PATCH_FUNCTION read_json_regexp
		INT_VAR
			/** The offset in the patch buffer where the reading starts. First non-white characters
			  * following %offset% must be the start of a regular expression: 'r' or 'R'. */
			offset = 0
		RET
			/** The offset immediately after the closing '"' of the read regular expression. */
			offset
			/** The unquoted value of the regular expression. */
		res

	/** Reads a literal key for a json translation string from the input at the given offset.
	  * The format is the same as used by weidu for translation reference literals: @<number>.
	  * Any whitespace between the specified offset and the '@' character is skipped.
	  */
	DEFINE_PATCH_FUNCTION read_raw_json_translation
		INT_VAR 
			/** The offset in the patch buffer where the reading starts. */
			offset = 0
		RET 
			/** The offset in the patch buffer immediately after the read translation literal. */
			offset
			/** The tra literal as it appears in input and would be used in tpa: @<number>. */
			res

	/** Reads a literal key for a json translation string from the input at the given offset
	  * and immediately resolves it to a string from the appropriate tra file as per (AT var).
	  * The format is the same as used by weidu for translation reference literals: @<number>.
	  * Any whitespace between the specified offset and the '@' character is skipped.
	  */
	DEFINE_PATCH_FUNCTION read_json_translation
		INT_VAR 
			/** The offset in the patch buffer where the reading starts. */
			offset = 0
		RET 
			/** The offset in the patch buffer immediately after the read translation literal. */
			offset
			/** The resolves translation string from the most appropriate language file. */
			res



	/** Reads the json value following the given offset in the current patch buffer.
	  * Any leading whitespace is ignored. The value must be either a boolean, integer or a string;
	  * otherwise an error is raised. If the value is a boolean, it is returned as either zero or one.
	  * Integral numbers are returned as integers, while strings are unquoted and unescaped to their
	  * 'normal' selves. Translation string references are resolved and the actual translation string
	  * is returned. Additionally, a string value may be preceeded by a 'r' or 'R' character
	  * marking it as a regular expression. This function however does not distinguish between
	  * a regular string and a regexp, simply ignoring the 'r'/'R' character before a string value.
	  * This function is used internally by `read_json` and wherever an atomict json value is expected
	  * (`read_json_object_fields`, `read_json_array`, etc.).
	  */ 
	DEFINE_PATCH_FUNCTION read_json_atom
		INT_VAR	
			/** Offset from which reading starts. If omitted, it defaults to zero. If negative,
			  * the value of %cursor% variable is used instead.
			  */
			offset = 0
		RET 
			/** Offset in the buffer immediately after the read data. */
			offset 
			/** Read value after conversion from json. */
			res

	/** Reads a json array from the patched buffer and returns it as a WeiDU array which elements
	  * are intact json values read from the buffer.
	  */  
	DEFINE_PATCH_FUNCTION read_raw_json_array
		INT_VAR 
			/** The index at which the reading starts. The first non-white character after %offset%
			  * must be the array opening bracket '['. */
			offset = 0 
		RET 
			/** The position in the buffer immediately after the closing bracket ']' of the read array. */
			offset 
			/** Number of elements in the read array. If zero, the returned array will contain a synthetic
			  * element which was not part of the input. */
			size
		RET_ARRAY 
			/** An array (indexed by natural numbers starting with zero) containing all json elements
			  * of the read array. The elements are stored as unmodified json strings. If the input array
			  * is empty, %res% will contain a single synthetic element mandated by WeiDU. 
			  * Always check %size% before accessing the array. */
			res

	/** Reads a json array from the patched buffer and returns it as a WeiDU array containing
	  * converted json elements of the input array. All string values become unquoted and unescaped,
	  * boolean values are converted to integers '0' and '1'. If the input array contains an element
	  * other than integers, strings and booleans, an error is raised.
	  */  	
	DEFINE_PATCH_FUNCTION read_json_array
		INT_VAR 
			/** The index at which the reading starts. The first non-white character after %offset%
			  * must be the array opening bracket '['. */
			offset = 0
		RET 
			/** The position in the buffer immediately after the closing bracket ']' of the read array. */
			offset 
			/** Number of elements in the read array. If zero, the returned array will contain a synthetic
			  * element which was not part of the input. */
			size
		RET_ARRAY 
			/** An array (indexed by natural numbers starting with zero) containing all elements
			  * of the read array. The elements are converted from the json format to standard
			  * WeiDU values before storing. If the input array is empty, %res% will contain 
			  * a single synthetic element mandated by WeiDU. Always check %size% before accessing the array. 
			  */
			res


	/** Reads the element at the specified index of a json array in the patch buffer. 
	  * If the input array is shorter than required, the provided default value is returned instead.
	  */
	DEFINE_PATCH_FUNCTION read_json_array_element
		INT_VAR 
			/** The offset in the patch buffer before the input array. The first following 
			  * non-white character must be the opening bracket '['. */
			offset = 0
			/** The index of the requested element, starting with zero. */
			idx = 0
		STR_VAR
			/** The value to return if the input array's length is lesser than %idx%. Defaults to ~~. */
			default = ~~
		RET	
			/** The %idx%-th element of the input array as unconverted json. */
			res

	/** Reads a key-value pair of a json object from the patch buffer. Expects to find
	  * data in the format of '"key":<json_value>' with optional whitespace around the two values. 
	  * If read data does not conform to that format an error is raised.
	  */
	DEFINE_PATCH_FUNCTION read_raw_json_object_field 
		INT_VAR 
			/** Offset in the buffer immediately before the json string serving as the key value, 
			  * Following whitespace is ignored. */
			offset = 0
		RET 
			/** The offset in the patch buffer immediately after the value of the read pair. */
			offset
			/** The json field (quoted in '"') being the key/field name of the read entry. */
			field 
			/** The json element being the value of the read entry. */
			value

	/** Reads a json object from the patch buffer in the raw (unconverted) json format.
	  * The fields of the read object are returned as a WeiDU array which keys are json strings
	  *	and values their associated json elements.
	  */
	DEFINE_PATCH_FUNCTION read_raw_json_object_fields
		INT_VAR 
			/** The offset in the patch buffer before the input array. The first following 
			  * non-white character must be the opening bracket '{'. */
			offset = 0
		RET 
			/** The offset in the patch buffer immediately after the closing bracket '}' of the read object. */
			offset 
			/** The number of fields (key-value entries) in the read json object. */
			size
		RET_ARRAY 
			/** An array which keys are (quoted) json strings and values their associated 
			  * json elements of any type. If the object is empty, the array will contain
			  * an artificial entry - check %size% before accessing. */
			res

	/** Reads a json object from the patch buffer into a WeiDU array. The keys of the returned array
	  * are converted (unquoted) strings given for field names. Their values are
	  * unconverted json elements associated with the keys in the read object. 
	  */
	DEFINE_PATCH_FUNCTION read_json_object_fields
		INT_VAR 
			/** The offset in the patch buffer before the input array. The first following 
			  * non-white character must be the opening bracket '{'. */
			offset = 0
		RET 
			/** The offset in the patch buffer immediately after the closing bracket '}' of the read object. */
			offset 
			/** The number of fields (key-value entries) in the read json object. */
			size
		RET_ARRAY 
			/** An array which keys are (unquoted) strings being the key names and values 
			  * their associated json elements of any type. If the object is empty, 
			  * the array will contain an artificial entry - check %size% before accessing. */
			res

	/** Reads a json object from the patch buffer into a WeiDU array. Both the keys and values
	  * are converted from the json format to standard string variables: the keys are the names
	  * of the fields. Their values are converted based on their type: strings become unquoted,
	  * integer numbers are printed in the decimal format and boolean values are stored as either 
	  * '0' or '1'. 
	  */
	DEFINE_PATCH_FUNCTION read_json_as_dict
		INT_VAR 
			/** The offset in the patch buffer before the input array. The first following 
			  * non-white character must be the opening bracket '{'. */
			offset = 0
		RET 
			/** The offset in the patch buffer immediately after the closing bracket '}' of the read object. */
			offset 
			/** The number of fields (key-value entries) in the read json object. */
			size
		RET_ARRAY 
			/** An array which keys are (unquoted) strings being the key names and values 
			  * are converted from json. If the object is empty, 
			  * the array will contain an artificial entry - check %size% before accessing. */
			res

	/** Reads the json element following the given offset in the patch buffer.
	  * The json value is returned as a string exactly equal to the read buffer fragment.
	  */
	DEFINE_PATCH_FUNCTION read_json	
		INT_VAR 
			/** The offset before the element to read. The first following non-white character
			  * must be the first character of the value to read. */
			offset = 0
		RET 
			/** The offset in the buffer immediately after the read element. */
			offset 
			/** Read json element. */
			json


#### Json validation
The following functions verify if a given string contains valid json data of an
expected type.

	/** Sets the %is_null% return variable to zero if the passed %json% argument is not a valid json `null`
	  * (does not equal 'null'), or to a non-zero value otherwise.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_null
		STR_VAR json = ~~
		RET is_null

	/** Sets the %is_boolean% return variable to zero if the passed %json% argument is not a valid 
	  * json boolean value ('true' or 'false'), or to a non-zero value otherwise.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_boolean
		STR_VAR json = ~~
		RET is_boolean

	/** Sets the %is_int% return variable to zero if tne passed %json% argument is not a valid 
	  * json number (IS_AN_INT is not true for the trimmed string), or to a non-zero value otherwise.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_number
		STR_VAR json = ~~
		RET 
			is_int is_number


	/** Sets the %is_string% return variable to zero if the passed %json% argument is not a valid json string,
	  * or to a non-zero value otherwise. The input %json% is trimmed of whitespace before validation.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_string
		STR_VAR json = ~~
		RET is_string

	/** Sets the %is_regexp% return variable to zero if the passed %json% argument is not a valid
	  * regular expression, or to one otherwise. A regular expression is a json string preceded
	  * immediately by a 'r' or 'R' character. 
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_regexp
		STR_VAR json = ~~
		RET is_regexp


	/** Sets the %is_tra% return variable to zero if the passed %json% argument is not a valid
	  * translation string reference, or one otherwise. The translation reference is not resolved
	  * and the existance of its target string is not checked, only the format is verified for
	  * correctness. Any leading or trailing whitespace in the string is ignored.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_translation
		STR_VAR json = ~~
		RET is_tra



	/** Sets the %is_atom% return variable to non-zero iff %json% is a valid json string, number, boolean
	  * or null value. A string value may be additionally preceded by an ignored 'r'/'R' character,
	  * marking it as a regular expression. Leading and trailing whitespace is ignored for the purpose 
	  * of this check.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_atom
		STR_VAR json = ~~
		RET is_atom

	/** Sets the %is_array% return variable to zero if the passed %json% argument is not a valid json array,
	  * or to a non-zero value otherwise. Any leading or trailing whitespace is ignored.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_array
		STR_VAR json = ~~
		RET is_array

	/** Sets the %is_object% return variable to zero if the passed %json% argument is not a valid json object,
	  * or to a non-zero value otherwise. Any leading or trailing whitespace is ignored.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_json_object
		STR_VAR json = ~~
		RET is_object

	/** Sets the %is_object% return variable to zero if the passed %json% argument is not 
	  * a correctly formatted Json, or to a non-zero value otherwise. Any leading or trailing 
	  * whitespace is ignored.
	  */
	DEFINE_ACTION/PATCH_FUNCTION is_valid_json
		STR_VAR json = ~~
		RET is_json

	/** Fails if %json% is not a valid Json, no-op otherwise. */
	DEFINE_ACTION/PATCH_FUNCTION validate_json
		STR_VAR 
			json = ~~
			logprefix = ~~





#### Json parsing
The following functions take a %json% string with a valid json expression and
convert them to a more weidu-friendly form. They have behaviour mostly 
consistent with the 'reading' functions, so consult them for more details.


	/** Converts a json boolean (one of 'true'/'false' strings) into a weidu integer. */	
	DEFINE_ACTION/PATCH_FUNCTION json_boolean_value
		STR_VAR 
			/** Input json representation of the boolean. */
			json = ~~
		RET 
			/** 1 or 0, depending on the read value. */
			res 

	/** Converts a json boolean (one of 'true'/'false' strings) into a weidu integer. 
	  * Any leading whitespace in the input string is ignored.
	  */	
	DEFINE_ACTION/PATCH_FUNCTION json_to_boolean
		STR_VAR 
			/** Input json representation of the boolean. */
			json = ~~
		RET 
			/** 1 or 0, depending on the read value. */
			res 

	/** Converts a json number into a weidu integer variable using the autoconversion from string. 
	  * Input json must be a valid integer in a format accepted by weidu. */
	DEFINE_ACTION/PATCH_FUNCTION json_number_value
		STR_VAR 
			/** A string with the value of the returned number. */
			json = ~~
		RET 
			/** Parsed integer value of %json%. */
			res

	/** Converts a json number into a weidu integer variable. The number can be in any
	  * valid json format (octal, hex, decimal, positive or negative). 
	  * Any leading whitespace is ignored. If %json% is not a valid weidu integer
	  * an error is raised.
	  */
	DEFINE_PATCH_FUNCTION json_to_int
		STR_VAR 
			/** A string with the value of the returned number. */
			json = ~~
		RET 
			/** Parsed integer value of %json%. */
			res

	/** Converts a raw json string, quoted in a pair of '"', to a string value by
	  * unquoting it and replacing any escape sequences '\"' and '\\' by '"' and '\'.
	  * If %json% is not a valid string,
	  * an error is raised.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_string_value 
		STR_VAR json = ~~
		RET res 

	/** Converts a raw json string, quoted in a pair of '"', to a string value by
	  * unquoting it and replacing any escape sequences '\"' and '\\' by '"' and '\'.
	  * Any leading whitespace is ignored. If %json% is not a valid string,
	  * an error is raised.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_to_string
		STR_VAR json = ~~
		RET res

	/** Converts a regular expression string, given as a json string preceded immediately
	  * by a quoted in a pair of '"', to a string value by
	  * unquoting it and replacing any escape sequences '\"' and '\\' by '"' and '\'.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_regexp_value
		STR_VAR json = ~~
		RET res

	/** Converts a regular expression string, given as a json string preceded immediately
	  * by a quoted in a pair of '"', to a string value by
	  * unquoting it and replacing any escape sequences '\"' and '\\' by '"' and '\'.
	  * Any leading whitespace is ignored
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_to_regexp
		STR_VAR json = ~~
		RET res

	/** Resolve the given a weidu/bhaalsson translation string reference literal to the
	  * associated string for the chosen language. 
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_translation_value
		STR_VAR json = ~~
		RET res


	/** Converts a json atomic value - a boolean, number, string, translation reference 
	  * or regexp - into a weidu variable in the manner defined by the `read_json_atom` function. 
	  * Strings and regular expressions are unquoted in the process, translation string 
	  * references resolved, while boolean values are converted to `0` and `1`
	  * based on their value.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_value
		STR_VAR json = ~~
		RET res 

	/** Reads a json array from the %json% string, setting the elements of the returned
	  * weidu array %res% to its contents. The array is indexed by consecutive integers
	  * starting with `0` and its values are the raw json expressions exactly as they 
	  * appear in the input. If the input array is empty, returned array will contain
	  * an artificial element to prevent an 'uninitialized array' error - check the %size%
	  * variable, which is set to the number of elements in the array, before accessing the array.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_to_raw_array
		STR_VAR json = ~~
		RET size
		RET_ARRAY res 

	/** Reads a json array from the %json% string, setting the elements of the returned
	  * weidu array %res% to the converted json values. The array is indexed by consecutive 
	  * integers starting with `0` and its values are the atomic json values as found
	  * in the input and converted with `read_json_atom`. Any element in the input which
	  * cannot be converted (being an array or an object) results in an error.
	  * If the input array is empty, returned array will contain
	  * an artificial element to prevent an 'uninitialized array' error - check the %size%
	  * variable, which is set to the number of elements in the array, before accessing the array.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_to_array
		STR_VAR json = ~~
		RET size
		RET_ARRAY res

	/** Reads a json object from the %json% string, setting the elements of the returned
	  * weidu array %res% to its converted fields. The array is indexed by raw (quoted) 
	  * json strings used as the field names and their values are the raw json expressions 
	  * associated with them in the input json. If the input object is empty, returned array 
	  * will contain an artificial entry to prevent an 'uninitialized array' error - check the %size%
	  * variable, which is set to the number of fields in the object, before accessing the array.
	  */
	DEFINE_ACTION/PATCH_FUNCTION raw_json_object_fields
		STR_VAR json = ~~
		RET size
		RET_ARRAY res 

	/** Reads a json object from the %json% string, setting the elements of the returned
	  * weidu array %res% to its converted fields. The array is indexed by field names
	  * (unquoted json string values) and their values are the raw json expressions 
	  * associated with them in the input json. If the input object is empty, returned array 
	  * will contain an artificial entry to prevent an 'uninitialized array' error - check the %size%
	  * variable, which is set to the number of fields in the object, before accessing the array.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_object_fields
		STR_VAR json = ~~
		RET size
		RET_ARRAY res

	/** Reads a json object from the %json% string, setting the elements of the returned
	  * weidu array %res% to its converted fields. The array is indexed by field names
	  * (unquoted json string values) and their values are the values of their associated
	  * json expressions, converted from the json format as per `read_json_atom`.
	  * If the input object is empty, returned array 
	  * will contain an artificial entry to prevent an 'uninitialized array' error - check the %size%
	  * variable, which is set to the number of fields in the object, before accessing the array.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_to_dict
		STR_VAR json = ~~
		RET size
		RET_ARRAY res


#### Json accessors
The following functions extract a subexpression value from json data 
in a string.

	/** Returns the size (number of elements) of the given json array. */
	DEFINE_ACTION/PATCH_FUNCTION json_array_size
		STR_VAR json = ~~
		RET size

	/** Returns the element at the specified index in the array. The element is returned as json. */	
	DEFINE_ACTION/PATCH_FUNCTION json_array_element
		INT_VAR 
			/** Index of the required element. */
			idx = 0
		STR_VAR 
			/** Input array in the json format. */ 
			json = ~~ 
			/** Default value returned if index %idx% is out of range. */
			default = ~~
		RET 
			/** Required element as json or %default% if no such element exists. */
			res 

	/** Returns the element at the specified index in the array. 
	  * The json element is converted to a weidu variable before returning:
	  *  - strings are unescaped and without the extra '"' chars;
	  *  - numbers are returned verbatim (formatted as strings);
	  *  - boolean values are converted to ~0~ or ~1~;
	  *  - other elements can't be converted and result in a failure.
	. */	
	DEFINE_ACTION/PATCH_FUNCTION json_array_at
		INT_VAR 
			/** Index of the required element. */
			idx = 0
		STR_VAR 
			/** Input array in the json format. */ 
			json = ~~ 
		RET 
			/** Required element as json or %default% if no such element exists. */
			res 


	/**	Retrieves the raw json expression associated with the given field of a json object.
	  * The field can be given either as a quoted string (higher precedence) or a unquoted 
	  * string value. If the object does not have a field of the specified name, the default
	  * value is returned instead. If the passed %json% expression is not a valid json object,
	  * component installation will fail.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_raw_field	
		STR_VAR
			/** The input json object. */
			json = ~~
			/** A string with unquoted name of the field to retrieve, checked if %rawfield% is empty. */
			field = ~~
			/** A json string with the quoted name of the field to retrieve. */
			rawfield = ~~
			/** Any string (not necessarily a valid json expression) to return if the object
			  * does not declare the field of the specified name. Defaults to an empty string. */
			default = ~~
		RET	
			/** The json expression associated with the specified field or %default% if no such field exists. */
			res

	/**	Retrieves the converted value associated with the given field of a json object.
	  * If the passed %json% expression is not a valid json object or the object does not
	  * contain a field of this name, component installation will fail.
	  */
	DEFINE_ACTION/PATCH_FUNCTION json_field	
		STR_VAR
			/** The input json object. */
			json = ~~
			/** A string with unquoted name of the field to retrieve, checked if %rawfield% is empty. */
			field = ~~
		RET	
			/** The value associated with the specified field converted from json as per 
			  * the `json_value` function. */
			res


	/** Returns a value of a json element of the input json string, defined by its 'path'
	  * from the root element. The %property% variable must be a string containing and
	  * uninterrupted sequence of chunks in one of the formats:
	  *  - [%n%] will 'select' the (n+1)-th element of the array being the current 'top' element (zero-based indexing).
	  *    If the top element is not an array or the array does not contain that many elements,
	  *    The %property% will not match any element.
	  *  - .%field% will 'select' the field of the given name (an unquoted string) of the top
	  *    json object. The leading dot of %property% selecting a field from the top object can
	  *    be ommited. If the top element is not a json object, or the json object does not contain
	  *    a field of the given name, the %property% will not match any element.
	  * An empty property matches the top element itself. 
	  * The returned %res% value of the property is an exact, unprocessed substring of the input %json% 
	  * located by recursively following the individual chunks of the %property%, narrowing the 
	  * result in each step. If the element defined by the %property% does not exist, an empty
	  * string is returned. Note that this definition becomes ambigous if a field name contains
	  * dots or '['/']' brackets. 
	  *
	  * For example, a property ~proficiencies[2].name~ will match a json object with a field 
	  * "proficiencies", which value must be an array, and return the third (zero-indexed) element
	  * of the array; afterwards it tries to interpret the element as a json object and find the
	  * value of its field with the name "name". The result could be for example %"long sword"% 
	  * (mind the quotes). If any of the steps fails, %res% will be an empty string.
	  * This function will always have preference for matching elements on a higher level. 
	  * In the above example, should the top level object contain a field %"abilities[2].name"%
	  * it would be returned instead of the nested element under the %"abilities"% field. Likewise,
	  * a top level field %"abilities[2]"% which value is an object, would return the %"name"% field
	  * of the latter, if present. Finding a partial match - like the %"abilities[0]"% field 
	  * from the last example, if its value does not have a %"name"% field - does not stop further
	  * search, so the original "abilities" [0] "name" sequence would still be considered.
	  * Another ambiguity comes from field names starting with a dot. These should be avoided 
	  * if possible, but this function will always try first to interpret the '.' character as
	  * a separator preceding the field name, but not included in it. So, if the top-level
	  * object has both a "." and ".." fields, a property of ~..~ would match both, with a preference
	  * for the former.
	  */
	DEFINE_ACTION/PATCH_FUNCTION get_json
		STR_VAR
			/** The input (top-level) json expression. */
			json = ~~
			/** A string defining the path to the returned element as a sequence of field names
				  * and indexing expressions separated by the '.' character. */
			property = ~~
		RET
			/** The exact, 'raw' json expression matching the %property% or an empty string if
			  * the %property% does not match any element. */
			res

	/** Verifies whether the input json contains an element which path matches the given
	  * %property% string. The path must be in the same format as with the `get_json` function.
	  * It can be either:
	  *  - an empty string, matching the top-level element (whole input);
	  *  - another property, followed by ~[%n%]~, matching the (n+1)-th element of a json array matched
	  *    by the prefix property;
	  *  - another property, followed by ~.%name%~, matching the value of the "name" field of 
	  *    a json object matched by the prefix property;
	  */	
	DEFINE_ACTION/PATCH_FUNCTION json_has_property
		STR_VAR
			/** Input json expression. */
			json = ~~
			/** A complex json property which existance in %json% is to be verified. */
			property = ~~
		RET 
			/** `1` if %json% contains a sub-expression matched by %property%, or `0` otherwise. */
			exists

	/** Returns the value of a subexpression of an input json string, defined by its 'path'
	  * from the root element. The %property% variable must be a string containing and
	  * uninterrupted sequence of chunks in one of the formats:
	  *  - `[%n%]` will 'select' the (n+1)-th element of the array being the current 'top' element.
	  *    If the top element is not an array or the array does not contain that many elements,
	  *    The %property% will not match any element.
	  *  - `.%field%` will 'select' the field of the given name (an unquoted string) of the top
	  *    json object. The leading dot of %property% selecting a field from the top object can
	  *    be ommited. If the top element is not a json object, or the json object does not contain
	  *    a field of the given name, the %property% will not match any element.
	  * An empty property matches the top element itself. 
	  * This is simply a shortcut for calling `json_value` for the result of `get_json` - seen
	  * these functions for more details. In particular, if there is no element in %json% matching
	  * %property%, or that element is not an atomic json value, the component installation will fail.
	  */
	DEFINE_ACTION/PATCH_FUNCTION get_json_value 
		STR_VAR
			/** The input (top-level) json expression. */
			json = ~~
			/** A string defining the path to the returned element as a sequence of field names
			  * and indexing expressions separated by the '.' character. */
		RET	
			/** The ready-to-use value of the nested json element matched by %property%. 
			  * Regular expressions and json strings are returned as WeiDU string, while
			  * Boolean and integer values are returned as numbers. If there is no element
			  * matching the given path, this will be an empty string. Calling code can
			  * distinguish this case from an actual empty string value by verifying the
			  * %exists% return variable.
			  */
			res
			/** Set to `0` if %property% does not match a subexpression of %json%, or to `1` otherwise. */
			exists

	/** Returns the value of a boolean subexpression (i.e., `0` or `1`) of input %json%. 
	  * This is a simple shortcut for calling `json_to_boolean`	for the result of `get_json`.
	  * Consult these functions - especially the latter - for more deatils.
	  * If the value does not exist, or is not a json boolean, component installation will fail.
	  */
	DEFINE_ACTION/PATCH_FUNCTION get_json_boolean
		STR_VAR
			/** The input (top-level) json expression. */
			json = ~~
			/** A string defining the path to the returned element as a sequence of field names
			  * and indexing expressions separated by the '.' character. */
		RET	
			/** `0` if %property% is `false` or `1` if %property% is `true`. */
			res

	/** Returns the value of a numeric subexpression of input %json%. 
	  * This is a simple shortcut for calling `json_to_int`	for the result of `get_json`.
	  * Consult these functions - especially the latter - for more deatils.
	  * If the value does not exist, or is not an integer, component installation will fail.
	  */
	DEFINE_ACTION/PATCH_FUNCTION get_json_int
		STR_VAR
			/** The input (top-level) json expression. */
			json = ~~
			/** A string defining the path to the returned element as a sequence of field names
			  * and indexing expressions separated by the '.' character. */
		RET	
			/** A weidu integer variable with the value of %property%. */
			res

	/** Returns the value of a string subexpression of input %json%. 
	  * This is a simple shortcut for calling `json_to_string` for the result of `get_json`.
	  * Consult these functions - especially the latter - for more deatils.
	  * If the value does not exist, or is not a json string, component installation will fail.
	  */
	DEFINE_ACTION_FUNCTION get_json_string
		STR_VAR
			/** The input (top-level) json expression. */
			json = ~~
			/** A string defining the path to the returned element as a sequence of field names
			  * and indexing expressions separated by the '.' character. */
		RET	
			/** A weidu string variable with the (unquoted) value of %property%. */
			res




#### Local Json modifications
These functions implement operations modifying individual fragments 
of json data.

	/** Substitutes a subexpression specified by its path in input %json% data with a given json value.
	  * This modification is an analogue of the `get_json` accessor function. It takes a %json% 
	  * expression, a %property% string consisting of concatenated accessor chunks in the formats:
	  *  - `[%n%]` will select the (n+1)-th element of the top-level json array;
	  *  - `.%field%` will select the value of the field named `"%field%"` of the top-level json object.
	  * An empty expression selects the whole input json.
	  * The function recursively consumes the first chunk of %property%, tries to match it with
	  * the json expression to select the corresponding subexpression, and calls itself with
	  * the remaining suffix of %property% and the nested subexpression.
	  * If the %property% matches an existing subexpression in the %json% string, it is replaced
	  * in its entirety with %value% (which must be a valid json expresson).
	  * If there is no such subexpression in the input, an attempt will be made to insert 
	  * the %value% expression as deeply as possible in regards to %property% and in the manner 
	  * such that `get_json` for the same %property% will return the freshly inserted expression.
	  * This function will never create an intermediate object to match a segment of %property%,
	  * but will always try to insert %value% directly into an existing subexpression, failing
	  * component installation if it cannot be done.
	  * The exact procedure recursively follows %property% in the manner consistent with `get_json` up
	  * until the moment when no matching subexpression exists:
	  *  - if the %property% starts with an indexing expression `[%n%]`, recursively descend
	  *    into the n-th element of the top-level array. If no such element exists, but the %property%
	  *    equals ~[%length%]~ where %length% is the number of elements in the array, %value% is added
	  *    after the current last element of the array, becoming its (n+1)-th element.
	  *    Otherwise the element can't be inserted and the recursion backtracks. Likewise, 
	  *    if the current top-level expression is not a json array, the recursion also backtracks
	  *    to try a different match.
	  *
	  *  - otherwise treat %property% as a sequence of field names of the top-level object and
	  *    try to match first the whole %property% with an existing field name of the object,
	  *    followed by all proper prefixes ending right before '.' or '['. If only one such
	  *    field exists, the behaviour is intuitive. Otherwise all prefixes are tried in the order
	  *    of descending length to find an exact match (an expression which would be returned by
	  *    `get_json`). If such a match exists, the corresponding subexpression is replaced with
	  *    %value%, ending the operation with a success. If such a substitution is impossible, but
	  *    there is a field corresponding to a prefix of %property%, the recursion descends into
	  *    the value of the longest such a field. Finally, if no dot-ending prefix of %property% 
	  *    matches a field of the top level object, a field named "%property%" is created
	  *    in the top-level scope and its value is set to %value%.
	  * If it is impossible to insert the new element in a way consistent with `get_json`,
	  * component installation will fail.
	  * Note that in cases of possible ambiguity when %property% does not match an existing 
	  * subexpression the result might be counterintuitive, for example creating a field with 
	  * a name like "[0]" or "unmatched[x].expression". For that reason its best to assert that
	  * all intermediate objects up until the final field (or indexed access exists). In other
	  * words, the mods should limit themselves to inserting elements corresponding only to the
	  * last segment of %property% - either a new element at the end of the matched array, or
	  * an object field with a simple name (without any '.', '[', ']'). The behaviour in other
	  * cases may change in the future.
	  */
	DEFINE_ACTION/PATCH_FUNCTION set_json
		STR_VAR
			/** The modified input json expression. */
			json = ~~
			/** A recursively-formed property specifying a subexpression of %json% as per 
			  * the `get_json` function specification. */
			property = ~~
			/** A json expression which should be located under the path %property% path in the
			    modified json. */
			value = ~~
		RET
			/** A json expression resulting from substituting subexpression %property% 
			    of input %json% with %value%, or inserting %value% into %json% in such a way
				that `get_json` will locate it under the same property in the result. */
			res


	/** Modifies the content of a json array given as a string around a given index. 
	  * Separate arguments result in different type of modifications; providing multiple is possible.
	  * Leaving the default value (~~) means that type of modification is not performed.
	  * Allowed operations, and the order in which they are performed are as follows:
	  *  - delete = <number>:  delete that many elements from the array, starting with index %at%;
	  *  - set = <json>:       update the %at%-th element of the array to the given value
	  *  - insert = <json>:    insert the new element at index %at%, pushing all items from that index 
	  *                        further back (so the index of current item at %at% will be %at%+1 and so on).
	  *  - insertall=<jarray>: insert all elements of the given array into the given array, pushing all
	  *                        items currently at index %at% and above n slots further, where n is the number
	  *                        of elements in the array.
	  */
	DEFINE_ACTION/PATCH_FUNCTION update_json_array
		INT_VAR 
			/** Index in the modified array at which the change is made. Must be `0 <= at < size`
			  * (where size is the size of the array) for set and delete operations, 
			  * can be equal to size for insert/insertall. */
			at = 0
			/** Number of elements to delete from the array starting with index %at%. */
			delete = 0
		STR_VAR 
			/** The modified array in the Json format. */
			json = ~~
			/** Exchange the element at the given index for this one - must be valid json. */
			set = ~~
			/** Insert a new element to the array at the given index. Current element and all following are
			  * pushed up by 1. Must be valid json. */
			insert = ~~
			/** List of elements to insert at the given index in the json array format. All elements in
			  * the modified array from index %at% are pushed up to make space. */
			insertall = ~~
		RET 
			/** The array after the modification(s) in the json format. */
			res

	/** Updates a json object given as a string. The update may consist of any of the following operations:
	  *  - adding all fields from another object, overwriting previous values;
	  *  - deleting a single field;
	  *  - setting the value of a single field, adding that field if not previously present.
	  * If more than one operation is requested, they are executed in that order; only one of each is possible
	  * however. At least one of %merge%, %delete%, %set% input variables should be specified; ommiting any
	  * means the corresponding operation will not be performed.
	  */
	DEFINE_ACTION/PATCH_FUNCTION update_json_object
		STR_VAR
			/** Updated object given as a valid json string. */
			json = ~~
			/** Another valid json object given as a string. */
			merge = ~~
			/** Name of the field (without surrounding '"') to delete. */
			delete = ~~
			/** Name of the field (without surrounding '"') to update. */
			set = ~~
			/** New value for the updated field specified by %set%. Must be valid json if %set% is provided. */
			value = ~~
		RET 
			/** The object with the changes applied as a json string. */
			res

	/** Treats a json array as a stack - with the first element as its top - and provides
	  * standard push, pop and top operations, depending on which arguments are provided.
	  * 1. As the first action, first %pop% elements from the array are removed.
	  * 2. If %push% is not empty, it should contain a valid json expression, which is inserted onto
	  *    the top of the stack.
	  * 3. If %push_all% is not empty, it should contain a json array, and its contents
	  *    are inserted at the beginning of the stack, preserving the order. This is equivalent
	  *    to inserting the contents individually starting from the last and ending with the first.
	  */
	DEFINE_ACTION_FUNCTION json_array_stack
		INT_VAR
			/** Number of existing elements to remove from the top of the stack. */
			pop = 0
		STR_VAR
			/** The json array serving as the stack. Default to an empty array. */
			json = ~[]~
			/** A json expression to insert as the top element of the stack. 
			  * Ignored when empty/not specified. */
			push = ~~
			/** A json array containing elements to be inserted on the top of the stack.
		  	* Ignored when empty/not specified. */
			pushall = ~~
		RET
			/** The stack after modifications. */
			res
			/** The first ('top') element of the returned stack. */
			top





#### Global Json modifications
These functions modify the whole input json expression based on the provided
rules, transforming it into potentially a completely different structure.

	/** Applies a global modification transforming a json expression based on provided rules matching
	  * its affected fragments.
	  * It recursively traverses the json structure and applies the specified patch operation to
	  * elements which path match the given selector %select%. The patch consists of four optional 
	  * steps:
	  *  - matching the found element with the given regular expression %match% - if the match
	  *    fails, all other steps are skipped and the element is treated as if it did not match
	  *    the %path% selector.
	  *  - replacing the matched element with the given %patch%, which can contain regular expression
	  *    group references ~\0~, ~\1~ and so on, as if the element was the subject of
	  *    REPLACE_TEXTUALLY CASE_SENSITIVE EVALUATE_REGEXP ~%match%~ ~%patch%~
	  *  - calling the given action function %map% with arguments %json% - the result of previous steps
	  *    and %property% - the property path leading to the patched element.
	  *  - calling an action macro %macro% with variables %json% and %property% set to the matched 
	  *    element and its fully resolved property path.
	  * If any of these steps returns an empty string, the corresponding element is removed/omitted:
	  * if the removed element was a field in the object, the whole field is removed;
	  * if it was an element of an array, the following elements are shift down to its place.
	  *
	  *  The final result can be one of the following, depending on the value of argument %as%:
	  *  - if %as% is not specified or empty, the patching happens 'in place' with the result 
	  *    of the patch replacing the matched element in the returned json.
	  *  - if %as% equals ~[]~, the root element is replaced with a json array 
	  *    containing all patched elements; all not matched and surrounding elements 
	  *    are discarded.
	  *  - if %as% equals ~{}~, the root element (as seen from offset %offset%) is replaced with a json object
	  *    with matched elements as fields. The names of the fields are the paths to the matched elements
	  *    (in the format accepted by the `get_json` function) and the values 
	  *    are the results of applying the patch. As with the previous case, any not matched
	  *    elements are not included in the result.
	  *  This function is particularly useful when reading data from 2da or CSV files:
	  *  their flat structure means that sometimes several rows describe different parts
	  *  of the same, larger entity, and it would be convenient to handle them together.
	  * 
	  */
	DEFINE_ACTION/PATCH_FUNCTION map_json
		STR_VAR
			/** Input json data. */
			json = ~~
			/** Path selector pointing at elements which should be patched. 
			  * It can consist of any sequence of:
			  *  - a json string (in double quotes) selects an object field of the same name;
			  *  - a '*' character selects all fields of an object;
			  *  - a json object pattern '{"x": json1, "y": json2}' matches any json object 
			  *    whith fields "x" and "y" matching 'json1' and 'json2' (in any order). 
			  *    Both the field name and field value can be a regexp in the format r"regexp", 
			  *    in which case the entirety of field name/value must match the regular expression.
			  *    Otherwise the name/value must exactly equal the provided pattern. This filter
			  *    does not select any field of the current object and instead is used to match
			  *    other fields on the same level as the following path element.
			  *  - ~[%n%]~ selects the (n+1)-th element of an array;
			  *  - ~[%n%-%m%]~ selects the elements of an array with indices between %n% (inclusive) 
			  *    and %m% (exclusive). Any of the two values can be missing, denoting the start 
			  *    and the end of the array, respectively.
			  * All whitespace surrounding the individual path elements is ignored.
			  * An empty selector points directly to the root element; this is the default value.
			  * As follows, the selector ~[-] {"class": r"Thief/.*"} "abilities" *~ would match all field 
			  * values of the object under the "abilities" field for all elements of the root array
			  * which have a field "class" matching "Thief/.*".
			  */
			
			match = ~.*~
			/** The replacement value for the matched elements. Defaults to ~\0~, meaning the matched
			  * element is used without changes. */
			patch = ~\0~
			/** If not empty, it is treated as the name of an action function to invoke for every
			  * matched element. It should accept arguments %json% for the matched value and %property%
			  * for the property path leading to it. */
			map = ~~
			/** If not empty, it is treated as a name of an action macro to execute for each matched element.
			  * Before each call, the %json% variable is set to the matched element, while %property% to its property path. */
			macro = ~~
			/** Specifies the manner in which the patched elements are returned. If omitted, the patched
			  * values simply replace the originals in the buffer. If equal to ~[]~, the root json
			  * element is completely replaced with an array containing directly all patched elements.
			  * If equal to ~{}~, the root json element is replaced with a json object with fields named
			  * after concrete paths to found elements (i.e., without any wildcards) and their values
			  * are the results of applying the patch. */		  
			as = ~~
		RET 
			/** The result json expression. */
			res



	/** Traverse a json an array retrieving for every element the value of the given property
	  * to use as a key and group all elements with the same key value in a json array.
	  * The json arrays containing the elements with the same key are returned as a weidu
	  * array which contains a key for every encountered value of %property%, mapped into
	  * the aforementionned groups.
	  */
	DEFINE_ACTION/PATCH_FUNCTION index_json	
		STR_VAR 
			/** Input json array. */
			json = ~[]~
			/** The property by which the elements should be grouped. It can be an unquoted name of
			  * a field for objects, an indexing expression like [%i%] for arrays, or any complex
			  * property accepted by `get_json`. 
			  */
			by = ~~
		RET	
			/** Number of different key values and the effective size of the result array %res%.
			  * Will be zero for empty input json, in which case the array will contain an artificial
			  * element. */
			size
		RET_ARRAY 
			/** A weidu array mapping the keys - encountered values of the %property% for all elements
			  * in the input array %json% - into json arrays which contain every element in the input
			  * array with that particular value of the %property% property. The elements in each
			  * json array appear in the exact same order as in the input array. 
			  */
			res



	/** Traverse a json an array retrieving for every element the value of the given property
	  * to use as a key and group all elements with the same key value in a json array.
	  * The json arrays containing the elements with the same key are returned as a object
	  * which contains a field for every encountered value of %property%, mapped into
	  * the aforementionned groups.
	  */
	DEFINE_ACTION/PATCH_FUNCTION group_json	
		INT_VAR
			/** Specifies if the value of the %property% is a json string and it should be used
			  * directly as the name of the field. The default behaviour allows any json expression
			  * as the value of %property%, mandating quoting it for use as a json string name of 
			  * the result object. This means that string values will be doubly quoted; %res% in
			  * `group_json STR_VAR by = ~"name"~ json = ~[{"name": "Imoen"}, {"name": "Jaheira"}]~ RET res END
			  * would be ~{"\"Imoen\"": [{"name": "Imoen"}], "\"Jaheira\"": [{"name": "Jaheira"}]}~
			  * Setting this value to any positive value will avoid double quoting, resulting in
			  * fields "Imoen" and "Jaheira" instead, but will fail the installation if a non-string
			  * is encountered. 
			  */
			literal = 0
		STR_VAR 
			/** Input json array. */
			json = ~[]~
			/** The property by which the elements should be grouped. It can be an unquoted name of
			  * a field for objects, an indexing expression like [%i%] for arrays, or any complex
			  * property accepted by `get_json`. 
			  */
			by = ~~
		RET
			/** A json object mapping the keys - encountered values of the %property% for all elements
			  * in the input array %json% - into json arrays which contain every element in the input
			  * array with that particular value of the %property% property. The elements in each
			  * individual json array appear in the exact same order as in the input array. 
			  */
			res





#### File reads

	/** Reads and validates json data from a file. */
	DEFINE_ACTION/PATCH_FUNCTION read_json_file
		INT_VAR 
			/** If set to a positive value, all weidu variables '%var%' will be substituted
			  * with their current values as per EVALUATE_BUFFER.
			  */
			eval = 0
		STR_VAR 
			/** Name of the file to read. Must contain a single json element. */
			file = ~~
		RET 
			/** The contents of the file. */
			json


	/** Reads a 2da file in the standard IE format and transforms it to a weidu array. 
	  * The first row should contain the names of the columns. Each subsequent row
	  * is then transformed into a single json object which fields are named after
	  * the column names, with the values taken from the corresponding column.
	  */
	DEFINE_ACTION/PATCH_FUNCTION read_2da_as_json_array
		INT_VAR
			/** If set to a positive value, all weidu variables %var% will be substituted
			  * with their current values as per EVALUATE_BUFFER. 
			  */
			eval = 0
		STR_VAR 
			/** Name of the file to read, including the extension. */
			file = ~~
			/** A sequence of characters used to insert comments/comment out rows
			  * in the input file. If not empty, any line starting with this string
			  * will be ignored.
			  */
			comment = ~~
		RET 
			/** Number of rows in the file, excluding the first row with column names 
			  * and any commented lines. */
			size
		RET_ARRAY 
			/** A weidu array indexed by consecutive integers starting with zero,
			  * with an entry for each data row in the file. If %size% is zero,
			  * it will contain an artificial element.
			  */
			res


	/** Reads a 2da file in the standard IE format and transforms it into a json array. 
	  * The first row should contain the names of the columns. Each subsequent row
	  * is then transformed into a single json object which fields are named after
	  * the column names, with the values taken from the corresponding column.
	  */
	DEFINE_ACTION/PATCH_FUNCTION read_2da_as_json
		INT_VAR
			/** If set to a positive value, all weidu variables %var% will be substituted
			  * with their current values as per EVALUATE_BUFFER. 
			  */
			eval = 0
		STR_VAR 
			/** Name of the file to read, including the extension. */
			file = ~~
			/** A sequence of characters used to insert comments/comment out rows
			  * in the input file. If not empty, any line starting with this string
			  * will be ignored.
			  */
			comment = ~~
		RET 
			/** Number of rows in the file, excluding the first row with column names 
			  * and any commented lines. */
			size
			/** A json array with an element for each data row in the file. */
			res


	/** Reads a CSV file and transforms it to a weidu array of json objects. 
	  * CSV format consists of column values separated by commas, although
	  * the character(s) used can be customized with the %separators% parameter.
	  * All leading and trailing whitespace in a column is ignored and the value
	  * is formatted either as a number, if it forms a valid weidu integer value,
	  * or as a json string.
	  * The first row should contain the names of the columns. Each subsequent row
	  * is then transformed into a single json object which fields are named after
	  * the column names, with the values taken from the corresponding column.
	  */
	DEFINE_ACTION/PATCH_FUNCTION read_csv_as_json_array
		INT_VAR
			/** If set to a positive value, all weidu variables %var% will be substituted
			  * with their current values as per EVALUATE_BUFFER. 
			  */
			eval = 0
		STR_VAR 
			/** Name of the file to read, including the extension. */
			file = ~~
			/** A sequence of characters used to insert comments/comment out rows
			  * in the input file. If not empty, any line starting with this string
			  * will be ignored.
			  */
			comment = ~~
			/** A string, each character of which is considered to be a column separator.
			  * If set to an empty string, whitespace sections will be treated as separators.
			  * Defaults to ~,~ */
			separators = ~,~
		RET 
			/** Number of rows in the file, excluding the first row with column names 
			  * and any commented lines. */
			size
		RET_ARRAY 
			/** A weidu array indexed by consecutive integers starting with zero,
			  * with an entry for each data row in the file. If %size% is zero, it will
			  * contain an artificial element. */
			res


	/** Reads a CSV file and transforms it to a json array. 
	  * CSV format consists of column values separated by commas, although
	  * the character(s) used can be customized with the %separators% parameter.
	  * All leading and trailing whitespace in a column is ignored and the value
	  * is formatted either as a number, if it forms a valid weidu integer value,
	  * or as a json string.
	  * The first row should contain the names of the columns. Each subsequent row
	  * is then transformed into a single json object which fields are named after
	  * the column names, with the values taken from the corresponding column.
	  */
	DEFINE_ACTION_FUNCTION read_csv_as_json
		INT_VAR
			/** If set to a positive value, all weidu variables %var% will be substituted
			  * with their current values as per EVALUATE_BUFFER. 
			  */
			eval = 0
		STR_VAR 
			/** Name of the file to read, including the extension. */
			file = ~~
			/** A sequence of characters used to insert comments/comment out rows
			  * in the input file. If not empty, any line starting with this string
			  * will be ignored.
			  */
			comment = ~~
			/** A string, each character of which is considered to be a column separator.
			  * If set to an empty string, whitespace sections will be treated as separators.
			  * Defaults to ~,~ */
			separators = ~,~
		RET 
			/** Number of rows in the file, excluding the first row with column names 
			  * and any commented lines. */
			size
			/** A json array with an entry for each data row in the file. */
			res
	
