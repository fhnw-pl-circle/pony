// TODO: Setup nodes and topics
//
//

class val RosEnv
  let vel: Topic[Twist[I32] val] = Topic[Twist[I32] val]
  let motor_log: Topic[Array[I32] val] = Topic[Array[I32] val]


actor Main
  new create(env: Env) =>
    env.out.print("Hello")
