; http://msdn.microsoft.com/en-us/library/bb760435.aspx
include '..\windows.g'
include '..\controls.h'

; TODO: setting sizing to show additional buttons without wrapping
; just send TB_AUTOSIZE?

TB_ADDBUTTONSW := WM_USER + 68
extrn 'DialogProcW.WM_CLOSE' as ToolbarDlgProc.WM_CLOSE

public ToolbarDlgProc
:ToolbarDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp + 16 ; only shadow space
		.hDialog	dq ?
		.hToolbar	dq ?
		.rc		RECT
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_BAR_CLASSES
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the Toolbar Bar control.
{const}	.ToolbarWindow32 du "ToolbarWindow32",0
	CreateWindowExW 0, .ToolbarWindow32, 0, WS_CHILD or WS_VISIBLE \
		or TBSTYLE_FLAT or CCS_ADJUSTABLE or CCS_NODIVIDER,\
		0,0,0,0, [.hDialog], IDC_TOOLBAR, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hToolbar], rax

;	SendMessageW [.hToolbar], TB_SETBITMAPSIZE , 0, 0x0040_0040 ; 64x64

	; Use system-defined images ...
	{const} .tbAddBmp TBADDBITMAP hInst: HINST_COMMCTRL, nID: IDB_STD_LARGE_COLOR
	SendMessageW [.hToolbar], TB_ADDBITMAP, 0, addr .tbAddBmp

	; Different DLL versions have different default button structure
	; size - set the size being used.
	SendMessageW [.hToolbar], TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0

	; Set the buttons.
	SendMessageW [.hToolbar], TB_ADDBUTTONSW, sizeof .tbButtons, addr .tbButtons

	; Tell the toolbar to resize itself, and show it.
	SendMessageW [.hToolbar], TB_AUTOSIZE, 0, 0
	mov eax, 1
@@:	leave
	retn

iterate <BITMAP,	STATE,		STYLE,			TEXT>,\
	STD_FILENEW,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"New",\
	STD_FILEOPEN,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Open",\
	STD_FILESAVE,	0,		TBSTYLE_AUTOSIZE,	"Save",\
	0,		0,		TBSTYLE_SEP,		,\; Separator
	STD_CUT,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Cut",\
	STD_COPY,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Copy",\
	STD_PASTE,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Paste",\
	STD_DELETE,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Delete",\
	0,		0,		TBSTYLE_SEP,		,\; Separator
	STD_UNDO,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Undo",\
	STD_REDOW,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Redo",\
	STD_FIND,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Find",\
	STD_REPLACE,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Replace",\
	0,		0,		TBSTYLE_SEP,		,\; Separator
	STD_PROPERTIES,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Properties",\
	STD_HELP,	TBSTATE_ENABLED,TBSTYLE_AUTOSIZE,	"Help"

	if % = 1
		repeat %%
			indx %
			match ,TEXT
				.%.str = 0
			else
				{const} .%.str du TEXT,0
			end match
		end repeat
		indx 1
		{const} align 8
		{const} label .tbButtons:%%
	end if
	{const} .% TBBUTTON iBitmap: BITMAP, fsState: STATE,\
		fsStyle: STYLE, iString: .%.str
end iterate


; TODO: advanced usage:
;	customization dialog
;	save/restore state (moveable/toggle)
;	drop-down menus
;	multi-size selection
;	rebar hosted
if 0
; Remove all of the existing buttons, starting with the last one.
:Toolbar__RemoveButtons:
	virtual at rbp + 16 ; only shadow space
		.hToolbar	dq ?
		.count		dd ?
	end virtual
	enter .frame, 0
	mov [.hToolbar], rcx
	SendMessageW rcx, TB_BUTTONCOUNT, 0, 0
	mov [.count], eax
	jmp .try
.more:
	SendMessageW [.hToolbar], TB_DELETEBUTTON, [.count], 0
.try:
	dec [.count]
	jns .more
	leave
	retn


:Toolbar__AddButtons: ;(int sizeButtons){
	virtual at rbp + 16 ; only shadow space
		.hToolbar	dq ?
		.count		dd ?
	end virtual

	; select from images sizes
	SendMessageW [.hToolbar], TB_SETIMAGELIST, 0, [g_hImageLists + r9*8]

	SendMessageW [.hToolbar], TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
	SendMessageW [.hToolbar], TB_ADDBUTTONS, numButtons, &tbButtons

	// Resize the toolbar
	SendMessageW [.hToolbar], TB_AUTOSIZE, 0, 0
	leave
	retn

end if
