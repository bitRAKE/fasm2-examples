; http://msdn.microsoft.com/en-us/library/bb760435.aspx
include '..\windows.g'
include '..\controls.h'

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

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_BAR_CLASSES
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the Toolbar Bar control.
	CreateWindowExW 0, W "ToolbarWindow32", 0, WS_CHILD or WS_VISIBLE \
		or TBSTYLE_FLAT or CCS_ADJUSTABLE or CCS_NODIVIDER,\
		0,0,0,0, [.hDialog], IDC_TOOLBAR, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hToolbar], rax

	; Use system-defined images ...
{const:8} .tbAddBmp TBADDBITMAP hInst: HINST_COMMCTRL, nID: IDB_STD_LARGE_COLOR
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
				{const:2} .%.str du TEXT,0
			end match
		end repeat
		indx 1
		{const:8} label .tbButtons:%%
	end if
	{const:8} .% TBBUTTON iBitmap: BITMAP, fsState: STATE,\
		fsStyle: STYLE, iString: .%.str
end iterate
