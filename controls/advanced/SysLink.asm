;
; SysLink advanced control detail:
;
; build with:
;	fasm2 SysLink.asm
;	link @SysLink.response SysLink.obj
;
include 'windows.g'
include 'SysLink.g' ; control interface

IDC_SYSLINK := 0x1234

public WinMainCRTStartup
:WinMainCRTStartup:
	pop rax ; no return
	DialogBoxIndirectParamW __ImageBase, & SysLinkDialog, 0, & SysLinkDlgProc
	ExitProcess rax
	jmp $

:SysLinkDlgProc:
	enter .frame, 0
	iterate message, WM_NOTIFY,WM_COMMAND,WM_CLOSE,WM_INITDIALOG
		cmp edx, message
		jz .message
	end iterate
@0:	leave
	xor eax, eax
	retn

{bss:8} .hSysLink dq ? ; static value with future use

.WM_COMMAND:; This is a trick to allow the ESC key to exit.
	test r9,r9
	jnz @0B
	cmp r8, IDCANCEL ; undocumented menu command?
	jnz @0B
.WM_CLOSE:
	EndDialog rcx, 0
	jmp @0B

.WM_INITDIALOG:	; Size dialog to fit SysLink text:
	virtual at rbp+16
		.rc		RECT
		.hDlg		dq ?
		.change		dd ?
		assert $-$$ < 33 ; don't exceed shadow space
	end virtual
	mov [.hDlg], rcx

	GetDlgItem rcx, IDC_SYSLINK
	mov [.hSysLink], rax
	xchg rcx, rax
	jrcxz @0B

 ; simplified sizing of just the bottom of control and parent dialog
 ; TODO: dynamic SysLink sizing

	GetWindowRect [.hSysLink], & .rc
	mov r8d, [.rc.right]
	sub r8d, [.rc.left]
	SendMessageW [.hSysLink], LM_GETIDEALHEIGHT, r8d, 0
	mov ecx, [.rc.bottom]
	sub ecx, [.rc.top]
	sub ecx, eax
	mov [.change], ecx

	GetWindowRect [.hDlg], & .rc
	mov r8d, [.rc.left]
	mov r9d, [.rc.top]
	sub [.rc.right], r8d
	sub [.rc.bottom], r9d

	mov eax, [.change]
	sub [.rc.bottom], eax
	SetWindowPos [.hDlg], 0, r8,r9,[.rc.right],[.rc.bottom],\
		SWP_NOMOVE or SWP_NOZORDER
	jmp @0B


; There are many ways to filter the notification ... (i.e. this is overkill)
.WM_NOTIFY:
	cmp r8w, IDC_SYSLINK
	jnz @0B
	cmp [r9 + NMHDR.idFrom], IDC_SYSLINK
	jnz @0B
	mov rax, [.hSysLink]
	cmp [r9 + NMHDR.hwndFrom], rax
	jnz @0B

	{const:1} .nm_return db 'NM_RETURN',0
	lea r8, [.nm_return]
	cmp [r9 + NMHDR.code], NM_RETURN
	jz .keyboard

	{const:1} .nm_click db 'NM_CLICK',0
	lea r8, [.nm_click]
	cmp [r9 + NMHDR.code], NM_CLICK
	jz .mouse

	jmp @0B

; NOTE:	SysLink does NOT populate all fields of NMLINK!
;	The following fields are set:
;		NMLINK.hdr.*
;		NMLINK.item.iLink
;		NMLINK.item.szID
;		NMLINK.item.szUrl

.keyboard:
.mouse:
	; MUST check for strings because [NMLINK.item.mask] isn't set:
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

@@:	wsprintfW & .buffer, <du \
		"Notification code %S indicating %S selected.",10,\
		9,"iLink #: %d",10,\
		9,"ID : %s",10,\
		9,"URL : %s",0>, r8, r9, [r10 + NMLINK.item.iLink],\
		& r10 + NMLINK.item.szID, & r10 + NMLINK.item.szUrl

	{bss:64} .buffer rw 4096
	MessageBoxW [.hSysLink], & .buffer, W "Link Action", MB_OK
	jmp @0B

virtual ; The syntax looks cleaner if we gather the string here for use later.
db\ ; it could be separate file, etc.
'Links can be <a>clicked</a>, or <a id="VK_TAB">tab</a> navigated to and selected by',\
' <a id="VK_RETURN">return</a> or <a id="VK_SPACE">space</a>. Links can have attributes, an HREF and/or ID',\
' can be assigned to the link, but that is not required. It all depends on what is',\
' useful in the notification handler. Typically, <a>NM_CLICK</a> and <a>NM_RETURN</a>',\
' result in the same action regardless of how selection was made. ',10,10,\
'The <a>SysLink</a> control''s parent responds to <a>WM_GETFONT</a> and determines',\
' the font used for display. Of course, <a>WM_SETFONT</a> can manually change the',\
' font. ',10,10,\
'These examples are <a id="coded">coded</a> by',\
' <a href="https://github.com/bitRAKE">bitRAKE</a>, using the latest dialect of the',\
' <a href="http://flatassembler.net">fasm</a> family of languages,',\
' <a href="https://github.com/tgrysztar/fasm2">fasm2</a>.',\
' It is an interesting exploration in low-level programming.',10,10,\
'Note: <a>all</a> these links are a single control.',10,10,\
'Also note: <a id="Hello World!" href="https://github.com/bitRAKE">links can have both id and href</a>.',10,10,\
'Also note: theming a SysLink with LWS_USEVISUALSTYLE will overwrite the default font setting from parent.'
load link_string:$-$$ from $$
end virtual

BLOCK COFF.4.CONST

	SysLinkDialog DLGTEMPLATEEX title: "Assemble-time SysLink",\
		exStyle: WS_EX_TOOLWINDOW,\
		style: DS_CENTERMOUSE or DS_SETFOREGROUND or DS_NOIDLEMSG\
			or WS_POPUP or WS_VISIBLE or WS_CAPTION or WS_THICKFRAME,\
		cx: 160, cy: 256, pointsize: 13, typeface: "Segoe UI"

; FYI: the Microsoft resource compiler doesn't fully support the extent
; of the control interface correctly. Try to compile this in RC.EXE:
;
; LWS_USEVISUALSTYLE will overwrite the dialog font.

	DLGITEMTEMPLATEEX title: link_string, id: IDC_SYSLINK, windowClass: "SysLink",\
		style: LWS_TRANSPARENT or LWS_NOPREFIX or WS_TABSTOP or WS_VISIBLE or WS_CHILD,\
		x: 4, y: 2, cx: 152, cy: 250

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
	db 'user32.lib',10
	db 'comctl32.lib',10
end virtual
