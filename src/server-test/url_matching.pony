use "collections"
use "debug"
use "http_server"
use "logger"
use "net"
use "promises"
use "regex"
use "valbytes"

type ResponseBody is (String val | ByteArrays)

type ResponseType is ((Response val, ResponseBody) | ResponseBody | Status val) 


interface URLHandler
  fun apply(r: Request val, m: Match val, b: ByteArrays, p: Promise[ResponseType])


interface DefaultHandler
  fun apply(r: Request val, b: ByteArrays, p: Promise[ResponseType])


class ResponseHandler
  
  let session: Session
  let request_id: USize val

  new create(session': Session, request_id': USize val) =>
    session = session'
    request_id = request_id'

  fun _ensure_bytes(b: ResponseBody): ByteArrays =>
    match b
    | let b': ByteArrays => b'
    | let b': String => ByteArrays(b'.array())
    end

  fun apply(r: ResponseType val) =>
    """
    """
    Debug("Creating response")
    (let r': Response, let b: ByteArrays) = match r
    | (let response: Response, let body: ResponseBody) => (response, _ensure_bytes(body))
    | let body: ResponseBody =>
      let response = recover val BuildableResponse(StatusOK where content_length' = body.size()) end
      (response, _ensure_bytes(body))
    | let status: Status =>
      let body = status.string()
      let response = recover val BuildableResponse(status where content_length' = body.size()) end
      (response, _ensure_bytes(body))
    end
    Debug("Sending Response")
    session.send(r', b, request_id)
    Debug("Response sent")
    

class NotFoundHandler is DefaultHandler
  fun apply(r: Request val, b: ByteArrays, p: Promise[ResponseType]) =>
    Debug("Returning empty response")
    p(StatusNotFound)
  


actor URLRouter
  let routes: Array[(Regex val, URLHandler ref)] = Array[(Regex val, URLHandler ref)]
  var default_route: (DefaultHandler ref | None) = NotFoundHandler

  
  be add_route(regex: Regex val, handler: URLHandler iso) =>
    """
    """
    routes.push((regex, consume handler))

  be set_default_handler(handler: (DefaultHandler iso | None)) =>
    default_route = consume handler


  be handle_request(r: Request val, b: ByteArrays, p: Promise[ResponseType]) =>
    let path = r.uri().path
    Debug("Handling request for path: " + path)
    for (regex, handler) in routes.values() do
      Debug("Trying")
      try
        let m = recover val regex(path)? end
        handler(r, m, b, p)
        return
      end

    else
      Debug("Matching with the default route")
      match default_route
      | let handler: DefaultHandler => handler(r, b, p)
      | None => p(StatusNotFound)
      end
    end
    p(StatusNotFound)


class MySimpleHandler is Handler
  let _session: Session
  var _request: (Request | None) = None
  var _body: ByteArrays = ByteArrays
  var _server: MySimpleServer

  new create(server: MySimpleServer, session': Session) => 
    Debug("Handler was created")
    _session = session'
    _server = server

  fun ref apply(request: Request val, request_id: USize val) =>
    _request = request
    _body = ByteArrays
    Debug("Handler was applyed")

  fun ref chunk(data: ByteSeq val, request_id: USize val) =>
    Debug("Received chunk of size: " + data.size().string())
    _body = _body + data

  fun ref finished(request_id: USize val) =>
    Debug("Request finished")
    try
      let request: Request = _request as Request
      _server.handle_request(request, _body, request_id, _session)
    end

class MySimpleHandlerFactory is HandlerFactory
  let server: MySimpleServer

  new create(server': MySimpleServer tag) =>
    server = server'
    
  fun box apply(session: Session tag): Handler ref^ =>
    MySimpleHandler(server, session)

class MySimpleServerNotify is ServerNotify
  let _server: MySimpleServer

  new create(server: MySimpleServer) =>
    _server = server

class NoneLogger
  fun box apply(level: (Fine val | Info val | Warn val | Error val)): Bool =>
    false

  fun box log(msg: String val, loc: SourceLoc = __loc): Bool =>
    """
    """
    false

actor MySimpleServer
  let _router: URLRouter
  let _server: Server
  let _logger: (NoneLogger | Logger[String])

  new create(
    router': URLRouter,
    auth: TCPListenAuth,
    config: ServerConfig,
    logger: (None | Logger[String]) = None
  ) =>
    _router = router'
    _server = Server(auth, MySimpleServerNotify(this), MySimpleHandlerFactory(this), config)

    match logger
    | let logger': Logger[String] =>  _logger = logger'
    | None => _logger = NoneLogger
    end

  be handle_request(request: Request, body: ByteArrays, request_id: USize val, session: Session) =>
    _logger(Fine) and _logger.log(
      "Handling request with id: " + request_id.string()
    )

    let p = Promise[ResponseType]
    let handler = recover iso ResponseHandler(session, request_id) end

    p.next[ResponseType]({(r: ResponseType) => 
      Debug("Promise was fullfilled")
      r
    }).next[None](consume handler)

    _router.handle_request(request, body, p)
