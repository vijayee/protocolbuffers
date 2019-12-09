use "collections"
use "logger"

primitive IsPackableType
  fun apply (ptype: String box) : Bool =>
    match ptype
      | "int32" => true
      | "int64" => true
      | "uint32" => true
      | "uint64" => true
      | "sint32" => true
      | "sint64" => true
      | "bool" => true
      | "fixed64" => true
      | "sfixed64" => true
      | "double" => true
      | "fixed32" => true
      | "sfixed32" => true
      | "float" => true
    else
      false
    end

primitive RemoveQuotes
  fun apply (text: String ref) ? =>
    while text(0)? == '"' do
      text.delete(0)
    end
    while text(text.size() - 1)? == '"' do
      text.delete(text.size().isize() - 1)
    end

primitive ParsePackageName
  fun apply (tokens: Array[String ref], log: Logger[String]) : String ref ? =>
    tokens.shift()?
    let packageName: String ref = tokens.shift()?
    if tokens(0)? != ";" then
      log(Error) and log.log("""Expected ';' but found '""" + tokens(0)?.string() +"""'""")
      error
    end
    tokens.shift()?
    packageName

primitive ParseVersion
  fun apply (tokens: Array[String ref], log: Logger[String]) : USize ? =>
    var version: String ref = tokens.shift()?
    if tokens(0)? != ";" then
      log(Error) and log.log("""Expected ';' but found '""" + tokens(0)?.string() + """'""")
      error
    end
    tokens.shift()?
    match version
      | """"proto2"""" => USize(2)
      | """"proto3"""" => USize(3)
    else
      log(Error) and log.log("""Invalid syntax version '""" + version.string() + """'""")
      error
    end

primitive ParseEnumValue
  fun apply (tokens: Array[String ref], log: Logger[String]) : EnumValue ? =>
    if tokens.size() < 4 then
      log(Error) and log.log("""Invalid enum value""")
      error
    end
    if tokens(1)? != "=" then
      log(Error) and log.log("""Expected '=' but found '""" + tokens(1)?.string() + """'""")
      error
    end
    if (tokens(3)? != ";") and (tokens(3)? != "[")  then
      log(Error) and log.log("""Expected ';' or '[' but found '""" + tokens(1)?.string() + """'""")
      error
    end
    let name: String ref = tokens.shift()?
    tokens.shift()?
    let value: Value = Value(tokens.shift()?.u64()?, if tokens(0)? == "[" then ParseFieldOption(tokens, log)? else  OptionMap end)
    tokens.shift()?
    EnumValue(name, value)

primitive ParseEnum
  fun apply (tokens: Array[String ref], log: Logger[String]) : Enum ? =>
    tokens.shift()?
    let options: OptionMap = OptionMap
    let name: String ref = tokens.shift()?
    let value: Map[String ref, Value] = Map[String ref, Value]
    let enum: Enum = Enum(name, options, value)

    if tokens(0)? != "{" then
      log(Error) and log.log("""Expected '{' but found '""" + tokens(0)?.string() +"""'""")
       error
    end
    tokens.shift()?

    while tokens.size() > 0 do
      if tokens(0)? == "}" then
        tokens.shift()?
        if tokens(0)? == ";" then
          tokens.shift()?
        end
        return enum
      end

      if tokens(0)? == "option" then
        let option: (String ref, OptionType) = ParseOption(tokens, log)?
        enum.options(option._1) = option._2
        continue
      end
      let eval: EnumValue = ParseEnumValue(tokens, log)?
      enum.value(eval.name) = eval.value
    end
    log(Error) and log.log("No closing tag for enum")
    error

