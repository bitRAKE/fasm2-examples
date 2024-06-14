include 'windows.g'
include 'controls.h'
;	+ ID for each main dialog button
;	+ ID for each control instance (might be able to eliminate?)
;	+ ID for needed example resources (try to use system resources)

public WinMainCRTStartup
public DialogProcW.WM_CLOSE ; Dialogs have the same clean up (i.e. none).
public FirstChild2ClientW.WM_SIZE ; no-setup resize of child to fill client area.
;public Ctrl2ClientW.WM_SIZE ; Dialogs are single control containers.
public SHELL32__Icons2ImageList ; shared resource create/append

:WinMainCRTStartup:
	pop rax ; no return
	; modal dialog application, param unused
	DialogBoxParamW dword __ImageBase, IDD_MAINDIALOG, 0, dword DialogProcW
	ExitProcess rax


; common dialog WM_CLOSE
align 16
:DialogProcW.WM_CLOSE:
	enter 32, 0
	xor edx, edx
	EndDialog rcx, edx
	leave
	xor eax, eax
	retn



if 0 ; deprecated
; For situations when the parent window is just a container for a single
; control, this common routine gets the control handle through GWLP_USERDATA
; instead of GetDlgItem - this allows all such windows to use the same
; WM_SIZE handler; but requires SetWindowLongPtrW setup.
;
; Resize control to fill client area of its parent window.
;	extrn 'Ctrl2ClientW.WM_SIZE' as TreeviewDlgProc.WM_SIZE
;	SetWindowLongPtrW [.hDialog], GWLP_USERDATA, [.hControl]

	align 16
:Ctrl2ClientW.WM_SIZE:
	enter .frame, 0
	label .lParam:8 at rbp + 16 ; use shadow space
	mov [.lParam], r9 ; cy:cx

	GetWindowLongPtrW rcx, GWLP_USERDATA ; control handle
	xchg rcx, rax
	jrcxz @F
	movzx r9d, word [.lParam]
	movzx eax, word [.lParam+2]
	MoveWindow rcx, 0, 0, r9d, eax, TRUE
@@:	xor eax, eax
	leave
	retn
end if

; Has the advantage of not needing any setup.
; if a chidl control has a child, which will be first child, DFS?
:FirstChild2ClientW.WM_SIZE:; assume SIZE_RESTORED
	enter .frame, 0
	EnumChildWindows rcx, dword ResizeFirstChild, r9 ; BOOL, not used
	xor eax, eax ; handled
	leave
	retn

:ResizeFirstChild:
	enter .frame, 0
	movzx r9d, dx
	shr edx, 16
	xchg eax, edx
	MoveWindow rcx, 0, 0, r9d, eax, TRUE
	xor eax, eax ; BOOL, stop enumeration
	leave
	retn



; Using shell32.dll icons for application image lists creats a consistent
; appearance within the same version of windows.
;
;	(0,RDX)	: append to existing image list handle RDX
;	ECX,EDX : new image list of dimensions (width and height)
;	R8	: word array of resource IDs to load, null terminated
;
; Image list handle in RAX (responsibility of caller), Zero flag set on error.

:SHELL32__Icons2ImageList:
	virtual at rbp + 16 + 8 ; only shadow space
		.hImages	dq ?
		.hLib		dq ?
	end virtual
	push rsi
	enter .frame + 8, 0
	xchg rsi, r8

	mov [.hImages], rdx
	jrcxz .have_image_list

	ImageList_Create ecx, edx, ILC_COLOR32 or ILC_MASK or ILC_HIGHQUALITYSCALE, 1, 1
	test rax, rax
	jz .fail
	mov [.hImages], rax
.have_image_list:
	LoadLibraryExW dword .shell32, 0, LOAD_LIBRARY_SEARCH_SYSTEM32
	test rax, rax
	jz .fail_hard
	mov [.hLib], rax
	jmp .try
.process:
	movzx edx, ax
	LoadImageW [.hLib], rdx, IMAGE_ICON, 0, 0, LR_SHARED
	test rax, rax
	jz .fail_harder

	ImageList_ReplaceIcon [.hImages], -1, rax
	cmp eax, -1
	jz .fail_harder
.try:
	lodsw
	test ax, ax
	jnz .process
	FreeLibrary [.hLib]
	or eax, 1 ; ZF=0
.fail_hard:
	mov rax, [.hImages]
