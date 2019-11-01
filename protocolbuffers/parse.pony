use "collections"
primitive IsPackableType
  fun apply (type: String box) : Bool =>
    match type
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
  fun apply (text: String ref)? =>
    while text(0)? == "\"" do
      text.delete(0)
    end
    while text(text.size() - 1)? == "\"" do
      text.delete(text.size() - 1)
    end
primitive ParsePackageName
  fun apply (tokens: Array[String ref]) : String ref ? =>
    tokens.shift()?
    let packageName: String ref = tokens.shift()?
    if tokens(0)? != ";" then
      error
    end
    tokens.shift()?
    packageName

primitive ParseVersion
  fun apply (tokens: Array[String ref]) : USize ? =>
    var version: String ref = tokens.shift()?
    match version
      | """"proto2"""" => USize(2)
      | """"proto3"""" => USize(3)
    else
      error
    end

primitive ParseEnumValue
  fun apply (tokens: Array[String ref]) : EnumValue ? =>
    if tokens.size() < 4 then
      error
    end
    if tokens(1)? == "=" then
      error
    end
    if (tokens(3)? != ";") and (tokens(3)? != "[")  then
      error
    end
    let name: String ref = tokens.shift()?
    tokens.shift()?
    let value: Value = Value(tokens.shift()?.u64(), if tokens(0)? == "[" then ParseFieldOption(tokens)? else  OptionMap end)
    tokens.shift()?
    EnumValue(name, value)

primitive ParseEnum
  fun apply (tokens: Array[String ref]) : Enum ? =>
    tokens.shift()?
    let options: OptionMap = OptionMap
    let name: String ref = tokens.shift()?
    let value: OptionMap = OptionMap
    let enum: Enum = Enum(name, options, value)

    if tokens(0)? != "{" then
       error
    end
    tokens.shift()?

    while tokens.size() > 0 then
      if tokens(0)? == "}" then
        tokens.shift()?
        if tokens(0)? == ";" then
          tokens.shift()?
        end
        return enum
      end

      if tokens(0)? == "option" then
        let option: (String ref, OptionType) = ParseOption(tokens)?
        enum.options(option._1) = option._2
        continue
      end
    end
    error // no closing tag

primitive ParseOption
  fun apply(tokens: Array[String ref]) : (String ref, OptionType) ? =>
    var name: (String ref | None) = None
    var value: (OptionType | None) = None
    let parse = {(text: String Ref) : (String ref | Bool) =>
      if text == "true" then
        return true
      end
      if text == "false" then
        return false
      end
      RemoveQuotes(text)
      return text
    }
    while tokens.size() > 0 then
      if tokens(0)? == ";" then
        tokens.shift()?
        return (name', value')
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
            if tokens(0)? != ')' then
              error
            end
            tokens.shift()?

            if tokens(0)?(0)? == "." then
              name = name + tokens.shift()?
            end
          end
        | "=" =>
          tokens.shift()?
          if name == None then
            error
          end
          value = parse
          tokens.shift()?)
          if ((name == "optimize_for") and (value.contains("SPEED") || value.contains("CODE_SIZE")  || value.contains("LITE_RUNTIME"))) then
            error
          else if (value == "")
            value = ParseOptionMap(tokens)
          end
      else
        error
      end
    end

