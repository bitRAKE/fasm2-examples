; http://msdn.microsoft.com/en-us/library/bb760704.aspx
include '..\windows.g'
include '..\controls.h'

extrn "DialogProcW.WM_CLOSE" as SysLinkDlgProc.WM_CLOSE

public SysLinkDlgProc
:SysLinkDlgProc:
	cmp edx, WM_NOTIFY
	jz .WM_NOTIFY
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	label .hDialog:8 at rbp + 16 ; only shadow space
	label .hSysLink:8 at rbp + 24
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_LINK_CLASS
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the simplest SysLink control.

{const}	.refs du 9,"<a>Links</a> can be <a>clicked</a>, or tab",10,\
	"navigated to and selected by <a>keyboard</a>.",0

{const}	.SysLink du "SysLink",0
	CreateWindowExW 0, .SysLink, .refs, WS_CHILD or WS_VISIBLE or WS_TABSTOP,\
		20, 20, 500, 100, [.hDialog], IDC_SYSLINK, __ImageBase, 0
	test rax, rax
	jrcxz @F
	mov [.hSysLink], rax

	GetStockObject DEFAULT_GUI_FONT
	SendMessageW [.hSysLink], WM_SETFONT, rax, 0

	mov eax, 1
@@:	leave
	retn


:SysLinkDlgProc.WM_NOTIFY:
	cmp r8w, IDC_SYSLINK
	jz .IDC_SYSLINK
@@:	xor eax, eax
	retn

.IDC_SYSLINK:
	; control ID might not be unique, so verify further ...

	cmp [r9 + NMHDR.idFrom], IDC_SYSLINK
	jnz @B

	; must also limit by action verb ... (other notifications are sent)

	cmp [r9 + NMHDR.code], NM_CLICK
	jz .NM_CLICK

	lea edx, [.message_return]
	cmp [r9 + NMHDR.code], NM_RETURN
	jz .NM_RETURN
	jmp @B
.NM_CLICK:
	lea edx, [.message_click]
.NM_RETURN:
	enter .frame, 0

{const} .caption du "Link Action",0
{const} .message_click du "Link selection by mouse click.",0
{const} .message_return du "Link selection by keyboard return.",0

	MessageBoxW rcx, rdx, addr .caption, MB_OK

	xor eax, eax
	leave
	retn
