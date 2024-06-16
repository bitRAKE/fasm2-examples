; http://msdn.microsoft.com/en-us/library/bb774375.aspx
include '..\windows.g'
include '..\controls.h'

extrn "DialogProcW.WM_CLOSE" as RebarDlgProc.WM_CLOSE

public RebarDlgProc
:RebarDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp + 16 ; only shadow space
		.hDialog	dq ?
		.hRebar		dq ?
		.rc		RECT
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_COOL_CLASSES
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the ReBar control.
	CreateWindowExW WS_EX_TOOLWINDOW, W "ReBarWindow32", 0, WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or WS_VISIBLE \
		or RBS_VARHEIGHT or CCS_NODIVIDER or CCS_TOP or RBS_AUTOSIZE,\
		0,0,0,0, [.hDialog], IDC_REBAR, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hRebar], rax

; if used, configure rebar for image list first
;{data}	.ri REBARINFO cbSize: sizeof .ri;, fMask: RBIM_IMAGELIST
;	SendMessageW [.hRebar], RB_SETBARINFO, 0, addr .ri

	CreateWindowExW 0, W "STATIC", 0, WS_CHILD or WS_VISIBLE or SS_ICON or SS_REALSIZEIMAGE or SS_NOTIFY,\
		0, 0, 0, 0, [.hRebar], 0, __ImageBase, 0
	label .hStatic:8 at .rbBand.hwndChild
	mov [.hStatic], rax
	LoadImageW 0, IDI_QUESTION, IMAGE_ICON, 0, 0, LR_SHARED
	SendMessageW [.hStatic], STM_SETICON, rax, 0

; insert bands ...

{data:8} .rbBand REBARBANDINFOW cbSize: sizeof .rbBand,\
		fMask: RBBIM_STYLE or RBBIM_CHILDSIZE or RBBIM_CHILD or RBBIM_SIZE,\
		fStyle: RBBS_CHILDEDGE or RBBS_NOGRIPPER,\
		cxMinChild: 0, cyMinChild: 20, cx: 20

	; Insert the img into the rebar.
	SendMessageW [.hRebar], RB_INSERTBAND, -1, addr .rbBand

	; Insert a blank band.
	mov [.rbBand.fMask], RBBIM_STYLE or RBBIM_SIZE
	mov [.rbBand.fStyle], RBBS_CHILDEDGE or RBBS_HIDETITLE or RBBS_NOGRIPPER
	mov [.rbBand.cx], 1

	; Insert the blank band into the rebar.
	SendMessageW [.hRebar], RB_INSERTBAND, -1, addr .rbBand
	mov eax, 1
@@:	leave
	retn
