;
; SysLink advanced control detail:
;
; build with:
;	fasm2 SysLink.asm
;	link @SysLink.response SysLink.obj
;
; TODO: dynamic SysLink sizing

include 'windows.g'
include 'commctl\SysLink.g' ; control interface

IDC_SYSLINK := 0x1234

;-------------------------------------------------------------------------------
; Configure experimentation ...
;-------------------------------------------------------------------------------
OPTION_FORCE_MOUSE	:= 0
;	- Tab key still works, need to subclass.

; Note: LWS_USEVISUALSTYLE overwrites below options:

OPTION_BACKGROUND	:= 1	; only if NOT LWS_TRANSPARENT
	OPTION_TEXT_COLORREF	:= 0x0FD000
	OPTION_TXBK_COLORREF	:= 0x202020
	OPTION_BKGND_COLORREF	:= 0x404040

OPTION_RAINBOW		:= 1 ; requires LWS_USECUSTOMTEXT, NM_CUSTOMDRAW doesn't work?

SYSLINK_STYLE := LWS_USECUSTOMTEXT or LWS_NOPREFIX

;-------------------------------------------------------------------------------

BLOCK COFF.8.BSS
	g_hSysLink	dq ?
	g_hBrush	dq ?
	g_hOBrush	dq ?
	g_litem		LITEM
END BLOCK

{bss:64} g_buffer rw 4096


public WinMainCRTStartup
:WinMainCRTStartup:
	pop rax ; no return
	DialogBoxIndirectParamW __ImageBase, & SysLinkDialog, 0, & SysLinkDlgProc
	ExitProcess rax
	jmp $

:SysLinkDlgProc:
	iterate message, WM_COMMAND,WM_CLOSE,WM_INITDIALOG,\
		\;	messages from SysLink control:
		WM_NOTIFY,WM_CTLCOLORSTATIC,WM_QUERYUISTATE
		cmp edx, message
		jz .message
	end iterate
@@:	xor eax, eax
	retn


.WM_COMMAND:; This is a trick to allow the ESC key to exit.
	test r9, r9
	jnz @B
	cmp r8, IDCANCEL ; undocumented menu command?
	jnz @B
.WM_CLOSE:
	enter .frame, 0
	EndDialog rcx, 0
@0:	xor eax, eax
	leave
	retn


.WM_INITDIALOG:	; Size dialog to fit SysLink text:
	virtual at rbp+16
		.rc		RECT
		.hDialog	dq ?
		.change		dd ?
		assert $-$$ < 33 ; don't exceed shadow space
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx

	GetDlgItem rcx, IDC_SYSLINK
	mov [g_hSysLink], rax
	xchg rcx, rax
	jrcxz @0B

	mov rcx, [g_hSysLink]
	call FileVersionFromWindowHandle
	jz .no_version ; Y: module version not obtainable from window handle
	movzx r8, word [rax + 2 + VS_FIXEDFILEINFO.dwFileVersionMS]
	movzx r9, word [rax + 0 + VS_FIXEDFILEINFO.dwFileVersionMS]
	movzx r10, word [rax + 6 + VS_FIXEDFILEINFO.dwFileVersionLS]
	movzx r11, word [rax + 4 + VS_FIXEDFILEINFO.dwFileVersionLS]
	wsprintfW & g_buffer, W	"Common Controls Version %hu.%hu.%hu.%hu", r8, r9, r10, r11
	SetWindowTextW [.hDialog], & g_buffer
.no_version:
	if OPTION_BACKGROUND & ~(LWS_TRANSPARENT and SYSLINK_STYLE)
		CreateSolidBrush OPTION_BKGND_COLORREF
		mov [g_hBrush], rax
	end if

 ; simplified sizing of just the bottom of control and parent dialog

	GetWindowRect [g_hSysLink], & .rc
	mov r8d, [.rc.right]
	sub r8d, [.rc.left]
	SendMessageW [g_hSysLink], LM_GETIDEALHEIGHT, r8d, 0
	mov ecx, [.rc.bottom]
	sub ecx, [.rc.top]
	sub ecx, eax
	mov [.change], ecx
	sub [.rc.bottom], ecx

	mov r8d, [.rc.left]
	mov r9d, [.rc.top]
	sub [.rc.right], r8d
	sub [.rc.bottom], r9d
	SetWindowPos [g_hSysLink], 0, r8,r9,[.rc.right],[.rc.bottom],\
		SWP_NOMOVE or SWP_NOZORDER

	GetWindowRect [.hDialog], & .rc
	mov ecx, [.change]
	sub [.rc.bottom], ecx

	mov r8d, [.rc.left]
	mov r9d, [.rc.top]
	sub [.rc.right], r8d
	sub [.rc.bottom], r9d
	SetWindowPos [.hDialog], 0, r8,r9,[.rc.right],[.rc.bottom],\
		SWP_NOMOVE or SWP_NOZORDER
	jmp @0B


