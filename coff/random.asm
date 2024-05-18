include 'AppConsole.g'
;-------------------------------------------------------------------------------
include 'extrn\prng\pcg32.asm'
include 'extrn\u32.asm'

Fatal:	ExitProcess 1

~	columns		dd ?
~	lines		dd ?
~	oldOutMode	dd ?

public mainCRTStartup
mainCRTStartup: fastcall?.frame = 0
	virtual at rbp - .local
		.csbi CONSOLE_SCREEN_BUFFER_INFO
			align.assume rbp,16
			align 16
		.local := $ - $$
	; note: pcg32 at RBP, in shadow-space
	end virtual
	enter .frame + .local, 0

	GetStdHandle dword STD_OUTPUT_HANDLE
	xchg rbx, rax

	GetConsoleMode rbx, dword oldOutMode
	xchg ecx, eax ; BOOL
	jrcxz Fatal ; don't support redirected handles

	SetConsoleMode rbx, ENABLE_PROCESSED_OUTPUT or ENABLE_VIRTUAL_TERMINAL_PROCESSING
	xchg ecx, eax ; BOOL
	jrcxz Fatal ; VT required

; initialize terminal
<<	27,'[?1049h',\	; enables the alternative buffer
	27,'[2J',\	; clear screen
	27,'[?25l' >>	; make cursor invisible

	GetConsoleScreenBufferInfo rbx, addr .csbi
	mov cx, [.csbi.srWindow.Right]
	mov ax, [.csbi.srWindow.Bottom]
	sub cx, [.csbi.srWindow.Left]
	sub ax, [.csbi.srWindow.Top]
	add cx, 1
	add ax, 1
	movsx ecx, cx
	movsx eax, ax
	mov [columns], ecx
	mov [lines], eax

	call pcg32_initialize
.main_loop:
	Sleep 1 ; fraction of a percent CPU utilization

	; try to fill buffer, approx. message length = 32
	mov ecx, (sizeof Buffer) / 32
.more:
	push rcx

	call pcg32_random_r ; make the most of psuedo-random bits ...
	mul [symbols]
	push rdx
	mul [colors]
	push rdx
	mul [intensities]
	push rdx
	mul [columns]
	push rdx
	mul [lines]

	lea edi, [Buffer]
	mov ax, 27 or ('[' shl 8)	; cursor to L x C
	stosw
	lea eax, [rdx+1]		; line
	call u32__ToString
	mov al, ';'
	stosb
	pop rax
	add eax, 1			; column
	call u32__ToString

	pop rsi
	mov esi, [intensities + 4*(rsi+1)]
	movzx ecx, byte [rsi-1]
	rep movsb

	pop rsi
	mov esi, [colors + 4*(rsi+1)]
	movzx ecx, byte [rsi-1]
	rep movsb

	pop rax
	mov al, [symbol + rax]
	stosb
;-------------------------------------------------------------------------------
	pop rcx
	loop .more

	lea edx, [Buffer]
	push rbx
	pop rcx		; handle
	sub edi, edx
	mov r8d, edi	; bytes
	WriteFile rcx, rdx, r8, 0, 0

	GetAsyncKeyState 27 ; VK_ESC
	test al,1
	jz .main_loop

;	restore terminal
<<	27,'[?1049l',\	; disables the alternative buffer
	27,'[?25h' >>	; make cursor visible

	SetConsoleMode rbx, [oldOutMode]
	ExitProcess 0
	.frame = fastcall?.frame

	iterate I,\
		'1',\	; bold
		'2',\	; dim
		'3',\	; italic
		'4',\	; underline
\;nope		'5',\	; blink
		'7',\	; inverse
		'9',\	; strikethrough
		'22',\	; reset bold/dim off
		'23',\	; reset italic
		'24',\	; reset underline
\;		'25',\	; reset blink
		'27',\	; reset inverse
		'29'	; reset strikethrough
		if % = 1
			intensities dd %%
			repeat %%
				dd .%
			end repeat
		end if
!			db .%.bytes
!		.%	db 'H',27,'[',I
!		.%.bytes := $ - .%
	end iterate

	iterate C,\; {r};{g};{b}
		'255;182;193',\		; light pink
		'137;207;240',\		; baby blue
		'152;255;152',\		; mint green
		'230;230;250',\		; lavender
		'255;229;180'		; peach
		if % = 1
			colors dd %%
			repeat %%
				dd .%
			end repeat
		end if
!			db .%.bytes
!		.%	db ';38;2;',C,'m'
!		.%.bytes := $ - .%
	end iterate

! symbol db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~'
! symbols dd $ - symbol

~	align 64
~ label Buffer:4096
~	rb sizeof Buffer
