.PHONY: test fundamentals rover clean fetch

fetch:
	corral fetch

all: fundamentals rover server-test test

debug: FLAGS=--debug
debug: all

fundamentals: build/fundamentals
rover: build/rover
server-test: build/server-test

bench: build/benchmark
	./build/benchmark

test: build/test
	./build/test

build/fundamentals: src/fundamentals/*
	@mkdir -p build
	corral run -- ponyc -Dopenssl_3.0.x $(FLAGS) --output build src/fundamentals

build/rover: src/rover/*
	@mkdir -p build
	corral run -- ponyc $(FLAGS) -Dopenssl_3.0.x --output build src/rover

build/server-test: src/server-test/*
	@mkdir -p build
	corral run -- ponyc -Dopenssl_3.0.x $(FLAGS) --output build src/server-test

build/test: src/fundamentals/test/*
	@mkdir -p build
	corral run -- ponyc -Dopenssl_3.0.x $(FLAGS) --output build src/fundamentals/test

build/benchmark: src/fundamentals/benchmark/*
	@mkdir -p build
	corral run -- ponyc -Dopenssl_3.0.x $(FLAGS) --output build src/fundamentals/benchmark

clean:
	corral clean
	rm -rf build
