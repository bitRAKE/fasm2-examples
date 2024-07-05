;===============================================================================
; 32-bit Extended Dialog Template Support:
;
; For use by the following APIs functions:
;	1. modeless
;		CreateDialogIndirectParam
;		CreateDialogIndirect
;	2. modal
;		DialogBoxIndirectParam
;		DialogBoxIndirect
;
; They all have similar parameter list:
;	{*} __ImageBase, & template, [.hWndParent], & DialogFunction, [.param]
;
; note: if the `Param` is unused then just use the `Param` function anyway :-)

calminstruction CreateDialogIndirect line&
	arrange line,=CreateDialogIndirectParam line
	assemble line
end calminstruction
calminstruction DialogBoxIndirect line&
	arrange line,=DialogBoxIndirectParam line
	assemble line
end calminstruction





; TODO: What ordinal cases will route incorrectly as string?
; (Nothing that will pass through DU?)
calminstruction sz_Or_Ord line&
	local any
	match <line>,line
	match any=,any,line
	jyes str
	check line eqtype ''
	jyes str
	emit 2,0xFFFF
	emit 2,line
	exit
str:	arrange line, =du line,0
	assemble line
end calminstruction

;-------------------------------------------------------------------------------
define DLGITEMTEMPLATEEX ; select useful default values
define DLGITEMTEMPLATEEX.helpID		0	; DWORD
define DLGITEMTEMPLATEEX.exStyle	0	; DWORD
define DLGITEMTEMPLATEEX.style		0	; DWORD
define DLGITEMTEMPLATEEX.x		0	; short
define DLGITEMTEMPLATEEX.y		0	; short
define DLGITEMTEMPLATEEX.cx		0	; short
define DLGITEMTEMPLATEEX.cy		0	; short
define DLGITEMTEMPLATEEX.id		-1	; DWORD
define DLGITEMTEMPLATEEX.windowClass	''	; sz_Or_Ord
define DLGITEMTEMPLATEEX.title		''	; sz_Or_Ord
define DLGITEMTEMPLATEEX.extraCount	0	; WORD
define DLGITEMTEMPLATEEX.extraData

; predefined class atoms
define DLGITEMTEMPLATEEX.windowClass.button?	0x0080
define DLGITEMTEMPLATEEX.windowClass.edit?	0x0081
define DLGITEMTEMPLATEEX.windowClass.static?	0x0082
define DLGITEMTEMPLATEEX.windowClass.listbox?	0x0083
define DLGITEMTEMPLATEEX.windowClass.scrollbar?	0x0084
define DLGITEMTEMPLATEEX.windowClass.combobox?	0x0085

DLGITEMTEMPLATEEX..items = 0 ; internal counter for parent dialog

calminstruction DLGITEMTEMPLATEEX line&
	local val
	compute val,DLGTEMPLATEEX..cDlgItems shl 16 + DLGITEMTEMPLATEEX..items
	arrange line,=DLGITEMTEMPLATEEX..val =DLGITEMTEMPLATEEX line
	assemble line
end calminstruction

calminstruction (NAMED) DLGITEMTEMPLATEEX line&
	local var,val,rest,final
	compute DLGITEMTEMPLATEEX..items,1+DLGITEMTEMPLATEEX..items

; Problems with this technique:
; - duplicate assignments are not prevented, only the last part:value applies
;   low chance? n^2 solution or another abstraction for O(n)
;   default value use is the same, combine?
;   find a solution that generates useful error messages?

	arrange line,line=,
more:	arrange rest,
	match part:value=,rest?,line,<>
	jno error
	transform part,DLGITEMTEMPLATEEX
	jno error
	match part:value=,rest?,line,<>
	arrange var,=DLGITEMTEMPLATEEX.part
	publish :var,value
	arrange var,=restore var
	take final,var

	match , rest
	jyes done
	match line,rest
	jyes more
error:
	stringify line
	display 10
	display line
	err
	exit
