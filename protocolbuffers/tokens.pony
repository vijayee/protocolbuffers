use "ponytest"

primitive Tokenize
  fun apply(text: String ref): Array[String ref] =>
    //([;,{}()=:[\]<>]|\/\*|\*\/)
    let list: Array[String] = [
      ";"
      ","
      "{"
      "}"
      "("
      ")"
      "="
      ":"
      "["
      "]"
      "<"
      ">"
      "]"
      "/*"
      "*/"
    ]
    for symbol in list.values() do
      let sym: String box = symbol
      text.replace(sym, " " + sym + " ")
    end
    let lines: Array[String] = text.split("\n")
    let trimmed: Array[String ref] = Array[String ref](lines.size())
    for line in lines.values() do
      let line': String ref = line.clone()
      line'.trim_in_place()
      if line' != "" then
        trimmed.push(line')
      end
    end
    let trimmed2: Array[String ref] = Array[String ref](trimmed.size())
    for line in trimmed.values() do
      try
        let index: ISize = line.find("//")?
        line.delete(index, line.size())
      end
      line.trim_in_place()
      if line != "" then
        trimmed2.push(line)
      end
    end
    let text2: String ref = String(0)
    var first: Bool = true
    for line in trimmed2.values() do
      if first == false then
        text2.append("\n")
      else
        first = false
      end
      text2.append(line)
    end
    let lines2: Array[String] = text2.split(" \n")
    let tokens: Array[String ref] = Array[String ref](lines2.size())
    var inside: Bool = false
    for line in lines2.values() do
      if line == "/*" then
        inside = true
        continue
      elseif line == "*/" then
        inside = false
        continue
      elseif line == "" then
        continue
      end
      if inside == false then
        tokens.push(line.clone())
      end
    end
    tokens
