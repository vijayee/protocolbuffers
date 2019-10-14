use "regex"
use "ponytest"
primitive Tokens
  fun apply(): Array[(String, String)] =>
    [
      ("COMMENT_OL", "\\/\\/.*?\\n")
      ("COMMENT_ML", "\\/\\*(?:.|[\\r\\n])*?\\*\\/")
      ("OPTION", "option\\s+((?:.|[\\n\\r])*?);")
      ("IMPORT", "import\\s+\"(.+?).proto\"\\s*;")
      ("MESSAGE", "message\\s+([A-Za-z_][0-9A-Za-z_]*)")
      ("ENUM", "enum\\s+([A-Za-z_][0-9A-Za-z_]*)")
      ("PACKAGE", "package\\s+[A-Za-z_][0-9A-Za-z_\\.]*\\s*;")
      ("SYNTAX", "syntax\\s*=\\s*\"(.*?)\"\\s*;")
      ("EXTEND", "extend\\s+([A-Za-z_][0-9A-Za-z_\\.]*)")
      ("EXTENSION", "extensions\\s+(\\d+)\\s+to\\s+(\\d+|max)\\s*;")
      ("ONEOF", "oneof\\s+([A-Za-z_][0-9A-Za-z_]*)")
      ("MODIFIER", "(optional|required|repeated)")
      ("FIELD", "([A-Za-z][0-9A-Za-z_]*)\\s+([A-Za-z][0-9A-Za-z_]*)\\s*=\\s*(\\d+)")
      ("MAP_FIELD", "map<([A-Za-z][0-9A-Za-z_]+),\\s*([A-Za-z][0-9A-Za-z_]+)>\\s+([A-Za-z][0-9A-Za-z_]*)\\s*=\\s*(\\d+)")
      ("DEFAULT", "default\\s*=")
      ("PACKED", "packed\\s*=\\s*(true|false)")
      ("DEPRECATED", "deprecated\\s*=\\s*(true|false)")
      ("CUSTOM", "(\\([A-Za-z][0-9A-Za-z_]*\\).[A-Za-z][0-9A-Za-z_]*)\\s*=")
      ("LBRACKET", "\\[")
      ("RBRACKET", "\\]\\s*;")
      ("LBRACE", "\\{")
      ("RBRACE", "\\}\\s*;{0,1}")
      ("COMMA", ",")
      ("SKIP", "\\s")
      ("SEMICOLON", ";")
      ("NUMERIC", "(-?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?)")
      ("STRING", """("(?:\\.|[^"\\])*"|\'(?:\\.|[^"\\])*\')""")
      ("BOOLEAN", "(true|false)")
      ("ENUM_FIELD_WITH_VALUE", "([A-Za-z_][0-9A-Za-z_]*)\\s*=\\s*(0x[0-9A-Fa-f]+|-\"+\\|\\d+)")
      ("ENUM_FIELD", "([A-Za-z_][0-9A-Za-z_]*)")
    ]
class MatchedTokens
primitive Tokenize
  fun apply() =>
    let tokens = Tokens()
    for token in token
class GetToken
  let _regex: Regex

  new create(t: TestHelper, nun: None = None) ? =>
    let rx: String val = recover
      let tokens = Tokens()
      var size: USize = 0
      //Get total length of string
      for pair in tokens.values() do
        size = size + pair._2.size()
      end
      //Add delimeter sizes
      size = size + (6 * tokens.size()) + (tokens.size() - 1)
      let rx: String ref = String(size)
      var first = true
      for pair in tokens.values() do
        if (not first) then
          rx.append("|")
        else
          first = false
        end
        rx.append("(?P<")
        rx.append(pair._1)
        rx.append(">")
        rx.append(pair._2)
        rx.append(")")
      end
      rx
    end
    t.log(rx)
    _regex = recover Regex(rx)? end
    t.log("success")

  fun apply(text: String val) : MatchIterator ref =>
    _regex.matches(text)
