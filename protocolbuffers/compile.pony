use "collections"
use "files"

primitive _Indent
  fun apply(text: String ref, count: USize = 1) =>
    var i: USize = 0
    while i < count do
      text.append("  ")
      i = i + 1
    end
primitive _Newline
  fun apply(text: String ref, count: USize = 1) =>
    var i: USize = 0
    while i < count do
      text.append("\n")
      i = i + 1
    end
primitive _Space
  fun apply(text: String ref, count: USize = 1) =>
    var i: USize = 0
    while i < count do
      text.append(" ")
      i = i + 1
    end
primitive _Append
  fun apply(text: String ref, str: Stringable) =>
    text.append(str.string())

primitive _Capitalize
  fun apply(text: String ref): String ref =>
    try
      if (text(0)? >= 97) and (text(0)? <= 122) then
        text(0)? = text(0)? - 20
      end
    end
    text

primitive Compile
  fun apply(schema: Schema, path: FilePath)? =>
    let unique: Set[String ref] = Set[String ref]
    for enum in schema.enums.values() do
      _CompileEnum(enum, path, unique)?
    end
    for message in schema.messages.values() do
      for enum in message.enums.values() do
        _CompileEnum(enum, path, unique)?
      end
    end

primitive _CompileEnum
  fun apply(enum: Enum, path: FilePath, unique: Set[String ref])? =>
    let enumName: String ref = _Capitalize(enum.name)

    let text: String ref = String(100)
    let typetxt: String ref = String(100)
    let decodetxt: String ref = String(100)
    let encodetxt: String ref = String(100)

    _Append(typetxt, "type")
    _Space(typetxt)
    _Append(typetxt, enumName)
    _Space(typetxt)
    _Append(typetxt, "is")
    _Space(typetxt)
    _Append(typetxt, "(")

    let name: String ref = String(enum.name.size() + 5)
    name.append(enum.name)
    name.append(".pony")
    var first: Bool = true
    var i: USize = 0
    for (key, value) in enum.value.pairs() do
      let valueName: String ref = key.string()
      if first then
        //Encoder
        _Append(encodetxt, "primitive")
        _Space(encodetxt)
        _Append(encodetxt, "_")
        _Append(encodetxt, "Encode")
        _Append(encodetxt, enumName)
        _Newline(encodetxt)
        _Indent(encodetxt)
        _Append(encodetxt, "fun apply(value: ")
        _Append(encodetxt, enumName)
        _Append(encodetxt, "): U64 =>")
        _Newline(encodetxt)
        _Indent(encodetxt, 2)
        _Append(encodetxt, "match")
        _Space(encodetxt)
        _Append(encodetxt, "value")
        _Newline(encodetxt)
        _Indent(encodetxt, 3)
        _Append(encodetxt, "| ")
        //Decoder
        _Append(decodetxt, "primitive")
        _Space(decodetxt)
        _Append(decodetxt, "_")
        _Append(decodetxt, "Decode")
        _Append(decodetxt, enumName)
        _Newline(decodetxt)
        _Indent(decodetxt)
        _Append(decodetxt, "fun apply(value: ")
        _Append(decodetxt, "U64")
        _Append(decodetxt, "): " + enumName +" =>")
        _Newline(decodetxt)
        _Indent(decodetxt, 2)
        _Append(decodetxt, "match")
        _Space(decodetxt)
        _Append(decodetxt, "value")
        _Newline(decodetxt)
        _Indent(decodetxt, 3)
        _Append(decodetxt, "| ")
      else
        _Indent(encodetxt, 3)
        _Append(encodetxt, "| ")
        _Indent(decodetxt, 3)
        _Append(decodetxt, "| ")
      end
      //Encoder
      _Append(encodetxt, valueName)
      _Append(encodetxt, " => ")
      _Append(encodetxt, value.value.string())
      _Newline(encodetxt)
      //Decoder
      _Append(decodetxt, value.value.string())
      _Append(decodetxt, " => ")
      _Append(decodetxt, valueName)
      _Newline(decodetxt)
      i = i + 1
      if not first then
        _Append(typetxt, " | ")
      else
        first = false
      end
      _Append(typetxt, valueName)
    end


    _Indent(encodetxt, 2)
    _Append(encodetxt, "end")
    _Newline(encodetxt)
    _Newline(encodetxt)
    _Indent(decodetxt, 2)
    _Append(decodetxt, "end")
    _Newline(decodetxt)
    _Newline(decodetxt)
    _Append(typetxt, ")")
    _Newline(typetxt)
    _Newline(typetxt)

    let path': FilePath = FilePath(path, name.string())?
    match CreateFile(path')
      | let file: File =>
        file.set_length(typetxt.size() + decodetxt.size() + encodetxt.size())
        file.write(text)
        file.write(typetxt)
        file.write(decodetxt)
        file.write(encodetxt)
      else
        error
    end
