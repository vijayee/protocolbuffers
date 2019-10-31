use "collections"

class Schema
  var package: String ref
  var version: USize
  var imports: Array[String ref]
  var enums: Array[Enum]
  var messages: Array[Message]
  var options: OptionMap
  var extends: Array[Extend]
  
  new create(package': String ref = String, version': USize = 0, imports': Array[String ref] = Array[String ref], enums': Array[Enum] = Array[Enum], messages': Array[Message] = Array[Message], options': OptionMap = OptionMap, extends': Array[Extend] = Array[Extend]) =>
    package = package'
    version = version'
    imports = imports'
    enums = enums'
    messages = messages'
    options = options'
    extends = extends'

class EnumValue
  var name: String ref
  var value: Value

  new create(name': String ref, value': Value) =>
    name = name'
    value = value'

class Enum
  var name: Sring ref
  var options: OptionMap
  var value: OptionMap

  new create(name': String ref, options': OptionMap, value': OptionMap) =>
    name = name'
    options = options'
    value = value'

class Value
  var value: U64
  var options: OptionMap
  new create (value': U64, options': OptionMap = OptionMap]) =>
    value = value'
    options = options'

type OptionType is (F64 | I64 | Bool | None | String ref | OptionMap | OptionArray )

class OptionMap
  var data: Map[String ref, OptionType]
  new create (size: USize = 0) =>
    data = Map[String, OptionType](size)
  fun apply(key: String ref): this->OptionType ? =>
    data(key)?
  fun ref update(key: String ref, value: OptionType): (OptionType^ | None) =>
    data(key) = value
  fun contains(key: box->String!) : Bool
    data.contains(key)

class OptionArray
  var data: Array[OptionType]
  new create(size: USize = 0) =?
    data = new Array[OptionType](size)
  fun apply(i: USize) : this->OptionType ? =>
    data(i)?
  fun ref update(i:USize, value: OptionType) (OptionType^ | None) ? =>
    data(i)? = value
  fun ref push(value: OptionType) =>
    data.push(value)

class Service
  var name: String ref
  var methods: Array[RPC]
  var options: OptionMap
  new create(name': String ref = String, methods': Array[RPC] = Array[RPC], options' = OptionMap) =>
    name = name'
    methods = methods'
    options = options'

class RPC
  var name: String ref
  var inputType: (String ref | None)
  var outputType: (String ref | None)
  var clientStreaming: Bool
  var serverStreaming: Bool
  var options: OptionMap
  new create(name': String ref = String, inputType': (String ref | None) = None, outputType': (String ref | None) = None, clientStreaming': Bool = false, serverStreaming': Bool = false, options: OptionMap = OptionMap) =>
      name = name'
      inputType = inputType'
      outputType = outputType'
      clientStreaming = clientStreaming'
      serverStreaming = serverStreaming'
      options = options'

class FieldMap
  var from: String ref
  var to: String ref
  new create(from': String ref = String, to': String ref = String) =>
    from = from'
    to = to'

class Extension
  var from: ISize
  var to: ISize
  new create(from': ISize = -1, to': ISize = -1) =>
    from = from'
    to = to'

class Field
  var name: String ref
  var type: String ref
  var tagg: ISize
  var map: FieldMap
  var required: false
  var repeated: false
  var options: OptionMap

  new create(name': String ref = String, type': String ref = String, tagg': ISize = -1, map': FieldMap = FieldMap, required': Bool = false, repeated': false, options': OptionMap) =>
    name = name'
    type = type'
    tagg = tagg'
    map = map'
    reqired = required'
    repeated = repeated'
    options = options'

class Message
  name: String ref
  enums: Array[Enum]
  extends: Array[Extend]
  messages: Array[Message]
  fields: Array[Field]
  new create(name': String ref = String, enums': Array[Enum] = Array[Enum](0), extends': Array[Extend] = Array[Extend](0), messages': Array[Message]= Array[Message](0), fields': Array[Field] = Array[Field](0)) =>
    name = name'
    enums = enums'
    extends = extends'
    messages = messages'
    fields = fields'

class Extend
  name: String ref
  message: Message
  new create(name': String ref = String, message': Message = Message) =>
    name = name'
    message = message'

class MessageBody
  var enums: Array[Enum]
  var messages: Array[Message]
  var fields: Array[Field]
  var extends: Array[Extend]
  var extensions: Array[Extension]