.fail:	leave
	pop rsi
	retn

.fail_harder:
	FreeLibrary [.hLib]
	xor eax, eax ; ZF=1
	jmp .fail_hard

{const}	.shell32 du "shell32.dll",0



; Use a tool like: https://www.nirsoft.net/utils/iconsext.html
; Folder set: 4,20,39,46,172,210,267,16715,16781,16784,16804,16806,37219
; File set:
; options: ,261,16775
;-------------------------------------------------------------------------------


align 16
:DialogProcW:
	iterate uMsg, WM_COMMAND,WM_CLOSE,WM_INITDIALOG
		cmp edx, uMsg
		jz .uMsg
	end iterate
	xor eax, eax
	retn

.WM_INITDIALOG:
	mov eax, TRUE ; default focus
	retn

.WM_COMMAND:
	enter .frame, 0

	cmp r8w, 1 + IDC_BUTTON_UPDOWN
	jnc .unknown_command
	cmp r8w, IDC_BUTTON_ANIMATION
	jnc .create_modeless_example_dialog

	xor edx, edx
	cmp r8w, IDOK
	jz .IDOK
	inc edx
	cmp r8w, IDCANCEL
	jnz .unknown_command
.IDOK:
	EndDialog rcx, rdx
.unknown_command:
	xor eax, eax ; processed
	leave
	retn
;
; Assemble-time controls are created by the system and can adopt different
; default settings. Getting this behaviour at run-time might requires manually
; configuring the control.
;
;
.create_modeless_example_dialog:

	; TODO: select amongst different versions of controls
	;	- assemble-time, data centric control
	;	- runtime (basic), code centric control
	;	- advanced/complex
	;
	;{const}	.branch du "Assemble-time","Runtime","Advanced"

	movzx eax, r8w
	.offset equ (rax-IDC_BUTTON_ANIMATION)*8

	; create title:
	;	Runtime %s Control

	mov r8, rcx ; parent dialog handle
	CreateDialogParamW __ImageBase, dword IDD_TEMPLATE, r8,\
		[.DlgProc_Table + .offset], [.DlgTitle_Table + .offset]
	jmp .unknown_command

; create data tables needed for example dialog instancing:

; some flexiblity in verbosity
iterate <title,				brief>,\
	'Animation',			Animation,\
	'ComboBoxEx',			ComboBoxEx,\
	'Date and Time Picker',		DateTimePick,\
	'Header',			Header,\
	'IP Address',			IPAddress,\
	'List View',			Listview,\
	'Month Calendar',		MonthCal,\
	'Progress Bar',			Progress,\
	'Rebar',			Rebar,\
	'Status Bar',			Statusbar,\
	'SysLink',			SysLink,\
	'Tab Control',			TabControl,\
	'Toolbar',			Toolbar,\
	'Tooltip',			Tooltip,\
	'Trackbar',			Trackbar,\
	'Treeview',			Treeview,\
	'Up-Down',			Updown

;	'Task Dialog',			TaskDialog,\
;	'Rich Edit',			RichEdit,\
;	'Ribbon',			Ribbon,\

	if % = 1
{const}		align 8
{const}		label .DlgProc_Table:8
		repeat %%
			indx %
			eval 'extrn ',`brief,'DlgProc'
{const}			dq brief#DlgProc
		end repeat
{const}		label .DlgTitle_Table:8
		repeat %%
{const}			dq .%
		end repeat
		indx 1
	end if

{const} .% du title bappend ' Control - Close with <Alt+F4>!',0

end iterate

;------------------------------------------------------------------------------
; We can generate a response file for use with the linker. This is better than
; using a '.drectve' section as all the commands are allowed. :-)
;
; Of course, we could add the object files for all examples here. Yet, build
; optimization benfits from defining dependancies in the makefile.
virtual as "response"
	db '/NOLOGO',10
;	db '/VERBOSE',10 ; use to debug process
	db '/NODEFAULTLIB',10
	db '/BASE:0x10000',10
	db '/DYNAMICBASE:NO',10
	db '/IGNORE:4281',10 ; bogus warning to scare people away
	db '/SUBSYSTEM:WINDOWS,6.02',10
	db '/MANIFEST:EMBED',10
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
	db 'kernel32.lib',10
	db 'user32.lib',10
	db 'gdi32.lib',10
	db 'comctl32.lib',10
end virtual
