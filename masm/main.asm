
include 'win64axp.inc'
include 'main.h'

.data?
label buffer:512
	db sizeof buffer dup(?)

hInstance dq ? ;HINSTANCE ?
CommandLine dq ? ;LPSTR ?

.code

start:
        invoke GetModuleHandle,0
        mov    [hInstance],rax
        invoke DialogBoxParam,[hInstance],"MyDialog",0,addr DlgProc,0
        invoke ExitProcess,eax

proc DlgProc, hWnd,uMsg,wParam,lParam
	mov [hWnd], rcx
	mov [uMsg], rdx
	mov [wParam], r8
	mov [lParam], r9

	.IF [uMsg] = WM_INITDIALOG
		invoke GetDlgItem,[hWnd],IDC_EDIT
		invoke SetFocus,eax
	.ELSEIF [uMsg] = WM_CLOSE
		invoke SendMessage,[hWnd],WM_COMMAND,IDM_EXIT,0
	.ELSEIF [uMsg] = WM_COMMAND
		;--- Menu items handling
                .IF [lParam] = 0 & word [wParam + 2] = 0
			.IF word [wParam] = IDM_GETTEXT
				invoke GetDlgItemText,[hWnd],IDC_EDIT,\
					addr buffer,sizeof buffer
				invoke MessageBox,0,addr buffer,\
					"Our Second Dialog Box",MB_OK
			.ELSEIF word [wParam] = IDM_CLEAR
				invoke SetDlgItemText,[hWnd],IDC_EDIT,0
			.ELSEIF word [wParam] = IDM_EXIT
				invoke EndDialog,[hWnd],0
			.ENDIF
                .ELSEIF word [wParam + 2] = BN_CLICKED
                ;--- Controls handling
			.IF word [wParam] = IDC_BUTTON
				invoke SetDlgItemText,[hWnd],IDC_EDIT,\
					"Wow! I'm in an edit box now."
			.ELSEIF word [wParam] = IDC_EXIT
				invoke SendMessage,[hWnd],WM_COMMAND,IDM_EXIT,0
			.ENDIF
		.ENDIF
	.ELSE
		mov  eax,FALSE
		ret
	.ENDIF
	mov  eax,TRUE
	ret
endp

.end start

section '.rsrc' data readable resource from 'main.res'
