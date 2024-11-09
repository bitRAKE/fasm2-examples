;
; IUICommandHandler is an interface required to link commands to methods.
;
; :NOTE: This isn't a typical COM object:
;	- no reference counting
;	- single static object without any dynamic data
;	- no factory to create instances - public object!

include 'windows.g'
include 'winerror.g'
include '..\common\UIRibbon.g'

BLOCK COFF.64.DATA
	vtable	dq \
	\;	IUnknown methods:
		QueryInterface,\
		AddRef,\
		Release,\
	\;	IUICommandHandler methods:
		Execute,\
		UpdateProperty

	m_Object	dq vtable
	m_cRef		dd ?,?
END BLOCK

public m_Object as "static__IUICommandHandler"

;------------------------------------------------------------ IUnknown Methods:

QueryInterface:	; (IUICommandHandler* this, REFIID iid, void** ppv) HRESULT
	cmp r8, 0xFFFF
	jbe .null

	and qword [r8], 0		; errors zero out parameters when possible

	cmp rdx, 0xFFFF
	jbe .arg

	mov r10, qword [rdx]
	mov r11, qword [rdx + 8]
	iterate iid, IID_IUnknown, IID_IUICommandHandler
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

AddRef:					; IUICommandHandler* this
Release:				; IUICommandHandler* this
	mov eax, 1			; return current reference count
	retn


; -------------------------------------------------- IUICommandHandler Methods:

; Most properties (UI_PKEY_*) only update by first being invalidated with
; IUIFramework::InvalidateUICommand method. Some properties support using
; IUIFramework::GetUICommandProperty and IUIFramework::SetUICommandProperty
; in a more direct manner.
:UpdateProperty:
;			IUICommandHandler* this
;			UINT nCmdID
;	__in		REFPROPERTYKEY key
;	__in_opt const	PROPVARIANT* ppropvarCurrentValue
;	__out		PROPVARIANT* ppropvarNewValue

	mov eax, E_NOTIMPL
	retn


; Called by the Ribbon framework when a command is executed by the user.  For
; example, when a button is pressed.
:Execute:
;			IUICommandHandler* this
;			UINT nCmdID
;			UI_EXECUTIONVERB verb
;	__in_opt const	PROPERTYKEY* key
;	__in_opt const	PROPVARIANT* ppropvarValue
;	__in_opt	IUISimplePropertySet* pCommandExecutionProperties

	xor eax, eax ; S_OK
	retn
