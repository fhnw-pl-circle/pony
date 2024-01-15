

class Vec3[A: Number val] is Stringable
  let x: A
  let y: A
  let z: A

  new create(x': A, y': A, z': A) =>
    x = x'
    y = y'
    z = z'

  fun box string(): String iso^ =>
    ("[ " + x.string() + "," + y.string() + "," + z.string() + "]").clone()


class val Twist[A: Number val] is Stringable
  let linear: Vec3[A]
  let angular: Vec3[A]

  new create(linear': Vec3[A], angular': Vec3[A]) =>
    linear = linear'
    angular = angular'

  fun box string(): String iso^ =>
    ("Linear: " + linear.string() + ", Angular: " + angular.string()).clone()
