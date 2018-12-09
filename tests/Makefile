all: fstr main

fstr:
	nasm -f elf64 -g -F dwarf -o fstring.o fstring.asm

main: fstr
	gcc -Wall -no-pie -g -o main main.c fstring.o

test: fstr
	gcc -O0 -no-pie -o ctest ctest.c 
	gcc -O0 -no-pie -o ftest main.c fstring.o
