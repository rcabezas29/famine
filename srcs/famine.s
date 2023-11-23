%define SYS_EXIT 60
global _start

	section .text
_start:
	push rbp
	mov rax, SYS_EXIT
	xor rdi, rdi
	syscall
