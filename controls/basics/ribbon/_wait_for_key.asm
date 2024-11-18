include 'console.g'
extrn hOutput

macro ← line& ; terse console output macro
	local str,chars
	COFF.2.CONST str du line
	COFF.2.CONST chars := ($ - str) shr 1
	WriteConsoleW [hOutput], & str, chars, 0, 0
end macro

:getch:
	virtual at rbp + 16 ; shadow-space
		.hInput		dq ?
		.dwRead         dd ?
		.oldInMode      dd ?
		.buffer         dd ? ; just need space for a single character
	end virtual
	enter .frame, 0
	GetStdHandle STD_INPUT_HANDLE
	mov [.hInput], rax
	GetConsoleMode [.hInput], & .oldInMode
	mov edx, not (ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT)
	and edx, [.oldInMode]
	SetConsoleMode [.hInput], rdx
	mov [.buffer], 0
	ReadConsoleW [.hInput], & .buffer, 1, & .dwRead, 0
	SetConsoleMode [.hInput], [.oldInMode]
	mov eax, [.buffer]
	leave
	retn

public wait_for_key as "_wait_for_key"
:wait_for_key:
	enter .frame, 0
	←	27,'[?25l',\	; hide cursor
		27,'[s',\	; save cursor position
		27,'[999;1H',\	; start of last line
		27,'[31m',\	; dark red text
		27,'[5m',\	; blinking text
	"Press any key to continue ..."
	call getch
	←	27,'[2K',\	; clear line
		27,'[m',\	; reset text attributes
		27,'[u',\	; restore cursor position
		27,'[?25h'	; show cursor
	leave
	retn