primitive ParsOptionMap
  fun apply(tokens: Array[String ref]) : OptionMap ? =>
    let parse = {(text: String Ref) : (String ref | Bool) =>
      if text == "true" then
        return true
      end
      if text == "false" then
        return false
      end
      RemoveQuotes(text)
      return text
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
        if tokens(0)? == ")" then
          error
        end

        tokens.shift()?

      end

      var value: OptionType = None

      match tokens(0)?
        | ":" =>
          if  map.contains(key) then error end
          tokens.shift()?
          value = parse(tokens.shift()?)
          match value
            | let value': String =>
              if value' == "{" then
                value = ParseOptionMap(tokens)?
              end
          end
          map(key) = value
          if tokens(0)? == ";" then
            tokens.shift()?
          end
        | "{" =>
          tokens.shift()?
          value = ParseOptionMap(tokens)?
          if not map.contains(key) then
            map(key) = OptionArray()
          end
          match map(key)
            | let arr: OptionArray =>
              arr.push(value)
          else
            error
          end
      else
        error
      end
    end
    error

primitive ParseImport
  fun apply (tokens: Array[String ref]) : String ref ? =>
    tokens.shift()?
    let text: String ref = tokens.shift()?

    if text(0)? == "\"" then
      text.delete(0)
    end
    if text(text.size() - 1)? == "\"" then
      text.delete(text.size() - 1)
    end

    if tokens(0)? != ";" then
      error
    end
    tokens.shift()?
    text

primitive ParseFieldOption
  fun apply (tokens: Array[String ref]) : OptionMap ? =>
    let options: OptionMap  = OptionMap
    let process = {() =>
      tokens.shift()?
      let name: String ref = tokens.shift()?

      if name == "(" then
        name = token.shift()?
        tokens.shift()?
      end

      if tokens(0)? != "=" then
        error
      end

      tokens.shift()?

      if tokens(0)? == "]" then
        error
      end
      options(name) = tokens.shift()?
    }
    while tokens.size() > 0 do
      match tokens(0)?
        | "[" => process()
        | "," => process()
        | "]" =>
          tokens.shift()?
          return options
        else
          error
      end
    end
    error

primitive ParseService
  fun apply (tokens: Array[String ref]) : Service ? =>
    tokens.shift()?

    let service: Service = Service

    if tokens(0)? != "{" then
      error
    end
    tokens.shift()?

    while tokens.size() > 0 do
      if tokens(0)? == "}" then
        tokens.shift()?
        if tokens(0)? == ";" then
          tokens,shift();
        end
        return service
      end

      match tokens(0)?
        | "option" =>
          var option: (String ref, OptionType) = ParseOption(tokens)
          if service.options.contains(option._1) then
            error //Duplicate Option
          end
          service.options(option._1) = option._2
        | "rpc" =>
          service.methods.push(ParseRPC(tokens))
      else
        error //Unexpected token
      end
    end
    error // No Closing Tag

primitive ParseRPC
  fun apply (tokens: Array[String ref]) : RPC ? =>
    tokens.shift()?

    var rpc = RPC()
    if tokens.shift()? != "(" then
      error
    end
    tokens.shift()?

    if tokens(0)? == "stream" then
      tokens.shift()?
      rpc.clientStreaming = true
    end

    rpc.inputType = tokens.shift()?

    if tokens(0)? != ")" then
      error
    end
    tokens.shift()?

    if tokens(0)? != "return" then
      error
    end
    tokens.shift()?

    if tokens(0)? != "("then
      error
    end
    tokens.shift()?

    if tokens(0)? == "stream" then
      tokens.shift()?
      rpc.serverStreaming = true
    end

    rpc.outputType = tokens.shift()?

    if tokens(0)? != ")" then
      error
    end
    tokens.shift()?

    if tokens(0)? == ";" then
      tokens.shift()?
      return rpc
    end

    if tokens(0)? != "{" then
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
        var option: (String ref, OptionType) = ParseOption(tokens)?
        if rpc.options.contains(option._1) then
          error
        end
        rpc.options(option._1) = options._2
      else
        error
      end
    end
    error

primitive ParseField
  fun apply (tokens: Array[String ref]) : Field ? =>
    var field: Field = Field
    let opional ={(tokens: Array[String ref]) ? =>
      var token = tokens.shift()?
      field.required = (token == "required")
      field.required = (token == "repeated")
      field.type = tokens.shift()?
      field.name = tokens.shift()?
    }
    while tokens.size() > 0 do
      match tokens(0)?
        | "=" =>
          tokens.shift()?
          field.tagg = tokens,shift()?.isize()?
        | "map" =>
          field.type = token.shift()?
          tokens.shift()?

          if tokens(0)? != "<" then
            error
          end
          tokens.shift()?
          field.map.from = tokens.shift()?

          if tokens(0)? != "," then
            error
          end
          tokens.shift()?
          field.map.to = tokens.shift()?

          if tokens(0)? != ">" then
            error
          end
          tokens.shift()?
          field.name = tokens.shift()?
        | "repeated" => optional(tokens)?
        | "required" => optional(tokens)?
        | "optional" => optional(tokens)?
        | "[" =>
          field.options = ParseFieldOption(tokens)
        | ";" =>
          if field.name == "" then
            error
          end
          if field.type == "" then
            error
          end
          if field.tagg = -1 then
            error
          end
          tokens.shift()?
          return field
      else
          error
      end
    end

primitive ParseExtensions
  fun apply (tokens: Array[String ref]) : Extension ? =>
    tokens.shift()?
    let from: ISize = tokens.shift()?.isize()
    if tokens.shift()? != "to" then
      error
    end

    let to: ISize = if tokens(0)? == "max" then ISize.max_value() else tokens.shift()?.isize()? end
    if tokens(0)? != ";" then
     error
    end
    tokens.shift()?
    return Extension(from, to)

primitive ParseMessage
  fun apply (tokens: Array[String ref]) : Message ? =>
    tokens.shift()?
    var level: USize = 1
    var body: Array[String ref] = Array[String ref] (1)
    var message: Message = Message

    if tokens(0)? != "{" then
      error
    end

    tokens.shift()?

    while tokens.size() > 0 do
      if tokens(0)? == "{" then
        level = level + 1
      else if tokens(0)? == "}" then
        level = level - 1
      end

      if level == 0 then
        tokens.shift()?
        let body: MessageBody = ParseMessageBody(body)?
        message.enums = body.enums
        message.messages = body.messages
        message.fields = body.fields
        message.extends = body.extends
        message.extensions = body.extensions
        return message
      end
      body.push(tokens.shift()?)
    end
    error

primitive ParseMessageBody
  fun apply(tokens: Array[String ref]): MessageBody ? =>
    var body: MessageBody = MessageBody

    while tokens.size() > 0 then
       match tokens(0)?
        | "map" =>
          body.fields.push(ParseField(tokens)?)
        | "repeated" =>
          body.fields.push(ParseField(tokens)?)
        | "optional" =>
          body.fields.push(ParseField(tokens)?)
        | "required" =>
          body.fields.push(ParseField(tokens)?)
        | "enum" =>
          body.enums.push(ParseEnum(tokens)?)
        | "message" =>
          body.messages.push(ParseMessage(tokens)?)
        | "extensions" =>
          body.extensions.push(ParseExtensions(tokens)?)
        | "oneof" =>
          tokens.shift()?
          var name: String ref = tokens.shift()?
          if tokens(0)? != "{" then
            error
          end
          tokens.shift()?

          while tokens(0)? == "}" then
            tokens.unshift("optional")
            var field: Field = ParseField(tokens)?
            field.oneof = name
            body.fields.push(field)
          end
          tokens.shift()?
        | "extend" =>
          body.extends.push(ParseExtend(tokens)?)
        | ";" =>
          tokefun apply(tokens: Array[String ref]): MessageBody ? =>ns.shift()?
        | "reserved" =>
          tokens.shift()?
          while tokens(0) != ";" then
            tokens.shift()?
          end
        | "option" =>
          tokens.shift()?
          while tokens(0) != ";" then
            tokens.shift()?
          end
       else
         tokens.unshift("optional")
         body.fields.push(ParseFiel(tokens)?)
       end
    end
    return body

primitive ParseExtend
  fun apply(tokens: Array[String ref]): Extend ? =>
    return Extend(tokens(1)?, ParseMessage(tokens)?)

primitive ContainsQuote
  fun apply (text: String box) : Bool ? =>
    if text.size() == 0 then
      return false
    end
    if ((text(0)? == "\"") or (text(0)? == "''))
      and (try ((text(1)? !="\"") and (text(1)? != "\'")) else false end) then
        return true
    end
    false

primitive Parse
  fun apply (text: String ref): Schema ? =>
    var tokens: Array[String ref] = Tokenize(text)
    var i: USize = 0

    while i < tokens.size() do
      if ContainsQuotes(tokens(i)?)? then
        var j: USize = if tokens(i)?.size() == 1 then i + 1 else i end

        while j < tokens.size() do
          if ContainsQuote(tokens(j)?)? then
            var collapse: String ref = ""
            for k in Range(i, j + 1) do
              collapse = collapse + tokens(k)?
            end
            var tokens2: Array[String ref] = tokens.slice(0, i).push(collapse)
            tokens2.append(tokens, j + 1, tokens.size())
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
          schema.package = ParsePackageName(tokens)?
        | "syntax" =>
          if not firstLine then
            error
          end
          schema.syntax = ParseVersion(tokens)?
        | "message" =>
          schema.messages.push(ParseMessage(tokens)?)
        | "enum" =>
          schema.enums.push(ParseEnum(tokens)?)
        | "option"
            var option : (String ref, OptionType) = ParseOption(tokens)?
            if schema.options.contains(option._1) then
              error
            end
            schema.options(option._1) = option._2
        | "import" =>
          schema.extends.push(ParseExtend(tokens)?)
        | "service" =>
          schema.services.push(ParseService(tokens))
      else
        error
      end
      firstLine = false
    end

    for extend in schema.extends.values() do
      for message in schema.messages.values() do
        if message.name == extend.name then
          for field in extend.message.fields.values() do
            if (message.extensions.to == -1) or (message.extensions.from == -1)
              or (field.tagg < message.extension.from) or (field.tag > message.extensions.to) then
                error
            end
            message.fields.push(field)
          end
        end
      end
    end
    let enumNameIsFieldType = {(enums: Array[Enums], field: Field): Bool =>
      for enum in enums.values() do
        if enum.name == field.type then
          return true
        end
      end
      false
    } val
    let findMessage = {(messages: Array[Messages], messagName: String ref) (Message | None) =>
      for message in messages.values() do
        if message.name == messageName then
          return message
        end
      end
      None
    } val
    let enumNameIsNestedEnumName: = {(enums: Array[Enums], nestedEnumName: String ref): Bool =>
      for enum in enums.values() do
        if enum.name == nestedEnumName then
          return true
        end
      end
      false
    } val
    for message in schema.messages.values() do
      for field in message.fields.values() do
        if try field.options("packed")? == true else false end then
          if IsPackableType(field.type) then
            if not field.type.contains(".") then
              if enumNameIsFieldType(message.enums, field) then
                continue
              end
            else
              var fieldSplit: Array[String ref] = field.type.split(".")
              if fieldSplit.size() > 2 then
                error
              end
              let message': (Message | None) = findMessage(schema.message, fieldSplit(0)?)
              match message'
                | let message'' : Message =>
                  if enumNameIsNestedEnumName(message''.enums,fieldSplit(1)?) then
                    continue
                  end
              end
            end
            error
          end
        end
      end
    end
    return schema