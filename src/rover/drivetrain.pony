// TCP Listener that sends received speed to the motor driver

use "net"
use "serialise"

class DriveTrainConnectionNotifiy is TCPConnectionNotify
    let node: DriveTrainNode

    new create(node': DriveTrainNode tag) =>
      node = node'
  
    fun ref connected(conn: TCPConnection ref) =>
      node.connected()

    fun ref received(
      conn: TCPConnection ref,
      data': Array[U8] iso,
      times: USize)
      : Bool
    =>
      let data = recover val consume data' end
      node.received(data)
      true

    fun ref connect_failed(conn: TCPConnection ref) =>
      node.connect_failed()

    fun ref closed(conn: TCPConnection ref) =>
      node.closed()


actor DriveTrainNode
  let conn: TCPConnection
  let env: RosEnv val
  var _connected: Bool = false
  
  new create(auth: TCPConnectAuth, env': RosEnv val) =>
    env = env'
    conn = TCPConnection(auth, recover DriveTrainConnectionNotifiy(this) end, "", "8989")

    let node = recover tag this end

    env.vel.subscribe(object
        be apply(twist: Twist[I32] val) =>
          node.on_twist(twist)
      end
    )
    

  be on_twist(twist: Twist[I32] val) => 
    if not _connected then
      return
    end

    let speed_forward = twist.linear.x.max(1000)

    let speed_right = twist.linear.x + twist.angular.z
    let speed_left = twist.linear.x - twist.angular.z

    send_motor_speed(speed_left, speed_right)

  fun _convert_to_byte(value: I32): Array[U8] val =>
    let arr: Array[U8] iso = Array[U8](value.bytewidth())
    arr.push((value >> 24).u8())
    arr.push((value >> 16).u8())
    arr.push((value >> 8).u8())
    arr.push(value.u8())
    consume arr

  fun _convert_from_byte(arr: Array[U8]): I32 val ? =>
    if arr.size() != 4 then
      error
    end

    var value: I32 = 0
    value = value or (arr(0)?.i32() << 24)
    value = value or (arr(1)?.i32() << 16)
    value = value or (arr(2)?.i32() << 8)
    value = value or arr(3)?.i32()
    value

  fun send_motor_speed(left: I32, right: I32) =>
    let left_bytes = _convert_to_byte(left)
    let right_bytes = _convert_to_byte(right)

    let data: Array[U8] iso = recover iso
      let data = Array[U8].init(0, 5 * 4)

      data.copy_from[U8](left_bytes, 0, 0, 4)
      data.copy_from[U8](left_bytes, 0, 4, 4)
      data.copy_from[U8](right_bytes, 0, 0, 4)
      data.copy_from[U8](right_bytes, 0, 4, 4)

      data
    end

    conn.write(consume data)

  be connected() =>
    _connected = true

  be received(data: Array[U8] val) =>
    var idx = USize(0)
    let numbers = recover trn Array[I32](15) end

    while (idx + 4) < data.size() do
      let slice = data.slice(idx, idx + 4)
      let number = try _convert_from_byte(slice)? else I32(-1) end
      numbers.push(number)
    end

    env.motor_log.publish(consume numbers)

  be connect_failed() =>
    U32(1)

  be closed() =>
    _connected = false
