
; the idea here is to simplify coding into a single section,
; perfect for brief coding explorations

format MS64 COFF
include 'win64a.inc'

; missing constants
DIB_RGB_COLORS := 0

calminstruction entry? target*
	local line
	; naming based on windows subsystem expectation
	arrange line, =public target =as 'WinMainCRTStartup'
	assemble line
end calminstruction

section '.text$t' code executable readable align 64

postpone
	section '.drectve' linkinfo linkremove
	db '/BASE:0x10000 '
	db '/SUBSYSTEM:WINDOWS '
	db '/DEFAULTLIB:KERNEL32.LIB '
	db '/DEFAULTLIB:USER32.LIB '
	db '/DEFAULTLIB:GDI32.LIB '
	db '/DEFAULTLIB:dwmapi '

	section '.data$t' data readable writeable align 64
	!! ; commit cached lines

	; the linker will merge this section automatically, but it's
	; important to flag the data as uninitialized
	section '.bss$t' udata readable writeable align 64
	~~ ; commit cached lines
end postpone

; https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483
extrn __ImageBase ; the linker knows
hInstance equ __ImageBase ; also used as a psuedo-handle

nullptr := 0
;-------------------------------------------------------------------------------
postpone
irpv fun, COFF..functions
	extrn `fun as fun: QWORD
end irpv
end postpone

namespace COFF
	define FUNCTIONS FUNCTIONS
end namespace

calminstruction ?? line&
	local var, function, parameters
	arrange parameters,
	match function parameters?, line
	jno more

	; only one instance per function
	transform function, COFF.FUNCTIONS
	jyes pprocess
	; create a case-sensative reference
	arrange var, =COFF.=FUNCTIONS.function
	; we double up to prevent forward referencing (infinite loop)
	publish var, function
	publish var, function
	; gather unique vector of uses, preserve function
	transform var
	take COFF..functions, var
pprocess:
	arrange line, =fastcall function,parameters
	match , parameters
	jno more
	arrange line, =fastcall function
more:
	assemble line
end calminstruction
;-------------------------------------------------------------------------------
; context aware line gathering
calminstruction ?? line& ; works like magic
	match !!line?, line
	jyes commit
	match ~~line?, line
	jyes scatter
	match !line?, line
	jyes collect
	match ~line?, line
	jyes gather
	assemble line
	exit

	local stack
    collect:
	take stack, line
	exit

	local pile
    gather:
	take pile, line
	exit

    scatter:
	take line, pile
	jyes scatter
	jump assembly

    commit:
	take line, stack
	jyes commit
    assembly:
	assemble line
	take , line
	take line, line
	jyes assembly
end calminstruction

;-------------------------------------------------------------------------------
;include 'extrn\pcg32.asm'
;include 'extrn\u32.asm'


;-------------------------------------------------------------------------------
; dwmapi.inc

struct DWM_BLURBEHIND
	dwFlags			dd ?	; DWM_BB_*
	fEnable			dd ?
	hRgnBlur		dq ?
	fTransitionOnMaximized	dd ?,?
ends

DWM_BB_ENABLE			:= 0x00000001
DWM_BB_BLURREGION		:= 0x00000002
DWM_BB_TRANSITIONONMAXIMIZED	:= 0x00000004
