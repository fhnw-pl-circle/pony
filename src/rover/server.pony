// Simple http server, that receives json and sends them to a topic
use "net"
use "http_server"
use "valbytes"



class MyServerNotify is ServerNotify
  new create() =>
    U32(1)


class MyHandler is Handler
  let _session: Session
  let _server: RoverServer
  var _path: String = ""
  var _body: ByteArrays = ByteArrays
  
  new create(session': Session, server': RoverServer) =>
    _server = server'
    _session = session'

  fun ref apply(request: Request val, id: RequestID) =>
    _path = request.uri().path

  fun ref chunk(data: ByteSeq val, request_id: RequestID) =>
    _body = _body + data

  fun ref finished(request_id: RequestID) =>
      _session.send_raw(
      Responses.builder()
        .set_status(StatusOK)
        .add_header("Content-Length", (_body.size() + _path.size() + 13).string())
        .add_header("Content-Type", "text/plain")
        .finish_headers()
        .add_chunk((_body = ByteArrays).array())
        .add_chunk(_path.array())
        .build(),
      request_id
    )
    _session.send_finished(request_id)
    

class MyHandlerFactor is HandlerFactory
  let server: RoverServer
  new create(server': RoverServer tag) =>
    server = server'


  fun box apply(session: Session tag): Handler ref^ =>
    MyHandler(session, server)

actor RoverServer
  let server: Server
  new create(auth: TCPListenAuth, config: ServerConfig) =>
    server = Server(auth, MyServerNotify, MyHandlerFactor(this), config)

