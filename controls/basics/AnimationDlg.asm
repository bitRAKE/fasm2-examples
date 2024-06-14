; https://learn.microsoft.com/en-us/windows/win32/controls/animation-control-reference
include '..\windows.g'
include '..\controls.h' ; IDs

extrn DialogProcW.WM_CLOSE

public AnimationDlgProc
:AnimationDlgProc:
	cmp edx, WM_CLOSE
	jz DialogProcW.WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp + 16 ; only shadow space
		.hDlg		dq ?
		.hAnimate	dq ?
	end virtual
	enter .frame, 0
	mov [.hDlg], rcx
	SetWindowTextW rcx, r9 ; parent has given name

	; Load and register animation control class.
{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_ANIMATE_CLASS
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the animation control.
{const} .SysAnimate32 du 'SysAnimate32',0
	CreateWindowExW 0, dword .SysAnimate32, 0, WS_CHILD or WS_VISIBLE\
		or ACS_TIMER or ACS_AUTOPLAY or ACS_TRANSPARENT,\
		20, 20, 280, 60, [.hDlg], IDC_ANIMATION, __ImageBase, 0
	xchg rcx, rax ; hAnimate
	jrcxz @F

	; Open the AVI clip and display its first frame in the animation control.
	mov [.hAnimate], rcx
	SendMessageW rcx, ACM_OPEN, 0, IDR_UPLOAD_AVI
	xchg rcx, rax ; BOOL?
	jrcxz @F

	; Plays the AVI clip in the animation control.
	SendMessageW [.hAnimate], ACM_PLAY, -1, 0x0000_FFFF
@@:	leave
	xor eax, eax
	retn
