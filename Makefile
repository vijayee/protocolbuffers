build:
	mkdir -p build
test: build
	mkdir -p build/test
test/protocolbuffers: test protocolbuffers/*.pony protocolbuffers/test/*.pony
	stable fetch
	stable env ponyc protocolbuffers/test -o build/test --debug
test/execute: test/protocolbuffers
	./build/test/test
clean:
	rm -rf build

.PHONY: clean test
