%define SYS_WRITE 1
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_STAT 4
%define SYS_FSTAT 5
%define SYS_EXIT 60
%define S_IFDIR 0x4000
%define O_RDONLY 00
%define S_IFMT 0xf000
%define FAMINE_STACK_SIZE 5000


; r15 /tmp/test
; r15 + 16 /tmp/test fd
; r15 + 32 struct stat
;	r15 + 32 dev inode_number
;	r15 + 32 + 24 stat.st_mode
; 	r15 + 80 stat.st_size



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
	mov qword [r15 + 8], 0x00000074
;	mov rsi, r15
;	mov rdx, 9
;	mov rax, SYS_WRITE
;	mov rdi, 1

	mov rdi, r15
	mov [r15 + 16], rax
	test rax,rax
	js _end		; if open fails, exit silently

	mov rdi, r15
	lea rsi, [r15 + 32]

	mov rax, SYS_STAT
	syscall

_is_dir:
	lea rax, [r15 + 32 + 24]
	mov rcx, [rax]
	mov rdx, S_IFDIR

	and rcx, S_IFMT

	cmp rdx, rcx
	jne _end ; if failure, exit

	mov rdi, r15
	mov rsi, O_RDONLY
	mov rax, SYS_OPEN
	syscall
	mov [r15 + 16], rax

	


	lea rax, [r15 + 16]
	mov rdi, [rax]
	mov rax, SYS_CLOSE
	syscall

	jmp _end
_end:
	add  rsp, FAMINE_STACK_SIZE
	pop rsp
	pop rdx
	mov rax, SYS_EXIT
	xor rdi, rdi
	syscall
