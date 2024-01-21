# pony

Intro to pony, an "object-oriented, actor-model, capabilities-secure, high-performance programming language".


## Important links

- [Homepage](https://www.ponylang.io/)
- [Tutorial](https://tutorial.ponylang.io/): Introduction of the most important concepts
- [Playground](https://playground.ponylang.io/)
- [Patterns](https://patterns.ponylang.io/): Collection of some common practices when programming in pony
- [Zulip](https://ponylang.zulipchat.com/): Community chat to get quick support
- [GitHub](https://github.com/ponylang/): Source for the compiler, standard library and some additional packages

## Setup

Recommended via [ponyup](https://github.com/ponylang/ponyup) and [corral](https://github.com/ponylang/corral) as dependency manager.

```bash
ponyup update ponyc release
ponyup update corral release

# To setup a new project
mkdir project/
cd project
corral init

# To add packages
corral add github.com/ponylang/http.git --version 0.5.5
corral fetch

# To compile current folder
ponyc 

# Compile with debug options, options and dependencies
corral run -- ponyc -Dopenssl_3.0.x --debug --output build/ src/project
```
## Language Fundamentals

### Type system

- class, actor, struct, primitives
- interfaces and traits, nominal and structural subtyping
- type aliases, type matching
- generics

### Reference capabilities

- The different Capabilities and their guarantees
- Consume and recover, ephemeral types
- Viewpoint adaption

### Object capabilities

- Restrict access to system resources
- No globals like stdin, stdout, args, ...
- Hierarchy

### Error handling
- partial application
- try else end
- resource management with

### Testing
- Unit testing with PonyTest
- Property testing with PonyCheck

### [Standard library](https://stdlib.ponylang.io/) and important packages
- collections: Heap, Map, Set, List, Flags
- collections/persistent: persistent data structures
- net: TCP-connections, DNS, ..., [http](https://ponylang.github.io/http/) and [http_server](https://ponylang.github.io/http_server/) are separate packages
- promises: chainable handlers for values that are available later


### Pony Runtime arguments

To specify settings for the underlying pony runtime:
```
Runtime options for Pony programs (not for use with ponyc):
  --ponymaxthreads Use N scheduler threads. Defaults to the number of
                   cores (not hyperthreads) available.
                   This can't be larger than the number of cores available.
  --ponyminthreads Minimum number of active scheduler threads allowed.
                   Defaults to 0, meaning that all scheduler threads are
                   allowed to be suspended when no work is available.
                   This can't be larger than --ponymaxthreads if provided,
                   or the physical cores available
  --ponynoscale    Don't scale down the scheduler threads.
                   See --ponymaxthreads on how to specify the number of threads
                   explicitly. Can't be used with --ponyminthreads.
  --ponysuspendthreshold
                   Amount of idle time before a scheduler thread suspends
                   itself to minimize resource consumption (max 1000 ms,
                   min 1 ms).
                   Defaults to 1 ms.
  --ponycdinterval Run cycle detection every N ms (max 1000 ms, min 10 ms).
                   Defaults to 100 ms.
  --ponygcinitial  Defer garbage collection until an actor is using at
                   least 2^N bytes. Defaults to 2^14.
  --ponygcfactor   After GC, an actor will next be GC'd at a heap memory
                   usage N times its current value. This is a floating
                   point value. Defaults to 2.0.
  --ponynoyield    Do not yield the CPU when no work is available.
  --ponynoblock    Do not send block messages to the cycle detector.
  --ponypin        Pin scheduler threads to CPU cores. The ASIO thread
                   can also be pinned if `--ponypinasio` is set.
  --ponypinasio    Pin the ASIO thread to a CPU the way scheduler
                   threads are pinned to CPUs. Requires `--ponypin` to
                   be set to have any effect.
  --ponyprintstatsinterval
                   Print actor stats before an actor is destroyed and
                   print scheduler stats every X seconds. Defaults to -1 (never).
  --ponyversion    Print the version of the compiler and exit.
  --ponyhelp       Print the runtime usage options and exit.

```

## "Special" features

- Object literals and lambdas
- Arithmetic
- C-FFI, `--safe` parameter
- Syntactic sugar


## Under the hood

The [pony runtime](https://github.com/ponylang/ponyc/tree/main/src/libponyrt) is implemented in C. [Actors](https://github.com/ponylang/ponyc/blob/main/src/libponyrt/actor/actor.h#L53) are stored in a struct,
that points to the pony type and has a [queue of messages](https://github.com/ponylang/ponyc/blob/main/src/libponyrt/actor/messageq.h#L6).
The runtime also has a garbage collector.

## [An early history of Pony](https://www.ponylang.io/blog/2017/05/an-early-history-of-pony/)

Pony began with a library for actors written in and used with C, developed by Sylvan Clebsch.
This library did message passing without copies, while very fast, programmers often ran into memory
errors: data leaks, dangling pointers and especially data-races. Additionally deadlock conditions were encountered when
other synchronisation mechanisms were used.

The solution was a new language, with the type system taking care of these issues. Also a new garbage collector
that can deal with the distributed memory used be independent actors.


## Rover

Implement basic functionality to control the FHNW-Rover with a pony program, mainly the drivetrain.

This includes sending and receiving data via TCP to talk to the motor drivers, additionally a simple http server is needed to control
the behaviour of the rover through a client application. Later communication via the yocto API could be implemented, either via Rest
or the low level C API (yapi).

Pony has similar constructs as ROS2, so it lends itself to try this. Obviously pony does not come close in respect to libraries.

### Some differences:
- ROS2 is more sophisticated, and has additional controls
- Pony comes with compile time guarantees for the types of the topics
- ROS2 needs a rather large bundle of dependencies
- ROS2 can run in different processes and communicate through network wide channels
- Ponys actor system is tailored at communication between threads of the same process
- But the serialization functionality of pony could be used to communicate with other processes, even through a network
