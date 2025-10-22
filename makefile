main: main.v serial.v keyboard.v rpn_stack.v
	apio build
	apio upload

sim: main.v serial.v
	iverilog main.v serial.v keyboard.v rpn_stack.v
	./a.out
	gtkwave my_dumpfile.vcd

clean:
	git clean -fdX