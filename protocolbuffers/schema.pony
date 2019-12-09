use "collections"
use "json"

class Schema
  var package: String ref
  var version: USize
  var imports: Array[String ref]
  var enums: Array[Enum]
  var messages: Array[Message]
  var options: OptionMap
  var extends: Array[Extend]
  var services: Array[Service]

  new create(package': String ref = String, version': USize = 3, imports': Array[String ref] = Array[String ref], enums': Array[Enum] = Array[Enum], messages': Array[Message] = Array[Message], options': OptionMap = OptionMap, extends': Array[Extend] = Array[Extend], services': Array[Service] = Array[Service]) =>
    package = package'
    version = version'
    imports = imports'
    enums = enums'
    messages = messages'
    options = options'
    extends = extends'
    services = services'

  fun json() : JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("package") = package.string()
    json'.data("version") = version.f64()
    let importArr: Array[JsonType] = Array[JsonType](imports.size())
    for import in imports.values() do
      importArr.push(import.string())
    end
    json'.data("imports") = JsonArray.from_array(importArr)
    let enumArr: Array[JsonType] = Array[JsonType](enums.size())
    for enum in enums.values() do
      enumArr.push(enum.json())
    end
    json'.data("enum") = JsonArray.from_array(enumArr)
    let messageArr: Array[JsonType] = Array[JsonType](messages.size())
    for message in messages.values() do
      messageArr.push(message.json())
    end
    json'.data("messages") = JsonArray.from_array(messageArr)
    json'.data("options") = options.json()
    let extendArr: Array[JsonType] = Array[JsonType](extends.size())
    for extend in extends.values() do
      extendArr.push(extend.json())
    end
    json'.data("extends") = JsonArray.from_array(extendArr)
    let serviceArr: Array[JsonType] = Array[JsonType](services.size())
    for service in services.values() do
      serviceArr.push(service.json())
    end
    json'.data("services") = JsonArray.from_array(serviceArr)
    json'


class EnumValue
  var name: String ref
  var value: Value

  new create(name': String ref, value': Value) =>
    name = name'
    value = value'

