use ".."
use "files"
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(_TestTokens)

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
          let tokens: Array[String] = Tokenize(text)
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
