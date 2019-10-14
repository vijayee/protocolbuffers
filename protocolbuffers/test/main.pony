use ".."
use "files"
use "regex"
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
    try
      let path: FilePath = FilePath(t.env.root as AmbientAuth, "protocolbuffers/test/proto/test_message.proto")?
      match CreateFile(path)
      | let file: File =>
          let text: String = recover file.read_string(file.size()) end
          try
            let getToken : GetToken = GetToken(t)?
            let tokens: MatchIterator = getToken(text)
            for token in tokens do
              for group in token.groups().values() do
                if (group.size() > 0) then
                  t.log(group)
                end
                t.log(group)
              end
            end
            t.fail("true")
          else
            t.fail("Regex Error")
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
