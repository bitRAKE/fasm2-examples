;
; IUIApplication is an interface required to manage IUIFramework events.
;
; :NOTE: This isn't a typical COM object:
;	- no reference counting
;	- single static object without any dynamic data
;	- no factory to create instances - public object!

include 'windows.g'
include 'winerror.g'
include '..\common\UIRibbon.g'

extrn static__IUICommandHandler ; static command COM object

BLOCK COFF.64.DATA
	vtable	dq \
	\;	IUnknown methods:
		QueryInterface,\
		AddRef,\
		Release,\
	\;	IUIApplication methods:
		OnViewChanged,\
		OnCreateUICommand,\
		OnDestroyUICommand

	m_Object	dq vtable
	m_cRef		dd ?
END BLOCK

public m_Object as "static__IUIApplication"

;------------------------------------------------------------ IUnknown Methods:

QueryInterface:				; (this, REFIID iid, void** ppv) HRESULT
	cmp r8, 0xFFFF
	jbe .null

	and qword [r8], 0		; errors zero out parameters when possible

	cmp rdx, 0xFFFF
	jbe .arg

	mov r10, qword [rdx]
	mov r11, qword [rdx + 8]
	iterate iid, IID_IUnknown, IID_IUIApplication
		cmp qword [iid], r10
		jnz .%
		cmp qword [iid + 8], r11
		jz .ok
	.%:
	end iterate

	mov eax, E_NOINTERFACE
	retn
.null:	mov eax, E_POINTER
	retn
.arg:	mov eax, E_INVALIDARG
	retn

.ok:	mov [r8], rcx
	xor eax, eax ; S_OK
	retn

AddRef:					; IUIApplication* this
Release:				; IUIApplication* this
	mov eax, 1			; return current reference count
	retn


; ----------------------------------------------------- IUIApplication Methods:

:OnViewChanged:
;		IUIApplication* this		; RCX
;		UINT viewId			; EDX
;	__in	UI_VIEWTYPE typeId		; R8D, 1, UI_VIEWTYPE_RIBBON
;	__in	IUnknown* pView			; R9, IUIRibbon*
;		UI_VIEWVERB verb		;
;		INT uReasonCode			;

	cmp r8d, UI_VIEWTYPE_RIBBON
	jnz .ximp

	label .verb:4 at rsp + 40
	iterate action, UI_VIEWVERB_CREATE,UI_VIEWVERB_SIZE,UI_VIEWVERB_DESTROY
		cmp [.verb], action
		jz .action
	end iterate

.ximp:	mov eax, E_NOTIMPL
	retn

.UI_VIEWVERB_CREATE:
;	+ IUIRibbon__LoadSettingsFromStream
;	+ control properties

.UI_VIEWVERB_DESTROY:
;	+ control properties
;	+ IUIRibbon__SaveSettingsToStream
	xor eax, eax
	retn


.UI_VIEWVERB_SIZE:
	enter .frame, 0
	virtual at rbp+16
		.pRibbon	IUIRibbon
		.uRibbonHeight	dd ?
		.hResult	dd ?
	end virtual

	; need to verify the interface?
	IUnknown__QueryInterface r9, IID_IUIRibbon, & .pRibbon
	test eax, eax
	js .fail			; Y: forward HRESULT

	; Call to the framework to determine the desired height of the Ribbon.
	IUIRibbon__GetHeight [.pRibbon], & .uRibbonHeight
	mov [.hResult], eax

	IUIRibbon__Release [.pRibbon]

; :TODO: Use the ribbon height to position client area content.

	mov eax, [.hResult]
.fail:	leave
	retn



:OnCreateUICommand:				; Bind a command to a handler.
;			IUIApplication* this
;			UINT nCmdID
;	__in		UI_COMMANDTYPE typeID
;	__deref_out	IUICommandHandler** ppCommandHandler

	; all commands are given the same handler

	lea rcx, [static__IUICommandHandler]
	mov [r9], rcx

	xor eax, eax ; S_OK
	retn



:OnDestroyUICommand:
; RCX			IUIApplication* this
; EDX			UINT32 commandId
; R8D	__in		UI_COMMANDTYPE typeID
; R9	__in_opt	IUICommandHandler* commandHandler
	mov eax, E_NOTIMPL
	retn