done:
	arrange line, =align 4
	assemble line
	arrange line, NAMED:
	assemble line
	arrange line, =namespace NAMED
	assemble line

	emit 4,DLGITEMTEMPLATEEX.helpID
	emit 4,DLGITEMTEMPLATEEX.exStyle
	emit 4,DLGITEMTEMPLATEEX.style
	emit 2,DLGITEMTEMPLATEEX.x
	emit 2,DLGITEMTEMPLATEEX.y
	emit 2,DLGITEMTEMPLATEEX.cx
	emit 2,DLGITEMTEMPLATEEX.cy
	emit 4,DLGITEMTEMPLATEEX.id
	transform DLGITEMTEMPLATEEX.windowClass,DLGITEMTEMPLATEEX.windowClass
	call sz_Or_Ord,DLGITEMTEMPLATEEX.windowClass
	call sz_Or_Ord,DLGITEMTEMPLATEEX.title

	compute val,$
	emit 2,0 ; extraCount
	match , DLGITEMTEMPLATEEX.extraData
	jno extra
	check DLGITEMTEMPLATEEX.extraCount
	jno dend
	arrange line, =extraData:
	assemble line
	emit DLGITEMTEMPLATEEX.extraCount,0 ; empty space
	jump chk
extra:
	arrange line,DLGITEMTEMPLATEEX.extraData
	assemble line
chk:	store val-$$, 2, $-val-2
	compute val, $-val-2
	check DLGITEMTEMPLATEEX.extraCount
	jno dend
	; if explicit data must match given size
	check DLGITEMTEMPLATEEX.extraCount = val
	jyes dend
	display 'ERROR: extraCount does not equal dialog extra data bytes'
	display 10
dend:
	arrange line, =end =namespace
	assemble line

fin:	assemble final
	take , final
	take final,final
	jyes fin
end calminstruction
;
; Several ways to specify extra data:
;
;   A. Assembled command generates output and size is calculated automatically:
;	extraData: db '0123456789'
;	extraData: file 'kctl.ico'
;
;   B. Assembled command generated data is checked against expected size:
;	extraCount:5, extraData: db '01234'
;	extraCount:128, extraData: file 'taco.bin'
;
;   C. Space is reversed for the item - perhaps later modification:
;	extraCount:64

;-------------------------------------------------------------------------------
define DLGTEMPLATEEX ; default values
define DLGTEMPLATEEX.dlgVer		1
define DLGTEMPLATEEX.signature		0xFFFF
define DLGTEMPLATEEX.helpID		0
define DLGTEMPLATEEX.exStyle		0
define DLGTEMPLATEEX.style		0
define DLGTEMPLATEEX.cDlgItems		0
define DLGTEMPLATEEX.x			0
define DLGTEMPLATEEX.y			0
define DLGTEMPLATEEX.cx			0
define DLGTEMPLATEEX.cy			0
define DLGTEMPLATEEX.menu		''
define DLGTEMPLATEEX.windowClass	''
define DLGTEMPLATEEX.title		''
define DLGTEMPLATEEX.pointsize		0
define DLGTEMPLATEEX.weight		0
define DLGTEMPLATEEX.italic		0
define DLGTEMPLATEEX.charset		0
define DLGTEMPLATEEX.typeface		''

DLGTEMPLATEEX..cDlgItems = 0 ; internal for auto item counts

; Extra features:
;	+ implied DS_SETFONT when typeface defined
;
; TODO: give each element their name?

calminstruction (NAMED) DLGTEMPLATEEX line&
	local var,val,rest,final

	; set the constant item count of last dialog
	check DLGTEMPLATEEX..cDlgItems
	jno first
	check DLGITEMTEMPLATEEX..items
	jyes some
	display 'ERROR: dialog template missing items'
	display 10
some:
	compute val,DLGTEMPLATEEX..cDlgItems
	arrange var,=DLGTEMPLATEEX..#val =:== =DLGITEMTEMPLATEEX..=items
	assemble var
	compute DLGITEMTEMPLATEEX..items,0
first:
	arrange line,line=,
