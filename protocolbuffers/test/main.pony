use ".."
use "files"
use "ponytest"
use "logger"
use "json"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    //test(_TestTokens)
    //test(_TestParsing)
    test(_TestCompiling)

class iso _TestTokens is UnitTest
  fun name(): String => "Testing Tokens"
  fun apply(t: TestHelper) =>
    let testTokens = [
      "message"
      "Point"
      "{"
      "required"
      "int32"
      "x"
      "="
      "1"
      ";"
      "required"
      "int32"
      "y"
      "="
      "2"
      ";"
      "optional"
      "string"
      "label"
      "="
      "3"
      ";"
      "}"
      "message"
      "Line"
      "{"
      "required"
      "Point"
      "start"
      "="
      "1"
      ";"
      "required"
      "Point"
      "end"
      "="
      "2"
      ";"
      "optional"
      "string"
      "label"
      "="
      "3"
      ";"
      "}"
      "message"
      "A"
      "{"
      "}"
    ]
    try
      let path: FilePath = FilePath(t.env.root as AmbientAuth, "protocolbuffers/test/fixtures/comments.proto")?
      match CreateFile(path)
      | let file: File =>
          let text: String ref = recover ref file.read_string(file.size()) end
          let tokens: Array[String ref] = Tokenize(text)
          var i : USize = 0
          if tokens.size() != testTokens.size() then
            t.fail("Invalid Token Count")
          end
          try
            while i < tokens.size() do
              t.assert_true(tokens(i)? == testTokens(i)?)
              i = i + 1
            end
          else
            t.fail("Token Error")
            t.complete(true)
          end
        | FileError =>
          t.fail("File Error")
          t.complete(true)
      end
    else
      t.fail("File Error")
      t.complete(true)
    end
class _TestParsing is UnitTest
  fun name (): String => "Testing Parser"
  fun apply(t: TestHelper) =>
    t.long_test(1000000000)
    try
      let path: FilePath = FilePath(t.env.root as AmbientAuth, "protocolbuffers/test/proto/test_repeated_enum.proto")?
      match CreateFile(path)
      | let file: File =>
          let text: String ref = recover ref file.read_string(file.size()) end
          let logger : Logger[String] = StringLogger(Error, t.env.out)
          try
            let schema: Schema = Parse(text, logger)?
            t.complete(true)
          else
            t.fail("Parsing Error")
            t.complete(true)
          end
        | FileError =>
          t.fail("File Error")
          t.complete(true)
      end
    else
      t.fail("File Error")
      t.complete(true)
    end

class _TestCompiling is UnitTest
  fun name (): String => "Testing Compiling"
  fun apply(t: TestHelper) =>
    t.long_test(1000000000)
    try
      let path: FilePath = FilePath(t.env.root as AmbientAuth, "protocolbuffers/test/fixtures/enum.proto")?
      match CreateFile(path)
      | let file: File =>
          let text: String ref = recover ref file.read_string(file.size()) end
          let logger : Logger[String] = StringLogger(Error, t.env.out)
          try
            let schema: Schema = Parse(text, logger)?
            let doc = JsonDoc
            doc.data = schema.json()
            //t.log(doc.string("  ", true))
            //t.fail()
            let path': FilePath = FilePath(t.env.root as AmbientAuth, "./build/compiled/")?
            path'.mkdir()
            Compile(schema, path')?
            //t.fail()
            t.complete(true)
          else
            t.fail("Parsing Error")
            t.complete(true)
          end
        | FileError =>
          t.fail("File Error")
          t.complete(true)
      end
    else
      t.fail("File Error")
      t.complete(true)
    end
