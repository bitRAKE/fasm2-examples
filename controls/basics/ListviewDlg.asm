; http://msdn.microsoft.com/en-us/library/bb774737.aspx
include '..\windows.g'
include '..\controls.h'

extrn SHELL32__Icons2ImageList

; resources belonging to window
struct LVHandles
	hHeap		dq ?	; HANDLE
	hLargeIcons	dq ?	; HIMAGELIST
	hSmallIcons	dq ?	; HIMAGELIST
ends

public ListviewDlgProc
:ListviewDlgProc:
	iterate message, WM_SIZE,WM_CLOSE,WM_INITDIALOG
		cmp edx, message
		jz .message
	end iterate
	xor eax, eax
	retn

.WM_INITDIALOG:
	push rdi rsi rbx
	virtual at rbp - .local
		.hIcon		dq ?
		.lvi		LVITEMW
		.id		dd ?,?
;				align.assume rbp,16
;				align 16|8 ; :BUG: |8 not working
		.local := $ - $$
		assert .local and 15 = 8
				rq 5 ; old registers and return
		.hDialog	dq ?
		.hListview	dq ?
		.rc		RECT
	end virtual
	enter .frame + .local, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

	; Load and register ComboBoxEx control class.
{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_LISTVIEW_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

	; allocate memory for list view resources
	GetProcessHeap
	xchg rbx, rax ; preserve hHeap
	HeapAlloc rbx, HEAP_GENERATE_EXCEPTIONS, sizeof LVHandles
	test rax, rax
	jz @F
	xchg rbx, rax ; use the RBX register to simplify the remaining code
	virtual at RBX
		.lvh LVHandles
	end virtual
	mov [.lvh.hHeap], rax

; Create the Listview control filling parent window.

	GetClientRect [.hDialog], addr .rc
{const} .SysListView32 du "SysListView32",0
	CreateWindowExW 0, .SysListView32, 0, WS_CHILD or WS_VISIBLE \
		or LVS_SHOWSELALWAYS or LVS_AUTOARRANGE,\;or LVS_ICON 
		[.rc.left], [.rc.top], [.rc.right], [.rc.bottom],\
		[.hDialog], IDC_LISTVIEW, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hListview], rax

; create & prepare image lists with icons from the resource:
; note: last applied image list is the style. Yes, regardless of style set during creation.

{const} .list_icons dw 4,20,39,46,172,210,267,16715,16781,16784,16804,16806,37219,0 ; TERMINATOR
	.icons := 13

	GetSystemMetrics SM_CXSMICON
	mov esi, eax
	GetSystemMetrics SM_CYSMICON
	xchg ecx, esi
	xchg edx, eax
	lea r8, [.list_icons]
	call SHELL32__Icons2ImageList
	jz @F ; fail
	mov [.lvh.hSmallIcons], rax
	SendMessageW [.hListview], LVM_SETIMAGELIST, LVSIL_NORMAL, [.lvh.hSmallIcons]

	GetSystemMetrics SM_CXICON
	mov esi, eax
	GetSystemMetrics SM_CYICON
	xchg ecx, esi
	xchg edx, eax
	lea r8, [.list_icons]
	call SHELL32__Icons2ImageList
	jz @F ; fail
	mov [.lvh.hLargeIcons], rax
	SendMessageW [.hListview], LVM_SETIMAGELIST, LVSIL_NORMAL, [.lvh.hLargeIcons]

; Done with resource pointers, store in windows for use later.

	SetWindowLongPtrW [.hDialog], GWLP_USERDATA, rbx

; Add items to the the list view common control.

{data}	.item_text du "Item XX",0
{const} .10 dd 10
	xor esi, esi
	xor edx, edx
	xor ebx, ebx
	mov [.lvi.iItem], 0x0FFF_FFFF ; add items as last
	mov [.lvi.mask], LVIF_TEXT or LVIF_IMAGE
	mov [.lvi.pszText], .item_text
	mov [.lvi.iSubItem], 0 ; indicate item, not subitem
.fill_list:
	inc esi
	mov eax, esi		; 1-based, display
	div [.10]
	lea rdi, [.item_text + 5*2]
	test eax, eax
	jz @1F
	add eax, '0'
	stosw
@1:	lea eax, [rdx + '0']
	stosd ; digit and terminator

	mov [.lvi.iImage], ebx ; 0-based, image indexing
	inc ebx
	SendMessageW [.hListview], LVM_INSERTITEMW, 0, addr .lvi ;?:BUG:-1

	xor edx, edx
	cmp ebx, .icons
	cmovz ebx, edx ; wrap icon indices

	cmp esi, .icons * 7
	jnz .fill_list

@@:	leave
	pop rbx rsi rdi
	xor eax, eax
	retn


:ListviewDlgProc.WM_SIZE:
	enter .frame, 0
	label .hListview:8	at rbp + 16 ; using shadow space
	label .lParam:8		at rbp + 16 + 8
	mov [.lParam], r9 ; preserve: cx, cy

	GetDlgItem rcx, IDC_LISTVIEW
	xchg rcx, rax
	jrcxz @F
	mov [.hListview], rcx

	; Resize the listview control to fill the parent window's client area
	movzx r9d, word [.lParam]
	movzx eax, word [.lParam + 2]
	MoveWindow rcx, 0, 0, r9d, eax, 1

	; Arrange contents of listview along top of control
;	SendMessageW [.hListview], LVM_ARRANGE, LVA_ALIGNTOP, 0
@@:	xor eax, eax
	leave
	retn


; note: unless LVS_SHAREIMAGELISTS is used the control automatically
; destroys the image lists on control destruction
:ListviewDlgProc.WM_CLOSE:
	enter .frame, 0
	label .hDialog:8 at rbp + 16 ; using shadow space
	label .lvh:8	 at rbp + 24
	mov [.hDialog], rcx
	; Get the pointer to listview information which was previously
	; stored in the user data associated with the parent window.
	GetWindowLongPtrW rcx, GWLP_USERDATA
	xchg rcx, rax
	jrcxz @F
	mov [.lvh], rcx
	ImageList_Destroy [rcx + LVHandles.hLargeIcons]
	mov rcx, [.lvh]
	ImageList_Destroy [rcx + LVHandles.hSmallIcons]
	mov r8, [.lvh]
	HeapFree [r8 + LVHandles.hHeap], 0, r8
@@:	EndDialog [.hDialog], 0
	xor eax, eax
	leave
	retn


if used SetListViewViewMode
; internal convention
;	call SetListViewViewMode, [.hListView], [.dwView]
:SetListViewViewMode: ; HWND hListView, DWORD dwView
	virtual at rbp+16
		.hListView	dq ?
		.dwView		dd ?,?
		.param_bytes := $-$$
	end virtual
	enter .frame, 0
	and [.dwView], LVS_TYPEMASK ; filter input
	GetWindowLongW [.hListView], GWL_STYLE
	and eax, not LVS_TYPEMASK
	or eax, [.dwView]
	xchg r8d, eax
	SetWindowLongW [.hListView], GWL_STYLE, r8d
	leave
	retn .param_bytes
end if
