; http://msdn.microsoft.com/en-us/library/bb759988.aspx
include '..\windows.g'
include '..\controls.h'

extrn SHELL32__Icons2ImageList
extrn 'FirstChild2ClientW.WM_SIZE' as TreeviewDlgProc.WM_SIZE

public TreeviewDlgProc
:TreeviewDlgProc:
	iterate message, WM_SIZE,WM_CLOSE,WM_INITDIALOG
		cmp edx, message
		jz .message
	end iterate
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp + 16 ; only shadow space
		.hDialog	dq ?
		.hTreeView	dq ?
		.rc		RECT
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_TAB_CLASSES
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the Tab control to fill client area.
	GetClientRect [.hDialog], addr .rc
{const}	.SysTreeView32 du "SysTreeView32",0
	CreateWindowExW 0, .SysTreeView32, 0, WS_CHILD or WS_VISIBLE \
		or TVS_HASLINES or TVS_LINESATROOT or TVS_HASBUTTONS,\
		[.rc.left], [.rc.top], [.rc.right], [.rc.bottom],\
		[.hDialog], IDC_TREEVIEW, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hTreeView], rax

{const} .tree_icons dw \
\;	normal	selected
	4,	146,\	; folder
	1,	21,\	; file
	184,	174,\	; display
	16775,	261,\	; options
	194,	48,\	; key/lock
	200,	240,\	; 0/X
	14,	276,\	; earth
	0

	label .cx:4 at .hDialog
	GetSystemMetrics SM_CXSMICON
	mov [.cx], eax
	GetSystemMetrics SM_CYSMICON
	xchg ecx, [.cx]
	xchg edx, eax
	lea r8, [.tree_icons]
	call SHELL32__Icons2ImageList
	jz @F ; fail
	SendMessageW [.hTreeView], TVM_SETIMAGELIST, TVSIL_NORMAL, rax

{data}	.tvis TVINSERTSTRUCT \
	itemex: <mask: TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE>

	iterate <TEXT,		IMAGE,		PARENT>,\
		"First", 	0,		TVI_ROOT,\
		"Level 1A", 	1,		-,\
		"Level 1B", 	2,		|,\
		"Level 1C", 	3,		|,\
		"Level 2C", 	4,		-,\
		"Level 3C", 	5,		-,\
		"Level 3D", 	6,		|,\
		"Second", 	0,		TVI_ROOT,\
		"Third", 	0,		TVI_ROOT,\
		"Fourth", 	0,		TVI_ROOT,\
		"Fifth", 	0,		TVI_ROOT

		{const} .% du TEXT,0

		mov [.tvis.itemex.pszText], .%
		; note: cchTextMax member ignored on setting text
		mov [.tvis.itemex.iImage], IMAGE*2+0
		mov [.tvis.itemex.iSelectedImage], IMAGE*2+1

		match -, PARENT ; deeper
			mov [.tvis.hParent], rax
		else match |, PARENT ; continue last parent
;			mov [.tvis.hInsertAfter], rax
;			mov [.tvis.hInsertAfter], POSITION
		else
			mov [.tvis.hParent], PARENT
		end match

		SendMessageW [.hTreeView], TVM_INSERTITEMW, 0, addr .tvis
		; RAX, HTREEITEM gets used in next iteration
	end iterate
@@:	leave
	xor eax, eax
	retn


:TreeviewDlgProc.WM_CLOSE:
	enter .frame, 0
	label .hDialog:8 at rbp + 16 ; use shadow space
	mov [.hDialog], rcx
	GetDlgItem rcx, IDC_TREEVIEW
	xchg rcx, rax
	jrcxz @F
	SendMessageW rcx, TVM_GETIMAGELIST, TVSIL_NORMAL, 0
	ImageList_Destroy rax
	EndDialog [.hDialog], 0
@@:	xor eax, eax
	leave
	retn



; advanced features:
;	TVITEMEX.iIntegral
;	edit item labels
;	tooltips
;	drag/drop
