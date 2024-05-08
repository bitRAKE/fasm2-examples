
; the idea here is to simplify coding into a single section,
; perfect for brief coding explorations

format MS64 COFF
include 'win64a.inc'
include 'wincon.g' ; console interface support

section '.text$t' code executable readable align 64

postpone
	section '.drectve' linkinfo linkremove
	db '/BASE:0x10000 '
	db '/SUBSYSTEM:CONSOLE '
	db '/DEFAULTLIB:KERNEL32.LIB '
	db '/DEFAULTLIB:USER32.LIB '

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

calminstruction ? line&
	local var,i
	match << line >>, line
	jno done
	init i, 0
	arrange var, .=const.i ; unique local label
	compute i, i + 1
	arrange line, ! var =db line
	assemble line
	arrange line, ! var=.=bytes == =$ - var
	assemble line
	arrange line, =WriteFile =rbx, =dword var, var=.=bytes, 0, 0
done:	assemble line
end calminstruction

calminstruction ? line&
	local var,i
	match <| line |>, line
	jno done
	init i, 0
	arrange var, .=buildup.i
	compute i, i + 1
	arrange line, ! var =db line
	assemble line
	arrange line, ! var=.=bytes == =$ - var
	assemble line
	arrange line, =lea =rsi, [var]
	assemble line
	arrange line, =mov =ecx, var=.=bytes
	assemble line
	arrange line, =rep =movsb
done:	assemble line
end calminstruction

;-------------------------------------------------------------------------------
include 'extrn\pcg32.asm'
include 'extrn\u32.asm'
