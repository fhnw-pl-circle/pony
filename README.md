# pony

Intro to pony, an "object-oriented, actor-model, capabilities-secure, high-performance programming language".


## Important links

- [Homepage](https://www.ponylang.io/)
- [Tutorial](https://tutorial.ponylang.io/): Introduction of the most important concepts
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

## "Special" features

- Object literals and lambdas
- Arithmetic
- C-FFI
- Syntactic sugar


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
