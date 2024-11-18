;
; IUICommandHandler is an interface required to link commands to methods.
;
; :NOTE: This isn't a typical COM object:
;	- no reference counting
;	- single static object without any dynamic data
;	- no factory to create instances - public object!
;
; :HACK: No command should actually use this handler. Except debugging.
;
include 'windows.g'
include 'winerror.g'
include 'UIRibbon.g'

public m_Object as "X_IUICommandHandler"

; bring into local namespace as common names
extrn "X_IUnknown.xQueryInterface"	as xQueryInterface
extrn "X_IUnknown.AddRef"		as AddRef
extrn "X_IUnknown.Release"		as Release

BLOCK COFF.64.DATA
	QueryInterface.iids:
		UUID IID_IUnknown
		UUID IID_IUICommandHandler
	.0:	dq .0,.0 ; exotic terminator :-)

	vtbl	dq \
	\;	IUnknown methods:
		QueryInterface,\
		AddRef,\
		Release,\
	\;	IUICommandHandler methods:
		Execute,\
		UpdateProperty
			dq ?
	m_Object	dq vtbl
	; no state
END BLOCK

;------------------------------------------------------------ IUnknown Methods:

QueryInterface:	; (IUICommandHandler* this, REFIID iid, void** ppv) HRESULT
	lea rax, [.iids]
	jmp xQueryInterface ; common querier

; -------------------------------------------------- IUICommandHandler Methods:

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

;	enter .frame, 0
;	leave
	xor eax, eax ; S_OK
	retn