primitive ParseOption
  fun apply(tokens: Array[String ref], log: Logger[String]) : (String ref, OptionType) ? =>
    var name: String ref = String(0)
    var value: OptionType = None
    let parse = {(text: String ref) : (String ref | Bool) ? =>
      if text == "true" then
        return true
      end
      if text == "false" then
        return false
      end
      RemoveQuotes(text)?
      text
    }
    while tokens.size() > 0 do
      if tokens(0)? == ";" then
        tokens.shift()?
        return (name, value)
      end

      match tokens(0)?
        | "option" =>
          tokens.shift()?
          let hasBracket = (tokens(0)? == "(")
          if hasBracket then
            tokens.shift()?
          end

          name = tokens.shift()?
          if hasBracket then
            if tokens(0)? != ")" then
              log(Error) and log.log("""Expected ')' but found '""" + tokens(0)?.string() + """'""")
              error
            end
            tokens.shift()?

            if tokens(0)?(0)? == '.' then
              name.append(tokens.shift()?)
            end
          end
        | "=" =>
          tokens.shift()?
          if name == "" then
            log(Error) and log.log("Expected key for option with value: " + tokens(0)?.string())
            error
          end
          value = parse(tokens.shift()?)?
          if name == "optimize_for" then
            match value
              | let value': String ref =>
                if not(value'.contains("SPEED") or value'.contains("CODE_SIZE") or value'.contains("LITE_RUNTIME")) then
                  log(Error) and log.log("Unexpected value for option optimize_for: " + value'.string())
                  error
                end
            end
          else
            match value
              | "{" =>
                value = ParseOptionMap(tokens, log)?
            end
          end
      else
        log(Error) and log.log("Unexpected token in option: " + tokens(0)?.string())
        error
      end
    end
    log(Error) and log.log("Missing ';' in option")
    error

primitive ParseOptionMap
  fun apply(tokens: Array[String ref], log: Logger[String]) : OptionMap ? =>
    let parse = {(text: String ref) : (String ref | Bool) ? =>
      if text == "true" then
        return true
      end
      if text == "false" then
        return false
      end
      RemoveQuotes(text)?
      text
    }
    let map: OptionMap = OptionMap()
    while tokens.size() > 0 do
      if tokens(0)? == "}" then
        tokens.shift()?
        return map
      end
      var hasBracket: Bool = tokens(0)? == "("
      if hasBracket then
        tokens.shift()?
      end

      let key: String ref = tokens.shift()?

      if hasBracket then
        if tokens(0)? != ")" then
          log(Error) and log.log("""Expected ')' but found '""" + tokens(0)?.string() + """"'""")
          error
        end
        tokens.shift()?
      end

      var value: OptionType = None

      match tokens(0)?
        | ":" =>
          if map.contains(key.clone()) then
            log(Error) and log.log("Unexpected token in option: " + tokens(0)?.string())
            error
          end
          tokens.shift()?
          value = parse(tokens.shift()?)?
          match value
            | let value': String ref=>
              if value' == "{" then
                value = ParseOptionMap(tokens, log)?
              end
          end
          map(key) = value
          if tokens(0)? == ";" then
            tokens.shift()?
          end
        | "{" =>
          tokens.shift()?
          value = ParseOptionMap(tokens, log)?
          if not map.contains(key.clone()) then
            map(key) = OptionArray()
          end
          match map(key)?
            | let arr: OptionArray =>
              arr.push(value)
          else
            log(Error) and log.log("Duplicate option map key: " + tokens(0)?.string())
            error
          end
      else
        log(Error) and log.log("Unexpected token in option: " + tokens(0)?.string())
        error
      end
    end
    log(Error) and log.log("Unexpected token in option map: " + tokens(0)?.string())
    error

primitive ParseImport
  fun apply (tokens: Array[String ref], log: Logger[String]) : String ref ? =>
    tokens.shift()?
    let text: String ref = tokens.shift()?

    if text(0)? == '"' then
      text.delete(0)
    end
    if text(text.size() - 1)? == '"' then
      text.delete(text.size().isize() - 1)
    end

    if tokens(0)? != ";" then
      log(Error) and log.log("Unexpected token: " + tokens(0)?.string() + ". Expected ';'")
      error
    end
    tokens.shift()?
    text

primitive ParseFieldOption
  fun apply (tokens: Array[String ref], log: Logger[String]) : OptionMap ? =>
    let options: OptionMap  = OptionMap
    let process = {(tokens: Array[String ref], options: OptionMap, log: Logger[String]) ? =>
      tokens.shift()?
      var name: String ref = tokens.shift()?

      if name == "(" then
        name = tokens.shift()?
        tokens.shift()?
      end

      if tokens(0)? != "=" then
        log(Error) and log.log("Unexpected token in field options: " + tokens(0)?.string())
        error
      end

      tokens.shift()?

      if tokens(0)? == "]" then
        log(Error) and log.log("Unexpected token ']' in field option")
        error
      end
      options(name) = tokens.shift()?
    } ref
    while tokens.size() > 0 do
      match tokens(0)?
        | "[" => process(tokens, options, log)?
        | "," => process(tokens, options, log)?
        | "]" =>
          tokens.shift()?
          return options
        else
          log(Error) and log.log("Unexpected token in field options: " + tokens(0)?.string())
          error
      end
    end
    log(Error) and log.log("No closing tag for field options")
    error

primitive ParseService
  fun apply (tokens: Array[String ref], log: Logger[String]) : Service ? =>
    tokens.shift()?

    let service: Service = Service(tokens.shift()?)

    if tokens(0)? != "{" then
      log(Error) and log.log("""Expected '{' but found '""" + tokens(0)?.string() +"""'""")
      error
    end
    tokens.shift()?

    while tokens.size() > 0 do
      if tokens(0)? == "}" then
        tokens.shift()?
        if tokens(0)? == ";" then
          tokens.shift()?
        end
        return service
      end

      match tokens(0)?
        | "option" =>
          var option: (String ref, OptionType) = ParseOption(tokens, log)?
          if service.options.contains(option._1.clone()) then
            log(Error) and log.log("""Duplicate option '""" + option._1.string() + """'""")
            error //Duplicate Option
          end
          service.options(option._1) = option._2
        | "rpc" =>
          service.methods.push(ParseRPC(tokens, log)?)
      else
        log(Error) and log.log("Unexpected token in service: " + tokens(0)?.string())
        error //Unexpected token
      end
    end
    log(Error) and log.log("No closing tag for Service")
    error // No Closing Tag

primitive ParseRPC
  fun apply (tokens: Array[String ref], log: Logger[String]) : RPC ? =>
    tokens.shift()?

    var rpc = RPC(tokens.shift()?)
    if tokens(0)? != "(" then
      log(Error) and log.log("""Expected '(' but found ''""" + tokens(0)?.string() + """'""")
      error
    end
    tokens.shift()?

    if tokens(0)? == "stream" then
      tokens.shift()?
      rpc.clientStreaming = true
    end

    rpc.inputType = tokens.shift()?

    if tokens(0)? != ")" then
      log(Error) and log.log("Expected ') but found " + tokens(0)?.string())
      error
    end
    tokens.shift()?

    if tokens(0)? != "returns" then
      log(Error) and log.log("Expected returns but found " + tokens(0)?.string())
      error
    end
    tokens.shift()?

    if tokens(0)? != "("then
      log(Error) and log.log("""Expected '(' but found """ + tokens(0)?.string())
      error
    end
    tokens.shift()?

    if tokens(0)? == "stream" then
      tokens.shift()?
      rpc.serverStreaming = true
    end

    rpc.outputType = tokens.shift()?

    if tokens(0)? != ")" then
      log(Error) and log.log("""Expected '{' but found '""" + tokens(0)?.string() +"""'""")
      error
    end
    tokens.shift()?

    if tokens(0)? == ";" then
      tokens.shift()?
      return rpc
    end

    if tokens(0)? != "{" then
      log(Error) and log.log("""Expected '{' but found '""" + tokens(0)?.string() + """'""")
      error
    end
    tokens.shift()?

    while tokens.size() > 0 do
      if tokens(0)? == "}" then
        tokens.shift()?
        if tokens(0)? == ";" then
          tokens.shift()?
        end
        return rpc
      end
      if tokens(0)? == "option" then
        var option: (String ref, OptionType) = ParseOption(tokens, log)?
        if rpc.options.contains(option._1.clone()) then
          log(Error) and log.log("""Duplicate option '""" + tokens(0)?.string() + """'""")
          error
        end
        rpc.options(option._1) = option._2
      else
        log(Error) and log.log("""Unexpected token '""" + tokens(0)?.string() + """' in rpc options """)
        error
      end
    end
    log(Error) and log.log("Unexpected token in rpc options: " + tokens(0)?.string())
    error

primitive ParseField
  fun apply (tokens: Array[String ref], log: Logger[String]) : Field ? =>
    var field: Field = Field
    let optional ={(tokens: Array[String ref], field: Field) ? =>
      var token = tokens.shift()?
      field.required = (token == "required")
      field.required = (token == "repeated")
      field.fieldType = tokens.shift()?
      field.name = tokens.shift()?
    }
    while tokens.size() > 0 do
      match tokens(0)?
        | "=" =>
          tokens.shift()?
          field.fieldTag = tokens.shift()?.isize()?
        | "map" =>
          field.fieldType = tokens.shift()?
          tokens.shift()?

          if tokens(0)? != "<" then
            log(Error) and log.log("Unexpected token in map type '" +  tokens(0)?.string() + " expected '<'")
            error
          end
          tokens.shift()?
          field.map.from = tokens.shift()?

          if tokens(0)? != "," then
            log(Error) and log.log("""Unexpected token in map type '""" +  tokens(0)?.string() + """' expected ','""")
            error
          end
          tokens.shift()?
          field.map.to = tokens.shift()?

          if tokens(0)? != ">" then
            log(Error) and log.log("""Unexpected token in map type '""" +  tokens(0)?.string() + """ '>'""")
            error
          end
          tokens.shift()?
          field.name = tokens.shift()?
        | "repeated" => optional(tokens, field)?
        | "required" => optional(tokens, field)?
        | "optional" => optional(tokens, field)?
        | "[" =>
          field.options = ParseFieldOption(tokens, log)?
        | ";" =>
          if field.name == "" then
            log(Error) and log.log("Missing Field Name")
            error
          end
          if field.fieldType == "" then
            log(Error) and log.log("Missing type in message field: " + field.name)
            error
          end
          if field.fieldTag == -1 then
            log(Error) and log.log("Missing tag number in message field")
            error
          end
          tokens.shift()?
          return field
      else
        log(Error) and log.log("""No ';' for message field""")
        error
      end
    end
    log(Error) and log.log("""Missing found ';' field""")
    error

primitive ParseExtensions
  fun apply (tokens: Array[String ref], log: Logger[String]) : Extension ? =>
    tokens.shift()?
    let from: ISize = try
      tokens.shift()?.isize()?
    else
      log(Error) and log.log("""Invalid 'from' in extensions definition""")
      error
    end
    if tokens.shift()? != "to" then
      log(Error) and log.log("""Expected keyword 'to' in extensions definition""")
      error
    end

    let to: ISize = if tokens(0)? == "max" then
      ISize.max_value()
    else
      try
        tokens.shift()?.isize()?
      else
        log(Error) and log.log("""Invalid 'to' in extensions definition""")
        error
      end
    end
    if tokens(0)? != ";" then
      log(Error) and log.log("Missing Field Name")
      error
    end
    if (tokens.shift()? != ";") then
      log(Error) and log.log("""Missing ';' in extensions definition""")
    end
    Extension(from, to)

primitive ParseMessage
  fun apply (tokens: Array[String ref], log: Logger[String]) : Message ? =>
    tokens.shift()?
    var level: USize = 1
    var body: Array[String ref] = Array[String ref] (1)
    var message: Message = Message(tokens.shift()?)

    if tokens(0)? != "{" then
      log(Error) and log.log("""Expected '{' but found '""" + tokens(0)?.string() +"""'""")
      error
    end

    tokens.shift()?

    while tokens.size() > 0 do
      if tokens(0)? == "{" then
        level = level + 1
      elseif tokens(0)? == "}" then
        level = level - 1
      end

      if level == 0 then
        tokens.shift()?
        let body': MessageBody = ParseMessageBody(body, log)?
        message.enums = body'.enums
        message.messages = body'.messages
        message.fields = body'.fields
        message.extends = body'.extends
        message.extensions = body'.extensions
        return message
      end
      body.push(tokens.shift()?)
    end
    log(Error) and log.log("""No closing tag for message""")
    error

primitive ParseMessageBody
  fun apply(tokens: Array[String ref], log: Logger[String]): MessageBody ? =>
    var body: MessageBody = MessageBody

    while tokens.size() > 0 do
       match tokens(0)?
        | "map" =>
          body.fields.push(ParseField(tokens, log)?)
        | "repeated" =>
          body.fields.push(ParseField(tokens, log)?)
        | "optional" =>
          body.fields.push(ParseField(tokens, log)?)
        | "required" =>
          body.fields.push(ParseField(tokens, log)?)
        | "enum" =>
          body.enums.push(ParseEnum(tokens, log)?)
        | "message" =>
          body.messages.push(ParseMessage(tokens, log)?)
        | "extensions" =>
          body.extensions = ParseExtensions(tokens, log)?
        | "oneof" =>
          tokens.shift()?
          var name: String ref = tokens.shift()?
          if tokens(0)? != "{" then
            log(Error) and log.log("Unexpected token in oneof: " + tokens(0)?.string())
            error
          end
          tokens.shift()?

          while tokens(0)? == "}" do
            tokens.unshift(String(8).>append("optional"))
            var field: Field = ParseField(tokens, log)?
            field.oneof = name
            body.fields.push(field)
          end
          tokens.shift()?
        | "extend" =>
          body.extends.push(ParseExtend(tokens, log)?)
        | ";" =>
          tokens.shift()?
        | "reserved" =>
          tokens.shift()?
          while tokens(0)? != ";" do
            tokens.shift()?
          end
        | "option" =>
          tokens.shift()?
          while tokens(0)? != ";" do
            tokens.shift()?
          end
       else
         tokens.unshift(String(8).>append("optional"))
         body.fields.push(ParseField(tokens, log)?)
       end
    end
    body

primitive ParseExtend
  fun apply(tokens: Array[String ref], log: Logger[String]): Extend ? =>
    Extend(tokens(1)?, ParseMessage(tokens, log)?)

primitive ContainsOpenQuote
  fun apply (text: String box) : Bool ? =>
    if text.size() == 0 then
      return false
    end
    if (((text(0)? == '"') or (text(0)? == '\''))
      and ((text.size() == 1) or (try (text(text.size() - 1)? != '"') and (text(text.size() - 1)? != '\'') else false end))) then
        return true
    end
    false
primitive ContainsCloseQuote
  fun apply (text: String box) : Bool ? =>
    if text.size() == 0 then
      return false
    end
    if (((text.size() == 1) or ((text(0)? != '"') or (text(0)? != '\'')))
      and (try (text(text.size() - 1)? == '"') or (text(text.size() - 1)? == '\'') else false end)) then
        return true
    end
    false
primitive Parse
  fun apply (text: String ref, log: Logger[String]): Schema ? =>
    var tokens: Array[String ref] = Tokenize(text)
    var i: USize = 0

    while i < tokens.size() do
      if try ContainsOpenQuote(tokens(i)?)? else false end then
        var j: USize = if tokens(i)?.size() == 1 then i + 1 else i end
        var collapse: String ref = String
        collapse.append(tokens(i)?)
        while j < tokens.size() do
          if ContainsCloseQuote(tokens(j)?)? then
            for k in Range(i + 1, j + 1) do
              collapse.append(tokens(k)?)
            end
            let tokens2: Array[String ref] = tokens.slice(0, i)
            i = tokens2.size()
            tokens2.push(collapse)
            tokens2.concat(tokens.values(), j + 1)
            tokens = tokens2
            break
          end
          j = j + 1
        end
      end
      i = i + 1
    end

    var schema: Schema = Schema
    var firstLine: Bool = true
    while tokens.size() > 0 do
      match tokens(0)?
        | "package" =>
          schema.package = ParsePackageName(tokens, log)?
        | "syntax" =>
          if firstLine == false then
            log(Error) and log.log("Syntax version must be the first line of file")
            error
          end
          schema.version = ParseVersion(tokens, log)?
        | "message" =>
          schema.messages.push(ParseMessage(tokens, log)?)
        | "enum" =>
          schema.enums.push(ParseEnum(tokens, log)?)
        | "option" =>
            var option : (String ref, OptionType) = ParseOption(tokens, log)?
            if schema.options.contains(option._1.clone()) then
              log(Error) and log.log("Duplicate Option: " + option._1.string())
              error
            end
            schema.options(option._1) = option._2
        | "import" =>
          schema.extends.push(ParseExtend(tokens, log)?)
        | "service" =>
          schema.services.push(ParseService(tokens, log)?)
      else
        log(Error) and log.log("Unexpected Token: " + tokens(0)?.string())
        error
      end
      firstLine = false
    end

    for extend in schema.extends.values() do
      for message in schema.messages.values() do
        if message.name == extend.name then
          for field in extend.message.fields.values() do
            if (message.extensions.to == -1) or (message.extensions.from == -1)
              or (field.fieldTag < message.extensions.from) or (field.fieldTag > message.extensions.to) then
                log(Error) and log.log(message.name.string() + " does not delcare " + field.fieldTag.string() + " as an extension number")
                error
            end
            message.fields.push(field)
          end
        end
      end
    end

    let enumNameIsFieldType = {(enums: Array[Enum], field: Field): Bool =>
      for enum in enums.values() do
        if enum.name == field.fieldType then
          return true
        end
      end
      false
    } val

    let findMessage = {(messages: Array[Message], messageName: String box): (Message | None) =>
      for message in messages.values() do
        if message.name == messageName then
          return message
        end
      end
      None
    } val

    let enumNameIsNestedEnumName = {(enums: Array[Enum], nestedEnumName: String box): Bool =>
      for enum in enums.values() do
        if enum.name == nestedEnumName then
          return true
        end
      end
      false
    } val
    for message in schema.messages.values() do
      for field in message.fields.values() do
        if try field.options(String(6).>append("packed"))? as Bool == true else false end then
          if IsPackableType(field.fieldType) then
            if not field.fieldType.contains(".") then
              if enumNameIsFieldType(message.enums, field) then
                continue
              end
            else
              var fieldSplit: Array[String] = field.fieldType.split(".")
              if fieldSplit.size() > 2 then
                log(Error) and log.log("Poorly formed type: " + field.fieldType.string())
                error
              end
              let message': (Message | None) = findMessage(schema.messages, fieldSplit(0)?)
              match message'
                | let message'' : Message =>
                  if enumNameIsNestedEnumName(message''.enums, fieldSplit(1)?) then
                    continue
                  end
              end
            end
            log(Error) and log.log("Fields of type " + field.fieldType.string() + " cannot be declared [packed=true]. " +
            "Only repeated fields of primitive numeric types (types which use " +
            "the varint, 32-bit, or 64-bit wire types) can be declared 'packed'. " +
            "See https://developers.google.com/protocol-buffers/docs/encoding#optional")
            error
          end
        end
      end
    end
    schema
