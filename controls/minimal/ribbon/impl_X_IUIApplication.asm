;
; IUIApplication is an interface required to manage IUIFramework events.
;
; :NOTE: This isn't a typical COM object:
;	- no reference counting
;	- single static object without any dynamic data
;	- no factory to create instances - public object!
;
; Is there a case where multiple IUIApplication interfaces are needed? Perhaps
; multiple ribbon controls where modes weren't sufficient? Need to test.

include 'windows.g'
include 'winerror.g'
include 'UIRibbon.g'

public m_Object as "X_IUIApplication"
public g_uRibbonHeight

; bring into local namespace as common names
extrn "X_IUnknown.xQueryInterface"	as xQueryInterface
extrn "X_IUnknown.AddRef"		as AddRef
extrn "X_IUnknown.Release"		as Release

extrn g_hWndMain:8
extrn X_IUICommandHandler ; static debug command handler COM interface

BLOCK COFF.64.DATA
	QueryInterface.iids:
		UUID IID_IUnknown
		UUID IID_IUIApplication
	.0:	dq .0,.0 ; exotic terminator :-)

	vtbl	dq \
	\;	IUnknown methods:
		QueryInterface,\
		AddRef,\
		Release,\
	\;	IUIApplication methods:
		OnViewChanged,\
		OnCreateUICommand,\
		OnDestroyUICommand

	m_Object	dq vtbl
	g_uRibbonHeight dd -1
	reserved0	dd ?
END BLOCK

;------------------------------------------------------------ IUnknown Methods:

QueryInterface:	; (IUIApplication* this, REFIID iid, void** ppv) HRESULT
	lea rax, [.iids]
	jmp xQueryInterface ; common querier

; ----------------------------------------------------- IUIApplication Methods:

:OnViewChanged: ; View state has changed.
;		IUIApplication* this		; RCX
;		UINT viewId			; EDX, only 0 valid
;	__in	UI_VIEWTYPE typeId		; R8D, 1, UI_VIEWTYPE_RIBBON
;	__in	IUnknown* pView			; R9, IUIRibbon*
;		UI_VIEWVERB verb
;		INT uReasonCode
	enter .frame, 0
	virtual at rbp+16
		.pApp		IUIApplication	; *
		.pRibbon	IUIRibbon
		.pStream	IStream
				dq ?
		.verb		dd ?		; *
		.uRibbonHeight	dd ?
		.uReasonCode	dd ?		; *
		.hr		dd ?
	end virtual
	test edx, edx
	jnz .ximp
	cmp r8d, UI_VIEWTYPE_RIBBON
	jnz .ximp
	cmp [.verb], 1+UI_VIEWVERB_ERROR
	jnc .ximp
	mov [.pApp], rcx

	; Insure needed interface present, why pView is not defined as IUIRibbon?
	IUnknown__QueryInterface r9, IID_IUIRibbon, & .pRibbon
	test eax, eax
	js .fail			; Y: forward HRESULT

	mov edx, [.verb]
	jmp [.table + rdx*8]

.ximp:	mov eax, E_NOTIMPL
.fail:	leave
	retn

{data:32} .table dq \
	.UI_VIEWVERB_CREATE,\
	.UI_VIEWVERB_SIZE,\
	.UI_VIEWVERB_DESTROY,\
	.UI_VIEWVERB_ERROR


{data:2} .reg_path	du "Software\bitRAKE\App5",0
{data:2} .reg_key	du "RibbonState",0


.UI_VIEWVERB_CREATE: ; create a view
	mov [.hr], S_FALSE ; not an error if it doesn't exist
	SHOpenRegStream2W HKEY_CURRENT_USER, & .reg_path, & .reg_key, STGM_READ
	test rax, rax
	jz @F ; Y: bad_stream
	mov [.pStream], rax
	xchg rdx, rax
	IUIRibbon__LoadSettingsFromStream [.pRibbon], rdx
	mov [.hr], eax
	IStream__Release [.pStream]

	; :TODO: load item settings details, the above doesn't load control state

@@:	IUIRibbon__Release [.pRibbon]
	mov eax, [.hr]
	leave
	retn



.UI_VIEWVERB_DESTROY: ; destroy a view

	; :TODO: save item settings details, the below doesn't save control state

	mov [.hr], E_FAIL
	SHOpenRegStream2W HKEY_CURRENT_USER, & .reg_path, & .reg_key, STGM_WRITE
	test rax, rax
	jz @F ; Y: bad_stream
	mov [.pStream], rax
	xchg rdx, rax
	IUIRibbon__SaveSettingsToStream [.pRibbon], rdx
	mov [.hr], eax
	IStream__Release [.pStream]
@@:	IUIRibbon__Release [.pRibbon]
	mov eax, [.hr]
	leave
	retn



.UI_VIEWVERB_SIZE: ; resize a view
	IUIRibbon__GetHeight [.pRibbon], & .uRibbonHeight
	mov [.hr], eax
	IUIRibbon__Release [.pRibbon]
	test [.hr], -1
	js .done

	; Only report size changes to parent window.

	mov eax, [.uRibbonHeight]
	cmp [g_uRibbonHeight], eax
	jz .done
	mov [g_uRibbonHeight], eax
;	SendMessageW [g_hWndMain], WM_SIZE, SIZE_RESTORED, -1
.done:
	mov eax, [.hr]
	leave
	retn



.UI_VIEWVERB_ERROR: ; action cannot be completed
;	"Ribbon framework was not able to complete action."
	IUIRibbon__Release [.pRibbon]
	leave
	retn



:OnCreateUICommand:; ----------------------------- Bind a command to a handler:
;			IUIApplication* this
;			UINT nCmdID
;	__in		UI_COMMANDTYPE typeID
;	__deref_out	IUICommandHandler** ppCommandHandler

	lea rax, [X_IUICommandHandler]
	mov [r9], rax
	xor eax, eax ; S_OK
	retn



:OnDestroyUICommand:
; RCX			IUIApplication* this
; EDX			UINT32 commandId
; R8D	__in		UI_COMMANDTYPE typeID
; R9	__in_opt	IUICommandHandler* commandHandler
	mov eax, E_NOTIMPL
	retn
