
use "pony_test"


actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(MyTest)

class iso MyTest is UnitTest
  fun name(): String => "my-test"

  fun apply(h: TestHelper) =>
    let s = "Hallo"
    h.assert_eq[String]("Hallo", s)
