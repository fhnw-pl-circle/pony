fundamentals: src/fundamentals/*
	corral fetch
	@mkdir -p build/
	corral run -- ponyc -Dopenssl_3.0.x --debug --output build src/fundamentals

rover: src/rover/*
	corral fetch
	@mkdir -p build/
	corral run -- ponyc --debug --output build src/rover

clean:
	corral clean
	rm -rf build
