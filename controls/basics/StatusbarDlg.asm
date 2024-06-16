; http://msdn.microsoft.com/en-us/library/bb760726.aspx
include '..\windows.g'
include '..\controls.h'

extrn "DialogProcW.WM_CLOSE" as StatusbarDlgProc.WM_CLOSE

public StatusbarDlgProc
:StatusbarDlgProc:
	cmp edx, WM_SIZE
	jz .WM_SIZE
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp + 16 ; only shadow space
		.hDialog	dq ?
		.hStatusbar	dq ?
		.rc		RECT
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_BAR_CLASSES
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the Status Bar control, size ignored.

	CreateWindowExW 0, W "msctls_statusbar32", 0,\
		WS_CHILD or WS_VISIBLE or SBARS_SIZEGRIP,\
		0,0,0,0, [.hDialog], IDC_STATUSBAR, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hStatusbar], rax

	GetClientRect [.hDialog], addr .rc
	mov rcx, [.hDialog]
	mov r9w, word [.rc.right]
	call .WM_SIZE ; common status bar sizing below

	; Put some texts into each part of the status bar and setup each part
	iterate <STYLE, TEXT>,\
		0,		"Status Bar: Part 1",\; appears lower
		SBT_POPOUT,	"Part 2",\
		SBT_NOBORDERS,	"Part 3",\
		SBT_POPOUT,	"Part 4"

		SendMessageW [.hStatusbar], SB_SETTEXTW, STYLE or (%-1), W TEXT
	end iterate
@@:	leave
	xor eax, eax
	retn


:StatusbarDlgProc.WM_SIZE:
	virtual at rbp + 16 ; use shadow space
		.hDialog	dq ?
		.hStatusbar	dq ?
	label	.nParts:4
				rd sizeof .nParts
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx

	; build array of partition corrdinates based off client width:
	movzx eax, r9w
	shr eax, 1 ; half
	mov [.nParts + 4*0], eax	; 1/2
	mov ecx, eax
	mov edx, 0x5555_5556		; 1/3 * 1/2
	mul edx
	lea eax, [rcx + rdx*2]
	add edx, ecx
	mov [.nParts + 4*1], edx	; 1/2 + 1/6
	mov [.nParts + 4*2], eax	; 1/2 + 2/6
	mov [.nParts + 4*3], -1		; end (1/2 + 3/6 = 1)

	GetDlgItem [.hDialog],IDC_STATUSBAR
	xchg rcx, rax
	jrcxz @F
	mov [.hStatusbar], rcx

	; Partition the statusbar here to keep the ratio of the sizes of its parts constant. Each part is set by specifing the coordinates of the right edge of each part. -1 signifies the rightmost part of the parent.
	SendMessageW rcx, SB_SETPARTS, sizeof .nParts, addr .nParts

	; Resize statusbar so it's always same width as parent's client area.
	SendMessageW [.hStatusbar], WM_SIZE, 0, 0
@@:	leave
	xor eax, eax
	retn
