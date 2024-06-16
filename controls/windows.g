; the fasm2 model:
;	include 'dd.inc'
;	include 'align.inc'
;	include 'format.inc'
;	include 'x86-2.inc'
;	use everything
;
;	include '@@.inc'
;	include 'times.inc'
;	include 'fix.inc'

format MS64 COFF
section ".text$t" code executable readable align 64

;------------------------------------------------------------------------------
; generate collection macros
iterate ANCHOR, const,data,bss
iterate V,1,2,4,8,16,32,64
	calminstruction COFF.V.ANCHOR? line&
		local X
		match ,line
		jyes A		; empty triggers output
		take X,line	; consume
		exit
		; reverse order
	A:	take line,X
		jyes A
		; output
	B:	assemble line	; process
		take , line	; remove TOS
		take line,line	; more?
		jyes B
	end calminstruction
end iterate
end iterate
;calminstruction testing
;	call COFF.2.CONST data =du value
;end calminstruction
;------------------------------------------------------------------------------

; remove some features of the fasm2 packaged distribution:
;	- no TCHAR support, use explicit API/struct names
;
; additional features:
;	- shortcut library names to fastcall invocation (invoke not needed)

; don't coerse api names to A/W - must explicitly use API desired
calminstruction api names&
	; TODO : create error macros to notify on use
end calminstruction

; TODO: error if TCHARs are used
struc? TCHAR args:?&
	. du args
end struc
macro TCHAR args:?&
	du args
end macro
sizeof.TCHAR = 2

include 'macro/struct.inc'
include 'fastcall.g'
;include 'macro/proc64.inc' ; replace with lite version
;purge fastcall?.inline_string ; disable TCHAR use in fastcall?.inline_string until better solution
;include 'macro/com64.inc'	; custom COM macros
;include 'macro/import64.inc'	; managed by linker in COFF objects
;include 'macro/export.inc'	; managed by linker in COFF objects
;include 'macro/resource.inc'	; managed by linker in COFF objects

Struct.CheckAlignment = 1

include 'equates/kernel64.inc'
include 'equates/user64.inc'
include 'equates/gdi64.inc'
include 'equates/comctl64.inc'	; TODO: replace with corrections
include 'equates/comdlg64.inc'
include 'equates/shell64.inc'
include 'equates/wsock32.inc'

;------------------------------------------------------------------------------
include 'winmore.g'
;===================================================== fastcall/extrn catch all
namespace COFF
	define FUNCTIONS FUNCTIONS
end namespace
calminstruction ?? line& ; this catch all can easily masks errors
	local var, function, parameters
	arrange parameters,
	match function parameters?, line
	jno more
	transform function, COFF.FUNCTIONS
	jyes present
	arrange var, =COFF.=FUNCTIONS.function
	publish var, function
	publish var, function

;	stringify line ; debug
;	display line
;	display 10

	transform var
	take COFF..functions, var
present:
	arrange line, =fastcall function,parameters
	match , parameters
	jno more
	arrange line, =fastcall function
more:	assemble line
end calminstruction

;-------------------------------------------------------------- light proc-like
calminstruction ?? &line&
	; TODO: add function features? Presently MUST be complete line
	match :named:,line
	jyes fn
	assemble line
	exit

fn:	local var
	take .frame,.frame ; has a value?
	jyes skip

	arrange var,=.=frame :== =fastcall?=.=frame
	assemble var
skip:
	arrange var,named:
	assemble var
	; reset stack depth counter
	compute fastcall?.frame, 0
end calminstruction

;------------------------------------------------------- data section gathering
calminstruction ?? line&
	match {section:grain} line, line
	jyes datas
	assemble line
	exit
datas:
	arrange line,=COFF=.grain=.section line
	assemble line
	stringify line
;	display line
;	display 10
end calminstruction
;--------------------------------------------------------------------- finalize
postpone
calminstruction onetime ; light proc-like closure
	local tmp
	arrange tmp, =.=frame :== =fastcall?=.=frame
	assemble tmp
end calminstruction
onetime
purge onetime

irpv fun, COFF..functions ; catch-all API's done
	extrn `fun as fun: QWORD
end irpv

; https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483
extrn __ImageBase ; the linker knows

; TODO: finalize constant data

align?.count = 1 ; reset align

; output collection macros
iterate <ANCHOR,HEADER>,\
	CONST,	<section '.const$t'	data	readable align 64>,\
	DATA,	<section '.data$t'	data	readable writeable align 64>,\
	BSS,	<section '.bss$t'	udata	readable writeable align 64>

	if COFF.ANCHOR.BYTES > 0
		HEADER
	end if
	COFF.ANCHOR:
	iterate V,64,32,16,8,4,2,1
		COFF.V.ANCHOR
	end iterate
	COFF.ANCHOR.BYTES := $ - COFF.ANCHOR
;	repeat 1,B:COFF.ANCHOR.BYTES
;		display 10,9,`ANCHOR,' bytes ',`B
;	end repeat
end iterate

end postpone