.WM_CTLCOLORSTATIC:
	if OPTION_BACKGROUND & ~(LWS_TRANSPARENT and SYSLINK_STYLE)
		; configure DC and return HBRUSH, for area outside text
		enter .frame, 0
		label .hDC:8 at rbp+16
		mov [.hDC], r8
		SetTextColor [.hDC], OPTION_TEXT_COLORREF
		SetBkColor [.hDC], OPTION_TXBK_COLORREF
		leave
		mov rax, [g_hBrush] ; OPTION_BKGND_COLORREF
	else
		xor eax, eax
	end if
	retn


.WM_QUERYUISTATE: ; check SysLink activity state
;	GetFocus
;	cmp rax, [.hSysLink]
;	leave
;	setz al ; 0 ? UISF_ACTIVE
;	add al, UISF_HIDEACCEL or UISF_HIDEFOCUS
;	movzx eax, al
	mov eax, 4 ; UISF_ACTIVE, always appear active
	retn


.WM_NOTIFY:
	cmp r8w, IDC_SYSLINK
	jnz @B
	cmp [r9 + NMHDR.idFrom], IDC_SYSLINK
	jnz @B
	mov rax, [g_hSysLink]
	cmp [r9 + NMHDR.hwndFrom], rax
	jnz @B

; There are many ways to filter the notification ...
; (i.e. above is overkill, but we definately have a SysLink notification :-)
;
;-NM_CUSTOMDRAW doesn't appear to work - CDDS_PREPAINT is sent, but no value
; triggers additional messages.

	iterate _code, NM_CUSTOMTEXT,NM_CUSTOMDRAW,NM_CLICK,NM_RETURN,NM_SETFOCUS
		cmp [r9 + NMHDR.code], _code
		jz .WM_NOTIFY._code
	end iterate
	xor eax, eax
	retn


.WM_NOTIFY.NM_SETFOCUS:	; just a signal on {some} keyboard focus
	if OPTION_FORCE_MOUSE
		enter .frame, 0
		SendMessageW [g_hSysLink], WM_KILLFOCUS, 0, 0 ; force user to mouse?
		leave
	end if
	retn ; value ignored


.WM_NOTIFY.NM_CUSTOMTEXT: ; NMCUSTOMTEXT, set LWS_USECUSTOMTEXT
; support tabs, DOESN'T WORK
;	or [r9+NMCUSTOMTEXT.uFormat], DT_EXPANDTABS or DT_VCENTER or DT_NOPREFIX or DT_NOCLIP
;	mov rax, [r9+NMCUSTOMTEXT.lpString]
	if OPTION_RAINBOW
		enter .frame, 0
		test [r9+NMCUSTOMTEXT.fLink],-1
		jnz @F ; Y: don't style links

		{const:64} .test_colors dd \
			0xFF0000,0x00FF00,0x0000FF,0xFFFF00,\
			0xFF00FF,0x00FFFF,0x800000,0x008000,\
			0x000080,0x808000,0x800080,0x008080,\
			0xFFA500,0xFFC0CB,0xA52A2A,0x808080

		{bss:1} .test_value db ?

		inc [.test_value]
		and [.test_value], 0xF
		movzx eax, [.test_value]
		SetTextColor [r9+NMCUSTOMTEXT.hDC], [.test_colors+rax*4]
	@@:	leave
	end if
	retn ; value ignored


.WM_NOTIFY.NM_CUSTOMDRAW:; NMCUSTOMDRAWINFO
	iterate stage, CDDS_PREPAINT,CDDS_ITEMPREPAINT,CDDS_ITEMPOSTPAINT,CDDS_POSTPAINT
		cmp [r9 + NMCUSTOMDRAWINFO.dwDrawStage], stage
		jz .WM_NOTIFY.NM_CUSTOMDRAW.stage
	end iterate
	xor eax, eax
	retn

.WM_NOTIFY.NM_CUSTOMDRAW.CDDS_PREPAINT:
	if OPTION_RAINBOW
		; reset draw rainbow, to stop color rotation on redraw
		mov [.test_value], 0
	end if
	; v6.10.10.0 - unable to get further messages regardless of return value
	retn ; value ignored

.WM_NOTIFY.NM_CUSTOMDRAW.CDDS_ITEMPREPAINT:
	retn ; value ignored

.WM_NOTIFY.NM_CUSTOMDRAW.CDDS_ITEMPOSTPAINT:
	retn ; value ignored

.WM_NOTIFY.NM_CUSTOMDRAW.CDDS_POSTPAINT:
	retn ; value ignored



; Note: SysLink does NOT populate all fields of NMLINK!
;	The following fields are set:
;		NMLINK.hdr.*
;		NMLINK.item.iLink
;		NMLINK.item.szID
;		NMLINK.item.szUrl

.WM_NOTIFY.NM_CLICK:; control ID, *NMLINK
	{const:1} .nm_click db 'NM_CLICK',0
	lea r8, [.nm_click]
	jmp @F
