
// Simple http server, that receives json and sends them to a topic
use "net"
use "time"
use "http_server"
use "valbytes"
use "debug"
use "promises"
use "format"

use "regex"


actor App
  var _counter: USize = 0

  be hello(r: Request val, m: Match val, b: ByteArrays, p: Promise[ResponseType]) =>
    Debug("Called hello")
    p("Hello World!")

  be echo(r: Request val, m: Match val, b: ByteArrays, p: Promise[ResponseType]) =>
    Debug("Called echo")
    p(b)

  be count(r: Request val, m: Match val, b: ByteArrays, p: Promise[ResponseType]) =>
    Debug("Called count")
    _counter = _counter + 1
    p(_counter.string())

actor Main
  new create(env: Env) =>
    let config = ServerConfig("localhost", "8080")
    
    let app = App

    let router = URLRouter
    try
      router.add_route(Regex("^\\/hello\\/")?, app~hello())
      router.add_route(Regex("^\\/echo\\/")?, app~echo())
      router.add_route(Regex("^\\/count\\/")?, app~count())
    end

    let server = MySimpleServer(router, TCPListenAuth(env.root), config)



class MyServerNotify is ServerNotify
  new create() =>
    U32(1)


class MyHandler is Handler
  let _session: Session
  let _server: MyServer
  var _path: String = ""
  var _body: ByteArrays = ByteArrays
  var _closed: Bool = false
  
  new create(session': Session, server': MyServer) =>
    _server = server'
    _session = session'
    Debug("Created handler")

  fun ref apply(request: Request val, id: RequestID) =>
    Debug("Apply was called")
    _path = request.uri().path
    _server.inc()

  fun ref chunk(data: ByteSeq val, request_id: RequestID) =>
    Debug("Received chunk")
    _body = _body + data

  fun ref closed() =>
    _closed = true

  fun ref finished(request_id: RequestID) =>
    Debug("Finished!")
    let p = Promise[U32]

    p.next[None]({(d: U32) => 
      let msg: String val = d.string() + "\n"
      _session.send_raw(
        Responses.builder()
          .set_status(StatusOK)
          .add_header("Content-Type", "text/event-stream")
          .finish_headers()
          .add_chunk(msg.array())
          .add_chunk((_body = ByteArrays).array())
          .add_chunk(_path.array())
          .build(),
        request_id
      )
      Debug("Sent finish")
    })

    let timers = Timers
    let notify: TimerNotify iso = object iso is TimerNotify
      let _closed: Bool = false

      fun apply(timer: Timer, count: U64): Bool =>
        let s = _session
        let r = request_id
        let x = Promise[U32]

        x.next[None]({(d: U32) => 
          let msg: String val = d.string() + "\n"
          s.send_chunk(msg, r)
          Debug("Sent count:" + msg)
        })
        _server.get_count(x)
        true
    end
    let timer = Timer(consume notify, 1_000_000_000, 1_000_000_000)

    timers(consume timer)
    _server.get_count(p)
    

class MyHandlerFactor is HandlerFactory
  let server: MyServer
  new create(server': MyServer tag) =>
    server = server'


  fun box apply(session: Session tag): Handler ref^ =>
    MyHandler(session, server)

actor MyServer
  let server: Server

  var a: U32 = U32(0)

  new create(auth: TCPListenAuth, config: ServerConfig) =>
    server = Server(auth, MyServerNotify, MyHandlerFactor(this), config)

  be inc() =>
    a = a + 1

  be get_count(p: Promise[U32]) =>
    p(a)
