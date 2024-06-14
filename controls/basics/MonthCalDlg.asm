; http://msdn.microsoft.com/en-us/library/bb760917.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as MonthCalDlgProc.WM_CLOSE
extrn "FirstChild2ClientW.WM_SIZE" as MonthCalDlgProc.WM_SIZE

public MonthCalDlgProc
:MonthCalDlgProc:
	iterate message, WM_SIZE,WM_CLOSE,WM_INITDIALOG
		cmp edx, message
		jz .message
	end iterate
	xor eax, eax
	retn

.WM_INITDIALOG:
	enter .frame, 0
	label .hDialog:8 at rbp + 16 ; only shadow space
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_DATE_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @0F

{const}	.SysMonthCal32 du "SysMonthCal32",0
	CreateWindowExW 0, dword .SysMonthCal32, 0, WS_CHILD or WS_VISIBLE,\
		20, 20, 280, 200, [.hDialog], IDC_MONTHCAL, __ImageBase, 0
	test rax, rax
	jz @0F
	mov eax, 1
@0:	leave
	retn
