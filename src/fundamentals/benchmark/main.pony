use "time"
use "collections"
use "math"
use "pony_bench"

actor Main is BenchmarkList

  new create(env: Env) =>
    PonyBench(env, this)

  fun tag benchmarks(bench: PonyBench) => ""
    bench(_DefaultMathInt)
    bench(_UnsafeMathInt)
    bench(_PartialMathInt)
    bench(_CheckedMathInt)

    bench(_DefaultMathFloating)
    bench(_UnsafeMathFloating)


class iso _DefaultMathFloating is MicroBenchmark

  fun name(): String => "default math F64"

  fun apply() =>
    DoNotOptimise[F64](_div(12412000.0, 2.0))
    DoNotOptimise.observe()

  fun _div(a: F64, b: F64): F64 =>
    var a' = a
    for i in Range[USize](0, 1000) do
      a' = a' / b
    end
    a'

class iso _UnsafeMathFloating is MicroBenchmark

  fun name(): String => "unsafe math F64"

  fun apply() =>
    DoNotOptimise[F64](_div(12412000.0, 2.0))
    DoNotOptimise.observe()


  fun _div(a: F64, b: F64): F64 =>
    var a' = a
    for i in Range[USize](0, 1000) do
      a' = a' /~ b
    end
    a'


class iso _DefaultMathInt is MicroBenchmark

  fun name(): String => "default math U64"

  fun apply() =>
    DoNotOptimise[U64](_div(12412000, 2))
    DoNotOptimise.observe()

  fun _div(a: U64, b: U64): U64 => 
    var a' = a
    for i in Range[USize](0, 1000) do
      a' = a' / b
    end
    a'


class iso _UnsafeMathInt is MicroBenchmark

  fun name(): String => "unsafe math U64"

  fun apply() =>
    DoNotOptimise[U64](_div(12412000, 2))
    DoNotOptimise.observe()

  fun _div(a: U64, b: U64): U64 => 
    var a' = a
    for i in Range[USize](0, 1000) do
      a' = a' /~ b
    end
    a'

class iso _PartialMathInt is MicroBenchmark

  fun name(): String => "partial math U64"

  fun apply() =>
    DoNotOptimise[U64](_div(12412000, 2))
    DoNotOptimise.observe()

  fun _div(a: U64, b: U64): U64 => 
    var a' = a
    for i in Range[USize](0, 1000) do
      try
        a' = a' /? b
      else
        a' = 0
      end
    end
    a'

class iso _CheckedMathInt is MicroBenchmark

  fun name(): String => "checked math U64"


  fun apply() =>
    DoNotOptimise[U64](_div(12412000, 2))
    DoNotOptimise.observe()

  fun _div(a: U64, b: U64): U64 => 
    var a' = a
    for i in Range[USize](0, 1000) do
      match a'.divc(b)
      | (let r: U64, false) => a' = r
      else
        a' = 0
      end
    end
    a'
