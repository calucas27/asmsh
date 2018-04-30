%include "/usr/local/share/csc314/asm_io.inc"


segment .data
prompt		db		"[asmsh] > ",0
fmt			db		"%s",0
cdir_msg	db		"Change to which directory?: ",0
mov_msg		db		"Source filename?: ",0
mov_msg2	db		"Destination filename?: ",0
del_msg		db		"File to remove?: ",0
pid_msg		db		"PID: %d",10,0
ren_msg		db		"Old filename?: ",0
ren_msg2	db		"New filename?: ",0

helpmenu	db		"Welcome to the asmshell, here are all of the currently implemented commands: ",13,10
			db		"--> help",13,10
			db		"--> ot",13,10
			db		"--> cwd",13,10
			db		"--> cdir",13,10
			db		"--> gci",13,10
			db		"--> mov",13,10
			db		"--> ren",13,10
			db		"--> pid",13,10
			db		"--> del",13,10

exitstr		db		"kthxbai",10,0

segment .bss
buffer		resb	128
prog_cwd	resb	64
prog_cdir	resb	64
prog_mov	resb	64
prog_mov2	resb	64
prog_del	resb	64

segment .text
	global  asm_main
	extern	scanf
	extern	printf

	%define syswrite 4
	%define stdout 1

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********

	top_shell:

	;generate the prompt
	mov		eax,prompt
	call	print_string

	;get the input from the user
	push	buffer
	push	fmt
	call	scanf
	add		esp,8

	cmp		DWORD [buffer], "help"
	jne		skip_help
		call	help_func
		add		esp,4
	skip_help:

	cmp		DWORD [buffer],"ot" ; this is a test comamnd for debugging
	jne		skip_order
		mov		eax,1
		call	print_int
		call	print_nl
	skip_order:

	;time for all teh syscalls
	;also implemented strlen to make my life easier :)
	cmp		DWORD [buffer], "cwd"
	jne		skip_cwd
		mov	eax,0xb7 ;sys_getcwd
		mov	ebx, prog_cwd
		mov	ecx,128 ;size of getcwd buffer
		int		0x80

		mov		edx,ebx

		push	ebx	;the name of the dir
		call	strlen	;returns in EAX
		add		esp,4

		mov		edi,edx	;name of the dir
		mov		edx,eax	;output of strlen

		mov		eax,4	;sys_write
		mov		ebx,1	;stdout
		mov		ecx,edi	;name of dir
		int 0x80
		call	print_nl
	skip_cwd:

	cmp		DWORD [buffer],"cdir"
	jne		skip_cdir

		mov		eax,cdir_msg
		call	print_string
		;get the directory to change to
		push	prog_cdir
		push	fmt
		call	scanf
		add		esp,8	;stored in [prog_cdir]

		mov		edx,prog_cdir ;name of the dir to change to

		push	edx
		call	strlen
		add		esp,4	;strlen in eax, name of dir in edx

		mov		edi,eax ; strlen in edi, name of dir in edx

		;change the directory
		mov		eax,0x0c
		mov		ebx,edx
		int		0x80

		;mov		eax,4
		;mov		ebx,1
		;mov		ecx,edx
		;mov		edx,edi
		;int		0x80
		;call	print_nl
	skip_cdir:


	cmp		DWORD [buffer],"gci"	;i'm thoroughly appaled how much time I spent on this syscall.
	jne		skip_gci				;spent at least 3 hours on Saturday on this one


	;i taught myself about forking specifically to make it this way
	;super hacky, but it works -- program doesn't just die after running ls any more. :)

	mov		eax,2 ;sys_fork
	int		0x80
	cmp		eax,0
	jz		child

	parent:
		jmp	skip_gci

	child:

	call	print_nl

	mov		eax,11 ;sys_execve

	xor		eax,eax
	push	eax

	;make the call for /bin/ls --> has to be done in little endian for whatever reason

	push 0x736c2f6e ;push hex hs/n on to the stack
	push 0x69622f2f ;push hex ib// on to the stack

	mov		ebx, esp  ; push the filename onto the stack
	push	eax

	mov		edx, esp
	push	ebx
	mov		ecx, esp
	mov		al,11
	int		0x80

	jmp		top_shell

	skip_gci:


	cmp		DWORD [buffer],"mov"
	jne		skip_mov
		mov		eax,mov_msg
		call	print_string

		push	prog_mov
		push	fmt
		call	scanf
		add		esp,8	;stored in [prog_mov]

		mov		edi,prog_mov ;source file in prog_mov

		;push	edi
		;call	printf
		;add		esp,8

		mov		eax,mov_msg2
		call	print_string

		push	prog_mov2
		push	fmt
		call	scanf
		add		esp,8	;dest file in prog_mov

		mov		esi,prog_mov2 ;dest file in ecx

		;push	esi
		;call	printf
		;add		esp,8

		mov		eax,0x09 ;sys_link
		mov		ebx,edi
		mov		ecx,esi
		int		0x80

		skip_mov:


		cmp		DWORD [buffer], "ren"
		jne		skip_ren

			mov		eax,ren_msg
			call	print_string

			push	prog_mov
			push	fmt
			call	scanf
			add		esp,8 ; original filename stored in prog_mov

			mov		edi, prog_mov ; original name in edi

			mov		eax,ren_msg2
			call	print_string

			push	prog_mov2
			push	fmt
			call	scanf
			add		esp,8

			mov		esi, prog_mov2 ; original name in edi, new name in esi

			mov		eax,0x26 ;sys_rename
			mov		ebx,edi
			mov		ecx,esi
			int		0x80

		skip_ren:


	cmp		DWORD [buffer], "pid"
	jne		skip_pid

		mov		eax,0x14	;sys_getpid
		int		0x80

		mov		edx,eax ;pid stored in edx

		push	edx
		push	pid_msg
		call	printf
		add		esp,8

	skip_pid:


	cmp		DWORD [buffer], "del"
	jne		skip_del

		mov		eax,del_msg
		call	print_string

		push	prog_del
		push	fmt
		call	scanf
		add		esp,8	;stored in [prog_del]

		mov		ebx,prog_del ;name of the file to remove.

		mov		eax,0x0a
		int		0x80
	skip_del:


	cmp		DWORD [buffer],"exit"
	jne		top_shell
		;end the program by force
		push	exitstr
		call	printf
		add		esp,8
		mov	eax,0
		mov	ebx,0
		int 0x80

	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret


help_func:
	push	ebp
	mov		ebp,esp

	push	helpmenu
	push	fmt
	call	printf
	call	print_nl
	add		esp,8

	mov		esp,ebp
	pop		ebp
	ret

strlen:
	push	ebp
	mov		ebp,esp

	sub		esp,4

	mov		DWORD [ebp - 4] ,0

	topwhile:
		mov		edi, DWORD [ebp - 4]
		mov		esi, DWORD [ebp + 8]
		cmp		BYTE [esi + edi * 1], 0
		je		endwhile
			inc	DWORD [ebp - 4]
		jmp		topwhile

	endwhile:
	mov		eax, DWORD [ebp - 4]

	mov		esp,ebp
	pop		ebp
	ret