more:	arrange rest,
	match part:value=,rest?,line,<>
	jno error
	transform part,DLGTEMPLATEEX
	jno error
	match part:value=,rest?,line,<>
	arrange var,=DLGTEMPLATEEX.part
	publish :var,value
	arrange var,=restore var
	take final,var

	match , rest
	jyes done
	match line,rest
	jyes more
error:
	stringify line
	display 10
	display line
	err
	exit
done:
	compute val,DLGTEMPLATEEX.style or DS_SETFONT
	match '',DLGTEMPLATEEX.typeface
	jno force_font
	compute var,DLGTEMPLATEEX.pointsize+DLGTEMPLATEEX.weight+DLGTEMPLATEEX.italic+DLGTEMPLATEEX.charset
	check var
	jyes force_font
	compute val,DLGTEMPLATEEX.style
force_font:
	compute var,DLGTEMPLATEEX.cDlgItems
	match 0,DLGTEMPLATEEX.cDlgItems
	jno user
	; if user didn't bypass, reference forward constant
	compute DLGTEMPLATEEX..cDlgItems,1+DLGTEMPLATEEX..cDlgItems
	compute var,DLGTEMPLATEEX..cDlgItems
	arrange var,=DLGTEMPLATEEX..#var
user:
	arrange line, NAMED:
	assemble line
	arrange line, =namespace NAMED
	assemble line

	emit 2,DLGTEMPLATEEX.dlgVer
	emit 2,DLGTEMPLATEEX.signature
	emit 4,DLGTEMPLATEEX.helpID
	emit 4,DLGTEMPLATEEX.exStyle
	emit 4,val ; style
	emit 2,var ; cDlgItems
	emit 2,DLGTEMPLATEEX.x
	emit 2,DLGTEMPLATEEX.y
	emit 2,DLGTEMPLATEEX.cx
	emit 2,DLGTEMPLATEEX.cy
	call sz_Or_Ord,DLGTEMPLATEEX.menu
	call sz_Or_Ord,DLGTEMPLATEEX.windowClass
	arrange var, =du =DLGTEMPLATEEX.=title,0
	assemble var

	check val and DS_SETFONT ; or DS_SHELLFONT, optional part
	jno skip_font
	emit 2,DLGTEMPLATEEX.pointsize
	emit 2,DLGTEMPLATEEX.weight
	emit 1,DLGTEMPLATEEX.italic
	emit 1,DLGTEMPLATEEX.charset
	arrange line, =du =DLGTEMPLATEEX.=typeface,0
	assemble line
skip_font:
	arrange line, =end =namespace
	assemble line

fin:	assemble final
	take , final
	take final,final
	jyes fin
end calminstruction

postpone ; set the constant item count of last dialog
repeat 1,i:DLGTEMPLATEEX..cDlgItems
	if i & DLGITEMTEMPLATEEX..items = 0
		display 'ERROR: dialog template missing items',10
	end if
	DLGTEMPLATEEX..#i := DLGITEMTEMPLATEEX..items
end repeat
end postpone

; ACCEL
;		CreateAcceleratorTableA
;		CreateAcceleratorTableW

; MENUEX_TEMPLATE_HEADER
; MENUEX_TEMPLATE_ITEM
;		LoadMenuIndirectA
;		LoadMenuIndirectW

; Ideas considered, implemented and then removed:
;  - Per-class default style/exStyle: hides settings and future errors.
;	(solution) Create a local constant to cover the common styling.
;

;-------------------------------------------------------------------------------
; The evolution of dialog templates (Raymond Chen):
;
;  + 16-bit Classic Templates
;	https://devblogs.microsoft.com/oldnewthing/20040618-00/?p=38803
;  + 16-bit Extended Templates (Windows 95/98/Me)
;	https://devblogs.microsoft.com/oldnewthing/20040622-00/?p=38773
;  + 32-bit Classic Templates
;	https://devblogs.microsoft.com/oldnewthing/20040621-00/?p=38793
;  + 32-bit Extended Templates
;	https://devblogs.microsoft.com/oldnewthing/20040623-00/?p=38753
;-------------------------------------------------------------------------------
