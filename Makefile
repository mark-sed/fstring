all: fstr main

fstr:
	nasm -f elf64 -g -F dwarf -o fstring.o fstring.asm

main: fstr
	gcc -Wall -no-pie -o main main.c fstring.o