.WM_NOTIFY.NM_RETURN:; control ID, *NMLINK
	{const:1} .nm_return db 'NM_RETURN',0
	lea r8, [.nm_return]

@@:	; MUST check for strings because [NMLINK.item.mask] isn't set:
	mov r10, r9

	{const:1} .lif_url db 'hyperlink "href"',0
	lea r9, [.lif_url]
	test word [r10 + NMLINK.item.szUrl], -1
	jnz @F ; href

	{const:1} .lif_itemid db 'an "id" link',0
	lea r9, [.lif_itemid]
	test word [r10 + NMLINK.item.szID], -1
	jnz @F ; id

	{const:1} .lif_itemindex db 'a basic link',0
	lea r9, [.lif_itemindex]

@@:	enter .frame, 0
	mov [.hDialog], rcx
	wsprintfW & g_buffer, <du \
		"Notification code %S indicating %S selected.",10,\
		9,"iLink #%d, ID: %s",10,\
		9,"URL: %s",0>, r8, r9, [r10 + NMLINK.item.iLink],\
		& r10 + NMLINK.item.szID, & r10 + NMLINK.item.szUrl

	MessageBoxW [.hDialog], & g_buffer, W "Link Action", MB_OK
	leave
	retn ; value ignored



; Window handle to module VS_FIXEDFILEINFO structure.
:FileVersionFromWindowHandle:
	virtual at rbp - .local
		label .szFilePath:1024
				rw sizeof .szFilePath
		.local := $-$$
				rq 2
		.hComCtl32	dq ?
		.dwHandle	dd ?
		.uLen		dd ?
		.lplpBuffer	dq ?	;*VS_FIXEDFILEINFO, within .buffer
	end virtual
	enter .frame + .local, 0
	GetClassLongPtrW rcx, -24 ; GCLP_WNDPROC, could be a handle instead of address?
	xchg rdx, rax
	GetModuleHandleExW 4,rdx, & .hComCtl32 ; GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS
	{const:2} .error.0 du "Address not locatable in module.",0
	lea rdx, [.error.0]
	test eax, eax ; BOOL
	jz @9F

	GetModuleFileNameW [.hComCtl32], & .szFilePath, sizeof .szFilePath
	{const:2} .error.1 du "Unable to obtain module file path.",0
	lea rdx, [.error.1]
	test eax, eax ; characters - null
	jz @9F

	GetFileVersionInfoSizeW & .szFilePath, & .dwHandle
	{const:2} .error.2 du "Version info size appears to be zero.",0
	lea rdx, [.error.2]
	test eax, eax ; bytes
	jz @9F

	.buffer.bytes := 8192
	{const:2} .error.3 du "Insufficient buffer space for version info.",0
	lea rdx, [.error.3]
	cmp [.dwHandle], .buffer.bytes
	jnc @9F

	GetFileVersionInfoW & .szFilePath, 0, .buffer.bytes, & g_buffer
	{const:2} .error.4 du "Failed to get version info.",0
	lea rdx, [.error.4]
	test eax, eax ; BOOL
	jz @9F

	; root is language neutral structure VS_FIXEDFILEINFO
	VerQueryValueW & g_buffer, W "\", & .lplpBuffer, & .uLen
	{const:2} .error.5 du "Failed to get version value.",0
	lea rdx, [.error.5]
	test eax, eax ; BOOL
	jz @9F
	; return VS_FIXEDFILEINFO structure, ZF=0
	mov rax, [.lplpBuffer]
	leave
	retn

@9:	MessageBoxW 0, rdx, W "Module Version Error:", MB_OK
	xor eax, eax ; ZF=1
	leave
	retn



; FYI: the Microsoft resource compiler doesn't fully support the extent
; of the control interface correctly. Don't try to do this with RC.EXE.

virtual ; The syntax looks cleaner if we gather the string here for use later.
	file 'SysLink.xml' ; so much easier to edit!
	load link_string:$-$$ from $$
end virtual

BLOCK COFF.4.CONST
	; Note: Intentionally make dialog short to test auto-sizing based on text.

	SysLinkDialog DLGTEMPLATEEX title: "Assemble-time SysLink Control Example",\
		exStyle: WS_EX_TOOLWINDOW,\
		style: DS_CENTERMOUSE or DS_SETFOREGROUND or DS_NOIDLEMSG\
			or WS_POPUP or WS_VISIBLE or WS_CAPTION or WS_THICKFRAME,\
		cx: 240, cy: 16, pointsize: 11, typeface: "Segoe UI"

	DLGITEMTEMPLATEEX title: link_string, id: IDC_SYSLINK, windowClass: "SysLink",\
		style: SYSLINK_STYLE\; configure above, top of file
		or WS_TABSTOP or WS_VISIBLE or WS_CHILD,\
		x: 4, y: 2, cx: 240-8, cy: 16-4
END BLOCK

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
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.1.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
	db 'kernel32.lib',10
	db 'gdi32.lib',10
	db 'user32.lib',10
	db 'comctl32.lib',10
	db 'version.lib',10
end virtual
