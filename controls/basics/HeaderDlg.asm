; http://msdn.microsoft.com/en-us/library/bb775239.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as HeaderDlgProc.WM_CLOSE

public HeaderDlgProc
:HeaderDlgProc:
	iterate message, WM_SIZE,WM_CLOSE,WM_INITDIALOG
		cmp edx, message
		jz .message
	end iterate
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp - .local
		.hdi		HD_ITEMW
				align.assume rbp,16
				align 16
		.local := $ - $$
				rq 2 ; old RBP and return
		.hDialog	dq ?
		.hHeader	dq ?
		.rc		RECT
			assert $-$$-.local <= 8*6 ; shadow space restriction
	end virtual
	enter .frame + .local, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

	; Load and register Header control class.
{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_LISTVIEW_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the Header control.
	; Note: no WS_VISIBLE here, sizing will show control.
{const}	.SysHeader32 du "SysHeader32",0
	CreateWindowExW 0, dword .SysHeader32, 0, WS_CHILD or WS_VISIBLE \
		or HDS_HORZ or HDS_BUTTONS or HDS_DRAGDROP or HDS_HOTTRACK,\
		0, 0, 0, 0, [.hDialog], IDC_HEADER, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hHeader], rax

	GetClientRect [.hDialog], addr .rc

	; satisfy internal requirements (see function below)
	mov rcx, [.hDialog]
	mov r9d, [.rc.bottom - 2] ; high word
	mov r9w, word [.rc.right] ; low word
	call .WM_SIZE ; size header to client using header layout

	mov [.hdi.mask], HDI_WIDTH or HDI_FORMAT or HDI_TEXT
	mov [.hdi.fmt], HDF_CENTER
	; note: cchTextMax member not used on intert/set of text
	mov eax, [.rc.right]
	xor edx, edx
	mov ecx, .hitems
	div ecx
	mov [.hdi.cxy], eax ; width
	repeat 5 ; add header items
{const}		.% du "Header ",`%,0
		if % = %%
			.hitems := %%
			repeat %%
				mov [.hdi.pszText], .%
				SendMessageW [.hHeader], HDM_INSERTITEMW, %-1, addr .hdi
			end repeat
		end if
	end repeat
	GetStockObject DEFAULT_GUI_FONT ; isn't this default?
	SendMessageW [.hHeader], WM_SETFONT, rax, 0
	xor eax, eax
@@:	leave
	retn


; Note: this doesn't size the parts beyond the initial. Yet, individual parts
; can be configured with, hdi.mask = HDI_WIDTH.
:HeaderDlgProc.WM_SIZE: ; called internally (above)
	virtual at rbp - .local
		.wp		WINDOWPOS
		.hHeader	dq ?
				align.assume rbp,16
				align 16
		.local := $ - $$
				rq 2 ; old RBP and return
		.hdl		HD_LAYOUT
		.rc		RECT
			assert $-$$-.local <= 8*6 ; shadow space restriction
	end virtual
	enter .frame + .local, 0
	movzx eax, r9w
	shr r9d, 16
	mov [.rc.right], eax	; cx, width
	mov [.rc.bottom], r9d	; cy, height

	GetDlgItem rcx, IDC_HEADER
	xchg rcx, rax
	jrcxz @F
	mov [.hHeader], rcx

	lea rax, [.rc]
	and qword [rax], 0	; clear left/top
	mov [.hdl.prc], rax	; input retangle
	lea rax, [.wp]
	mov [.hdl.pwpos], rax	; output location/size of header control

	SendMessageW rcx, HDM_LAYOUT, 0, addr .hdl	
	add [.wp.cy], 8 ; taller
	SetWindowPos [.hHeader], [.wp.hwndInsertAfter],\
		[.wp.x], [.wp.y], [.wp.cx], [.wp.cy], [.wp.flags]
@@:	xor eax, eax
	leave
	retn
