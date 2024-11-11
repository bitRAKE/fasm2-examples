; import C/C++ preprocessor style defines (just numbers for now)

; :NOTE: This requires compiling the ribbon XML prior to assembly and managing
; command names such that they don't conflict with existing names.
;
; usage:
;	include "import_c_define.g",THE_FILE equ "app.rc"

calminstruction reader line&
	match =mvmacro? =reader? =, =?,line
	jno go
	assemble line
skip:	exit

go:	match =#=define? name= value // any?,line
	jyes ok
	match =#=define? name= value,line
	jno skip
ok:	arrange line,name =:== value
	assemble line
end calminstruction
include THE_FILE,mvmacro ?,reader
mvmacro reader,?
purge reader
restore THE_FILE ; no forward references, why?


; We want to verify a range of command ids. UICC.EXE will create names based
; on the command name and an underscore suffix. Names w/o an underscore are
; commands (if no underscore was added to command name :-).
;
; Another options is to parse the XML directly.
;
; if command:
;	+ check for duplicate command id
;	+ set id bit
;
; verify contigious bit range
;	bsf command_bitarray

;	COMMAND_MIN := 2
;	COMMAND_MAX := 97

