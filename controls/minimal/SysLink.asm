;
; SysLink minimal control requirements:
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
	cmp edx, WM_NOTIFY
	jz .WM_NOTIFY
	cmp edx, WM_CLOSE
	jnz @0F
	EndDialog rcx, 0
@0:	leave
	xor eax, eax
	retn

.WM_NOTIFY:
	cmp [r9 + NMHDR.idFrom], IDC_SYSLINK
	jnz @0B
	cmp [r9 + NMHDR.code], NM_RETURN ; or space
	jz .NM_RETURN
	cmp [r9 + NMHDR.code], NM_CLICK
	jnz @0B
.NM_RETURN:
	ShellExecuteW rcx, & r9 + NMLINK.item.szID, & r9 + NMLINK.item.szUrl, 0, 0, SW_SHOW
	jmp @0B

BLOCK COFF.4.CONST
	SysLinkDialog DLGTEMPLATEEX title: "Minimal SysLink",\
		exStyle: WS_EX_TOOLWINDOW or WS_EX_TOPMOST,\
		style: DS_CENTERMOUSE or DS_SETFOREGROUND or DS_NOIDLEMSG\
			or WS_POPUP or WS_VISIBLE or WS_CAPTION or WS_SYSMENU,\
		cx: 64, cy: 16
	DLGITEMTEMPLATEEX id: IDC_SYSLINK, windowClass: "SysLink",\
		style: LWS_TRANSPARENT or LWS_USEVISUALSTYLE or WS_TABSTOP or WS_VISIBLE or WS_CHILD,\
		x: 4, y: 2, cx: 56, cy: 10,\
		title: 'x86-64 by <a id="open" href="https://github.com/bitRAKE">bit&RAKE</a>.'
END BLOCK

virtual as "response"
	db '/NOLOGO',10
;	db '/VERBOSE',10 ; use to debug process
	db '/NODEFAULTLIB',10
	db '/SUBSYSTEM:WINDOWS,6.02',10
	db '/MANIFEST:EMBED',10
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.1.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
	db 'kernel32.lib',10
	db 'user32.lib',10
	db 'shell32.lib',10
end virtual
