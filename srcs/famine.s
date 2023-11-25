%define SYS_EXIT 60
%define SYS_WRITE 1
%define SYS_OPEN 2
%define FAMINE_STACK_SIZE 5000


global _start

	section .text
_start:
	push rbp
	push rdx
	push rsp
	sub  rsp, FAMINE_STACK_SIZE
	mov r15, rsp    
	mov qword [r15], '/tmp'
	mov qword [r15 + 4], '/tes'
	mov qword [r15 + 8], 't'
	mov rdi, 1
	mov rsi, r15
	mov rdx, 9
	mov rax, SYS_WRITE
	syscall
	jmp _end
_end:
	add  rsp, FAMINE_STACK_SIZE
	pop rsp
	pop rdx
	mov rax, SYS_EXIT
	xor rdi, rdi
	syscall
