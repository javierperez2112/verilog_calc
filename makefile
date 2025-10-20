main: main.v serial.v
	apio build
	apio upload

sim: main.v serial.v
	iverilog main.v serial.v
	./a.out
	gtkwave my_dumpfile.vcd

clean:
	git clean -fdX