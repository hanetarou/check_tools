.PHONY: all
all: check_ping ;

check_ping: mkdir src/check_ping.go
	go build -o bin/check_ping src/check_ping.go

.PHONY: mkdir
mkdir:
	mkdir -p bin

.PHONY: clean
clean:
	rm -f bin/test

.PHONY: rebuild
rebuild: clean all ;
