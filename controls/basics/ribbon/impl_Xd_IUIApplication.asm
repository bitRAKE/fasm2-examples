;
; IUIApplication is an interface required to manage IUIFramework events.
;
; Is there a case where multiple IUIApplication interfaces are needed? Perhaps
; multiple ribbon controls where modes weren't sufficient? Need to test.

include 'windows.g'
include 'winerror.g'
include 'UIRibbon.g'
include 'debug.asm'

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

	debug_application_on_view_changed

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
	.UI_VIEWVERB_DESTROY,\
	.UI_VIEWVERB_SIZE,\
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

	debug_application_on_create_uicommand

	lea rax, [X_IUICommandHandler]
	mov [r9], rax
	xor eax, eax ; S_OK
	retn



:OnDestroyUICommand:
; RCX			IUIApplication* this
; EDX			UINT32 commandId
; R8D	__in		UI_COMMANDTYPE typeID
; R9	__in_opt	IUICommandHandler* commandHandler

	debug_application_on_destroy_uicommand

	mov eax, E_NOTIMPL
	retn


;-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG


macro debug_application_on_view_changed
	{const:1} ._UI_VIEWTYPE_BAD	db 27,'[31m','View type unknown!',0
	{const:1} ._UI_VIEWTYPE_RIBBON	db 27,'[32m','UI_VIEWTYPE_RIBBON',0
	lea r10, [._UI_VIEWTYPE_BAD]
	lea rax, [._UI_VIEWTYPE_RIBBON]
	cmp r8d, 1
	cmovnz rax, r10

	iterate verb, UI_VIEWVERB_CREATE,UI_VIEWVERB_DESTROY,UI_VIEWVERB_SIZE,UI_VIEWVERB_ERROR
		assert %-1 = verb ; sanity check
		if 1 = %
			{const:1} ._UI_VIEWVERB_:
			repeat %%
				{const:1} db .% - ._UI_VIEWVERB_
			end repeat
			{const:1} db .0 - ._UI_VIEWVERB_
		end if
		{const:1} .% db 27,'[32m',`verb,0
	end iterate
	{const:1} .0 db 27,'[31m','UI verb unknown!',0

	mov r10d, 1+UI_VIEWVERB_ERROR
	mov r11d, [.verb]
	cmp r11d, r10d
	cmovnc r11d, r10d
	lea r10, [._UI_VIEWVERB_]
	movzx r11d, byte [r10 + r11]
	add r10, r11
	mov r11d, [.uReasonCode] ; uReasonCode
	ABISAFE_DebugLogMessage <\
		27,'[96m',"IUIApplication::OnViewChanged",27,'[m',"(",\
		27,'[90m'," *this : %p",10,\
		27,'[90m',"     UINT             viewId : %d",10,\
		27,'[90m',"__in UI_VIEWTYPE      typeId : %hs",10,\
		27,'[90m',"__in IUnknown*         pView : %p",10,\
		27,'[90m',"     UI_VIEWVERB        verb : %hs",10,\
		27,'[90m',"     INT         uReasonCode : %X",10,\
		27,'[m',")",10>, rcx, rdx, rax, r9, r10, r11
end macro

macro debug_application_on_create_uicommand
;-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG
	mov eax, 1+UI_COMMANDTYPE_COLORCOLLECTION
	lea r10, [OnDestroyUICommand.ctype]
	cmp r8d, eax
	cmovc eax, r8d ; clamp to upper bound
	movzx eax, byte [r10 + rax]
	add rax, r10
	ABISAFE_DebugLogMessage <\
		27,'[93m',"IUIApplication::OnCreateUICommand",27,'[m',"(",\
		27,'[90m'," *this : %p",10,\
		27,'[90m',"         UINT32                  commandId : ",27,'[m',"%d",10,\
		27,'[90m',"__in     UI_COMMANDTYPE             typeID : ",27,'[32m',"UI_COMMANDTYPE%hs",10,\
		27,'[90m',"__in_opt IUICommandHandler* commandHandler : %p",10,\
		27,'[m',")",10>, rcx, rdx, rax, r9
end macro

macro debug_application_on_destroy_uicommand
	iterate <NAME,CTYPE>,\
		"_UNKNOWN",		UI_COMMANDTYPE_UNKNOWN,\
		"_GROUP",		UI_COMMANDTYPE_GROUP,\
		"_ACTION",		UI_COMMANDTYPE_ACTION,\
		"_ANCHOR",		UI_COMMANDTYPE_ANCHOR,\
		"_CONTEXT",		UI_COMMANDTYPE_CONTEXT,\
		"_COLLECTION",		UI_COMMANDTYPE_COLLECTION,\
		"_COMMANDCOLLECTION",	UI_COMMANDTYPE_COMMANDCOLLECTION,\
		"_DECIMAL",		UI_COMMANDTYPE_DECIMAL,\
		"_BOOLEAN",		UI_COMMANDTYPE_BOOLEAN,\
		"_FONT",		UI_COMMANDTYPE_FONT,\
		"_RECENTITEMS",		UI_COMMANDTYPE_RECENTITEMS,\
		"_COLORANCHOR",		UI_COMMANDTYPE_COLORANCHOR,\
		"_COLORCOLLECTION",	UI_COMMANDTYPE_COLORCOLLECTION

		assert %-1 = CTYPE ; lookup sanity

		if 1 = %
			{const:1} label .ctype:1
			repeat %%
				{const:1} db .% - .ctype
			end repeat
			{const:1} db .0 - .ctype
			{const:1} .0 db 27,'[31m'," NOT KNOWN",0
		end if
		{const:1} .% db NAME,0
	end iterate
	mov eax, 1+UI_COMMANDTYPE_COLORCOLLECTION
	lea r10, [.ctype]
	cmp r8d, eax
	cmovc eax, r8d ; clamp to upper bound
	movzx eax, byte [r10 + rax]
	add rax, r10
	ABISAFE_DebugLogMessage <\
		27,'[33m',"IUIApplication::OnDestroyUICommand",27,'[m',"(",\
		27,'[90m'," *this : %p",10,\
		27,'[90m',"         UINT32                  commandId : ",27,'[m',"%d",10,\
		27,'[90m',"__in     UI_COMMANDTYPE             typeID : ",27,'[32m',"UI_COMMANDTYPE%hs",10,\
		27,'[90m',"__in_opt IUICommandHandler* commandHandler : %p",10,\
		27,'[m',")",10>, rcx, rdx, rax, r9
end macro
