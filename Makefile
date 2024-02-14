build = build
src = src/

.PHONY: fundamentals rover clean

all: fundamentals rover server-test

debug: FLAGS=--debug
debug: all

fundamentals: $(build)fundamentals
rover: $(build)rover
server-test: $(build)server-test

$(build)fundamentals: $(src)fundamentals/*
	corral fetch
	@mkdir -p $(build)
	corral run -- ponyc -Dopenssl_3.0.x $(FLAGS) --output $(build) $(src)fundamentals

$(build)rover: $(src)rover/*
	corral fetch
	@mkdir -p $(build)
	corral run -- ponyc $(FLAGS) -Dopenssl_3.0.x --output $(build) $(src)rover

$(build)server-test: $(src)server-test/*
	corral fetch
	@mkdir -p $(build)
	corral run -- ponyc -Dopenssl_3.0.x $(FLAGS) --output $(build) $(src)server-test

clean:
	corral clean
	rm -rf build
