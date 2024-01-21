// This file contains examples for the following langauge features of pony

// - interfaces and traits, subtyping
// - generics
// - simple actor
// - reference capabilities
// - consume, recover
// - viewpoint adaption
// - file access with object capabilities
// - error handling
// - partial application
// - with statement
// - object literals
// - maths
// - c-ffi
// - networking
//

// Use statements need to be at the top
use "collections"
use "debug"
use "files"
use "http"
use "json"
use "net"
use "promises"
use "serialise"
use "math"
use "cli"


use @printf[I32](fmt: Pointer[U8] tag, ...)

use "lib:curl" if linux or osx
// these booleans are available at compile time:
// windows, freebsd, osx, posix, x86, arm, lp64, llp64, ilp32, native128, debug

use @curl_version[Pointer[U8]]()
use @curl_easy_init[Pointer[_CURL]]()
use @curl_easy_setopt[U8](curl: Pointer[_CURL], option: U16, ...)
use @curl_easy_perform[U8](curl: Pointer[_CURL])

actor Main
  new create(env: Env) =>
    let cs = 
      try
        let parent = CommandSpec.parent("examples")?
        for name in [
          "typing"; "reference-caps"; "object-caps"; "errors"
          "object-literals"; "maths"; "c-ffi"; "network"
          "serialize"; "debug"; "methods"
          ].values() do
          parent.add_command(
            CommandSpec.leaf(name)?
          )?
        end
        parent.>add_help()?
      else
        env.exitcode(-1)
        return
      end

    let cmd =
      match CommandParser(cs).parse(env.args, env.vars)
      | let c: Command => c
      | let ch: CommandHelp =>
          ch.print_help(env.out)
          env.exitcode(0)
          return
      | let se: SyntaxError =>
          env.out.print(se.string())
          env.exitcode(1)
          return
      end

    match cmd.spec().name()
      | "typing" => TypingExample(env)
      | "reference-caps" => ReferenceCapsExample(env)
      | "object-caps" => ObjectCapsExample(env)
      | "errors" => ErrorExample(env)
      | "object-literals" => ObjectLiteralExample(env)
      | "maths" => MathsExample(env)
      | "methods" => MethodPassing(env)
      | "c-ffi" => CFFIExample(env)
      | "network" => NetworkExample(env)
      | "serialize" => SerializationExample(env)
      | "debug" => DebugExample(env)
    end


class Foo
  let x: U32
  var z: U32
  
  new create(x': U32, z': U32) =>
    x = x'
    z = z'

  fun calc_stuff(a: U32): U32 =>
    takes_stuff(x)
    if a > 8 then
       7
    else
       a * x * z
    end

  fun takes_stuff(a: (U32 | String | None)) =>
    """
    """

  fun takes_generic[A](a: A)  =>
    """
    """


