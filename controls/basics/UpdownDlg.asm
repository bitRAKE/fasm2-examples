; http://msdn.microsoft.com/en-us/library/bb759880.aspx
include '..\windows.g'
include '..\controls.h'

extrn "DialogProcW.WM_CLOSE" as UpdownDlgProc.WM_CLOSE

public UpdownDlgProc
:UpdownDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jnz @0F

virtual at rbp + 16 ; only shadow space
	.hDlg		dq ?
	.hEdit		dq ?
end virtual
	enter .frame, 0
	mov [.hDlg], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_UPDOWN_CLASS
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

	CreateWindowExW WS_EX_CLIENTEDGE, W "EDIT", 0, WS_CHILD or WS_VISIBLE,\
		20, 20, 100, 24, [.hDlg], IDC_EDIT, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hEdit], rax

	CreateWindowExW 0, W "msctls_updown32", 0, WS_CHILD or WS_VISIBLE\
		or UDS_ALIGNRIGHT or UDS_SETBUDDYINT or UDS_WRAP or UDS_ARROWKEYS or UDS_HOTTRACK,\
		0, 0, 0, 0, [.hDlg], IDC_UPDOWN, __ImageBase, 0
	xchg rcx, rax
	jrcxz @F

	; Explicitly attach the Updown control to its 'buddy' edit control.
	; ... and auto-size to buddy control.
	SendMessageW rcx, UDM_SETBUDDY, [.hEdit], 0
@@:	leave
@0:	xor eax, eax
	retn
