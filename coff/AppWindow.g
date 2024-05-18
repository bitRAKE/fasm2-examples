format MS64 COFF
include 'win64a.inc'
;----------------------------------------------------------- more windows stuff
; missing constants

HTCAPTION := 2

GWL_EXSTYLE := -20

DIB_RGB_COLORS := 0

struc(register) MAKELONG low*,high*
	match [high] [low], high low
		; high word, zero high dword
		mov reg32.register, dword [high + 2]
		; non-destructive low word
		mov reg16.register, word [low]
	else
		err 'memory parameters expected'
	end match
end struc
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




MONITOR_DEFAULTTONULL		:= 0x00000000
MONITOR_DEFAULTTOPRIMARY	:= 0x00000001
MONITOR_DEFAULTTONEAREST	:= 0x00000002

MONITORINFOF_PRIMARY		:= 0x00000001

struct MONITORINFOEXA
	cbSize		dd ?
	rcMonitor	RECT
	rcWork		RECT
	dwFlags		dd ?
	szDevice	rb 32 ; CCHDEVICENAME
ends


section '.text$t' code executable readable align 64
;----------------------------------------------------- fastcall/extrn catch all
namespace COFF
	define FUNCTIONS FUNCTIONS
end namespace
; this catch all can easily masks errors
calminstruction ?? line&
	local var, function, parameters
	arrange parameters,
	match function parameters?, line
	jno more
	transform function, COFF.FUNCTIONS
	jyes present
	arrange var, =COFF.=FUNCTIONS.function
	publish var, function
	publish var, function
	transform var
	take COFF..functions, var
present:
	arrange line, =fastcall function,parameters
	match , parameters
	jno more
	arrange line, =fastcall function
more:	assemble line
end calminstruction
;------------------------------------------------------------ section gathering
calminstruction ?? line&
	match {=bss?} line, line
	jyes bss
	match {=const?} line, line
	jyes const
	match {=data?} line, line
	jyes data
	match {=sections?}, line
	jyes over
	assemble line
	exit

	local _B_,_C_,_D_
bss:	take _B_,line
	exit
const:	take _C_,line
	exit
data:	take _D_,line
	exit

over:	take , line
done:	take line, _B_
	jyes done
don:	take line, _C_
	jyes don
do:	take line, _D_
	jyes do

out:	assemble line
	take , line
	take line, line
	jyes out
end calminstruction
{bss}	section '.bss$t' udata readable writeable align 64
{const}	section '.const$t' data readable align 64
{data}	section '.data$t' data readable writeable align 64

;--------------------------------------------------------------------- finalize
postpone

; https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483
extrn __ImageBase ; the linker knows
hInstance equ __ImageBase ; also used as a psuedo-handle

nullptr := 0

irpv fun, COFF..functions
	extrn `fun as fun: QWORD
end irpv

public WinMainCRTStartup ; just make default name public

{sections}
end postpone