class Enum
  var name: String ref
  var options: OptionMap
  var value: Map[String ref, Value]

  new create(name': String ref, options': OptionMap, value': Map[String ref, Value]) =>
    name = name'
    options = options'
    value = value'

  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
     json'.data("name") = name.string()
     json'.data("options") = options.json()
     //json'.data("value") = value.json()
     json'

class Value
  var value: U64
  var options: OptionMap
  new create (value': U64, options': OptionMap = OptionMap) =>
    value = value'
    options = options'

type OptionType is (F64 | I64 | Bool | None | String ref | OptionMap | OptionArray )


class OptionMap
  var data: Map[String ref, OptionType]
  new create (size: USize = 0) =>
    data = Map[String ref, OptionType](size)
  fun apply(key: String ref): this->OptionType ? =>
    data(key)?
  fun ref update(key: String ref, value: OptionType): (OptionType^ | None) =>
    data(key) = value
  fun contains(key: box->String!) : Bool =>
    data.contains(key)
  fun json() : JsonObject =>
    let json': JsonObject= JsonObject
    for pair in data.pairs() do
      json'.data(pair._1.string()) = match pair._2
        | let value: String box => value.string()
        | let value: OptionMap box => value.json()
        | let value: OptionArray box => value.json()
        | let value: F64 box => value.f64()
        | let value: I64 box => value.i64()
        | let value: Bool => value
      else
        None
      end
    end
    json'

class OptionArray
  var data: Array[OptionType]
  new create(size: USize = 0) =>
    data = Array[OptionType](size)
  fun apply(i: USize) : this->OptionType ? =>
    data(i)?
  fun ref update(i:USize, value: OptionType): (OptionType^ | None) ? =>
    data(i)? = value
  fun ref push(value: OptionType)  =>
    data.push(value)
  fun json(): JsonArray =>
    let arr: Array[JsonType] = Array[JsonType](data.size())
    for value in data.values() do
      arr.push(match value
        | let value': String box => value'.string()
        | let value': OptionMap box => value'.json()
        | let value': OptionArray box => value'.json()
        | let value': F64 box => value'.f64()
        | let value': I64 box => value'.i64()
        | let value': Bool => value'
      else
        None
      end)
    end
    JsonArray.from_array(arr)

class Service
  var name: String ref
  var methods: Array[RPC]
  var options: OptionMap
  new create(name': String ref = String, methods': Array[RPC] = Array[RPC], options': OptionMap = OptionMap) =>
    name = name'
    methods = methods'
    options = options'
  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("name") = name.string()
    let methodsArr: Array[JsonType] = Array[JsonType](methods.size())
    json'.data("methods") =  JsonArray.from_array(methodsArr)
    json'.data("options") = options.json()
    json'

class RPC
  var name: String ref
  var inputType: (String ref | None)
  var outputType: (String ref | None)
  var clientStreaming: Bool
  var serverStreaming: Bool
  var options: OptionMap
  new create(name': String ref = String, inputType': (String ref | None) = None, outputType': (String ref | None) = None, clientStreaming': Bool = false, serverStreaming': Bool = false, options': OptionMap = OptionMap) =>
      name = name'
      inputType = inputType'
      outputType = outputType'
      clientStreaming = clientStreaming'
      serverStreaming = serverStreaming'
      options = options'
  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("inputType") = match inputType
      | let inputType': String box => inputType'.string()
      | None => None
    end
    json'.data("outputType") = match outputType
      | let outputType': String box => outputType.string()
      | None =>  None
    end
    json'.data("clientStreaming") = clientStreaming
    json'.data("serverStreaming") = serverStreaming
    json'.data("options") = options.json()
    json'

class FieldMap
  var from: String ref
  var to: String ref
  new create(from': String ref = String, to': String ref = String) =>
    from = from'
    to = to'
  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("from") = from.string()
    json'.data("to") = from.string()
    json'
class Extension
  var from: ISize
  var to: ISize
  new create(from': ISize = -1, to': ISize = -1) =>
    from = from'
    to = to'

class Field
  var name: String ref
  var fieldType: String ref
  var fieldTag: ISize
  var map: FieldMap
  var oneof: String ref
  var required: Bool
  var repeated: Bool
  var options: OptionMap

  new create(name': String ref = String, fieldType': String ref = String, fieldTag': ISize = -1, map': FieldMap = FieldMap, oneof': String ref = String, required': Bool = false, repeated': Bool = false, options': OptionMap = OptionMap) =>
    name = name'
    fieldType = fieldType'
    fieldTag = fieldTag'
    map = map'
    oneof = oneof'
    required = required'
    repeated = repeated'
    options = options'

  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("name") = name.string()
    json'.data("fieldType") = fieldType.string()
    json'.data("fieldTag") = fieldTag.string()
    json'.data("map") = map.json()
    json'.data("oneof") = oneof.string()
    json'.data("required") = required
    json'.data("repeated") = repeated
    json'.data("options") = options.json()
    json'

class Message
  var name: String ref
  var enums: Array[Enum]
  var extends: Array[Extend]
  var messages: Array[Message]
  var fields: Array[Field]
  var extensions: Extension
  new create(name': String ref = String, enums': Array[Enum] = Array[Enum](0), extends': Array[Extend] = Array[Extend](0), messages': Array[Message]= Array[Message](0), fields': Array[Field] = Array[Field](0), extensions': Extension = Extension) =>
    name = name'
    enums = enums'
    extends = extends'
    messages = messages'
    fields = fields'
    extensions = extensions'
  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("name") = name.string()
    let enumArr: Array[JsonType] = Array[JsonType](enums.size())
    for enum in enums.values() do
      enumArr.push(enum.json())
    end
    json'.data("enums") = JsonArray.from_array(enumArr)
    let extendsArr: Array[JsonType] = Array[JsonType](enums.size())
    for extend in extends.values() do
      extendsArr.push(extend.json())
    end
    json'.data("extends") = JsonArray.from_array(extendsArr)
    let messagesArr: Array[JsonType] = Array[JsonType](messages.size())
    for message in messages.values() do
      messagesArr.push(message.json())
    end
    json'.data("messages") = JsonArray.from_array(messagesArr)
    let fieldsArr: Array[JsonType] = Array[JsonType](fields.size())
    for extend in extends.values() do
      extendsArr.push(extend.json())
    end
    json'.data("extends") = JsonArray.from_array(extendsArr)
    json'

class Extend
  var name: String ref
  var message: Message
  new create(name': String ref = String, message': Message = Message) =>
    name = name'
    message = message'
  fun json(): JsonObject =>
    let json': JsonObject = JsonObject
    json'.data("name") =  name.string()
    json'.data("message") = message.json()
    json'

class MessageBody
  var enums: Array[Enum]
  var messages: Array[Message]
  var fields: Array[Field]
  var extends: Array[Extend]
  var extensions: Extension
  new create(enums': Array[Enum] = Array[Enum](0), messages': Array[Message] = Array[Message](0), fields': Array[Field] = Array[Field], extends': Array[Extend] = Array[Extend](0), extensions': Extension = Extension) =>
    enums = enums'
    messages = messages'
    fields = fields'
    extends = extends'
    extensions = extensions'