actor Actor 
  let env: Env

  new create(env': Env) =>
    env = env'

  be do_stuff(x: U32 val) =>
    env.out.print("I got: " + x.string())

// interfaces can be used for nominal and structural subtyping

class Bar is Stringable
  // Compiler generates an error if we don't provide this method
  fun string(): String iso^ => "Hello".clone()


  // Operator overloading
  fun add(other: OtherBar): OtherBar =>
    OtherBar


class OtherBar
  // Still a "Stringable", but no compiler error if we forget it
  fun string(): String iso^ => "Hello".clone()


trait Named
  // Traits can provide default implementations, and use
  // methods implemented by the subtype
  fun greeting(): String => "Hello, my name is " + name()

  fun name(): String


class Tom is Named
  fun name(): String => "Tom"

class NotNamed
  fun greeting(): String => "Hi!"

  fun name() => "no-name"

// Open world typing
trait Color

primitive Red is Color
primitive Blue is Color

primitive Green is Color

// Closed world typing

primitive Left
primitive Right

type Direction is (Left | Right)

class TypingExample

  fun greet(o: Named box, out: OutStream) =>
    out.print(o.greeting())

  fun print(o: Stringable box, out: OutStream) =>
    out.print(o.string())

  fun takes_color(c: Color box) =>
    U32(1)

  fun takes_direction(d: Direction box) =>
    U32(1)

  fun apply(env: Env) =>
    let f = recover val Foo(1, 3) end
    f.takes_stuff(U32(1))

    f.takes_generic[U32](U32(1))
    f.takes_generic[String iso]("Hallo".clone())
    f.takes_generic[String]("Hallo")

    let a: Bar = Bar
    print(a, env.out)

    let b: OtherBar = OtherBar
    print(b, env.out)

    let ab = a + b

    let c: Tom ref = Tom
    greet(c, env.out)

    let d: NotNamed ref = NotNamed
//    greet(d, env.out)
//
    let green = Green
    takes_color(green)

    let left = Left
    takes_direction(left)
    //taker_color(left)

// Reference capabilities

class ref Sample
var x: String iso

  new ref create() =>
    x = "Hello".clone()

  fun ref replace(x': String iso) =>
    let z: String ref = x = consume x'

class ReferenceCapsExample
  fun needs_val(s: String val) =>
    s

  fun needs_iso(s: String iso) =>
    s

  fun needs_ref(s: String ref) =>
    s

  fun needs_box(s: String box) =>
    s

  fun needs_tag(s: String tag) =>
    s

  fun apply(env: Env) =>
    let s1 = "This is val"
    var s2: String iso = "This is iso".clone()

    let s3: String ref = "This is a reference".clone()

    needs_val(s1)
//    needs_val(s3)

      // This is not allowed, because we can't guarantee that
      // s2 will not change, but val needs this guarantee
//    needs_val(s2)
//    This works:
    needs_val(consume s2)

  
  // But no s2 isn't usable anymore
    s2 = "This is iso".clone()

    // needs_iso(s2) -- This is not enough!
    needs_iso(consume s2)
    // s2 not available anymore, until we provide a new value
    s2 = "This is iso".clone()
    //
    // Tis does not work, since val means that many other actors could
    // be reading this, we have now way of converting val to is in this
    // context!
    // needs_iso(s1)
    
    // needs_ref(s1) -- Not possible, since s1 is val and could be read in other places!
    needs_ref(consume s2) // s2 can be consumed and converted into a ref!
    needs_ref(s3)

    // Anything can be used as a tag!
    needs_tag(s1)
    s2 = "This is iso".clone()
    needs_tag(s2)
    needs_tag(s3)

    // Box: For read only access
    needs_box(s1)
    needs_box(s3) // s3 is a refernce but method will only use it to read

    s2 = "This is iso".clone()
    // needs_box(s2)

    let x1 = Sample
    // let x2: Sample iso = Sample
    let x2' = recover iso Sample end
    // let x3: Sample val = Sample
    
    let s4: String trn = "This is trn".clone()
    try
      needs_box(s4)
      s4.update(1, 'c')?
      needs_val(consume s4)
    end

    x1.replace("World".clone())

class ObjectCapsExample
  fun apply(env: Env) =>
    let file_name = "hello.txt"
    // env.root: AmbientAuth
    let path = FilePath(FileAuth(env.root), file_name)

    match OpenFile(path)
    | let file: File =>
      while \likely\ file.errno() is FileOK do
        env.out.write(file.read(1024))
      end
    else
      env.err.print("Error opening file '" + file_name + "'")
    end

class ObjectLiteralExample
  fun apply(env: Env) =>
    let obj = object
      fun hello(): String => "Hallo!"
      fun apply(): String => "Welt"
    end

    let a = obj.hello()
    let b = obj()

    let act = object
      be do_stuff(out: OutStream) => out.print("Hello actor")
    end

    act.do_stuff(env.out)

    let l = {(a: String, out: OutStream) => out.print("Lambda: " + a)}

    let l2 = object
      fun apply(a: String, out: OutStream) => out.print("Lambda" + a)
    end

    l("Hallo", env.out)


class MethodHandler
  fun print(out: OutStream, f: {ref(U32): String}) =>
    out.print(f(12))

  fun double_print(out: OutStream, f: {ref(U32, F32): String}) =>
    out.print(f(1, 2.0))


class MethodProvider
  fun double(x: U32): String val =>
    (x * 2).string()

  fun multiple(x: U32, y: U32): String val=>
    (x * y).string()

  fun divide(x: U32, y: U32): String val =>
    (x / y).string()


class MethodPassing
  fun apply(env: Env) =>

    let handler = recover ref MethodHandler end
    let provider = recover val MethodProvider end

    handler.print(env.out, provider~double())
    handler.print(env.out, provider~multiple(12))

    handler.print(env.out, provider~multiple(where x = 1))
    handler.print(env.out, provider~multiple(where y = 13))

class Disposable

  let out: OutStream

  new create(out': OutStream) =>
    out = out'

  fun apply()? =>
    out.print("Hello, World!")
    error
  
  fun dispose() =>
    out.print("Goodby, World!")


class ErrorExample
  fun good_luck(a: U32): U32? =>
    if a == 13 then
      error
    else
      a * 2
    end

  fun apply(env: Env) =>
    try
      good_luck(13)?
    else
      env.out.print("That didn't work...")
    end

    try with d = Disposable(env.out) do
        d()?
      end
      else
        env.out.print("This failed...")
      then
        env.out.print("This is always printed")
    end


class MathsExample
  fun apply(env: Env) =>
    env.out.print("Default Arithmetic")
    let x = U32(1) / U32(0)
    env.out.print("1 / 0 = " + x.string())

    var y = U32.max_value() + 1
    env.out.print("Max + 1 = " + y.string())

    y = U32.min_value() - 1
    env.out.print("Min - 1 = " + y.string())

    env.out.print("Unsafe Arithmetic")
    // Unsafe Integer Arithmetic
    let x' = U32(1) /~ U32(0)
    env.out.print("1 /~ 0 = " + x.string())

    y = U32.max_value() +~ 1
    env.out.print("Max + 1 = " + y.string())

    y = U32.min_value() -~ 1
    env.out.print("Min - 1 = " + y.string())

    // Checked Arithmetic
    match U32(1).divc(0)
      | (let result: U32, false) => env.out.print("Success: " + result.string())
      | (_, true) => env.out.print("Error!")
    end

    // Partial Arithmetic
    try
      let x'' = U32(1) /? 0
      env.out.print("1 /? = " + x''.string())
    else
      env.out.print("Error while dividing")
    then
      env.out.print("Done with partials!")
    end

    // Fibonacci 
    env.out.print("Fibonacci(10) = " + Fibonacci(10).string())

    // GCD
    env.out.print("GCD(42, 12) = " + try GreatestCommonDivisor[I64](42, 12)?.string() else "??" end)

type Record is (F64 val | I64 val | Bool val | None val | String val | JsonArray ref | JsonObject ref)

class NetworkExample
  fun apply(env: Env) =>
    let client = NetworkClient(TCPConnectAuth(env.root))

    let url = try
      URL.build("https://echo.sacovo.ch")?
    else
      return
    end
    
    let p1 = Promise[Payload val]

    p1.next[Array[ByteSeq] val](ToBody)
      .next[None](PrintBody(env.out))

    client.get(url, p1)

    let p2 = Promise[Payload val]

    p2.next[Payload val]({(p: Payload val) => 
        env.out.print("Received second payload:\n\n")
        p
      })
      .next[Array[ByteSeq] val]({(p: Payload val)? => recover val p.body()?.clone() end})
      .next[None](({(a: Array[ByteSeq] val) => 
        for line in a.values() do
          env.out.print(line)
        end
      }))

      
    let x = recover iso HashMap[String val, Record, HashEq[String val] val].create() end

    x("key") = "value"

    let obj: JsonObject iso = recover iso JsonObject.from_map(consume x) end

    client.post(url, consume obj, p2)

class ToBody
  fun apply(p: Payload val): Array[ByteSeq] val? =>
    recover val p.body()?.clone() end


class PrintBody
  let out: OutStream

  new create(out': OutStream) =>
    out = out'

  fun apply(a: Array[ByteSeq] val) =>
    for line in a.values() do
      out.print(line)
    end


class MyHandlerFactory is HandlerFactory
  let promise: Promise[Payload val]

  new create(promise': Promise[Payload val]) =>
    promise = promise'

  fun box apply(session: HTTPSession tag): HTTPHandler ref^ =>
    MyHandler(promise, session)


class MyHandler is HTTPHandler
  let promise: Promise[Payload val]
  let session: HTTPSession

  new create(promise': Promise[Payload val], session': HTTPSession) =>
    promise = promise'
    session = session'
  
  fun ref apply(payload: Payload val): None tag =>
    promise(payload)
    

actor NetworkClient
  let auth: TCPConnectAuth

  new create(auth': TCPConnectAuth) =>
    auth = auth'

  be get(url: URL, promise: Promise[Payload val]) =>
    let client = HTTPClient.create(auth)

    try
      let payload = Payload.request("GET", url)
      payload.update("My-Header", "This is a test header!")
      client.apply(consume payload, MyHandlerFactory(promise))?
    else
      promise.reject()
    end

  be post(url: URL, obj: JsonObject iso, promise: Promise[Payload val]) =>
    let client = HTTPClient.create(auth)

    try
      let payload = Payload.request("POST", url)
      payload.update("My-Header", "This is a test header!")

      let doc = JsonDoc
      doc.data = consume obj
      payload.add_chunk(doc.string())

      client.apply(consume payload, MyHandlerFactory(promise))?
    else
      promise.reject()
    end

// C-FFI

primitive _CURL
primitive _CURLcode

class CFFIExample

  fun apply(env: Env) =>

    let a: F32 = 3.1
    let b: U32 = 2

    @printf("A: %f, B: %d\n".cstring(), a, b)

    let v: String val = String.from_cstring(@curl_version()).clone()
    env.out.print(v)

    let curl = @curl_easy_init()

    var r = @curl_easy_setopt(curl, 10000 + 2, "https://echo.sacovo.ch".cstring())

    if r != 0 then
      env.out.print("Failed to set url")
      return
    end

    r = @curl_easy_setopt(curl, 20000 + 11, addressof this.callback)

    if r != 0 then
      env.out.print("Failed to setup callback")
      return
    end

    r = @curl_easy_perform(curl)

  fun @callback(buffer: Pointer[U8], size: USize, nmemb: USize, userp: Pointer[None]) => 
    @printf("Hello from the callback!\n".cstring())
    @printf("%s".cstring(), buffer)


class SerializationExample
  fun apply(env: Env) =>
    let serialise = SerialiseAuth(env.root)
    let output = OutputSerialisedAuth(env.root)

    let x = U32(124)
    let sfoo = try Serialised(serialise, x)?
      else
        return
    end

    let bytes: Array[U8] val = sfoo.output(output)

    for byte in bytes.values() do
      env.out.print("B: " + byte.string())
    end


class DebugExample

  fun debug_test() =>
    Debug.out("This is only printed when compiled with --debug")

  fun apply(env: Env) =>
    debug_test()
    env.out.print("This is always printed")
    
