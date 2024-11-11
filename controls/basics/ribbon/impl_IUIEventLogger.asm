include 'windows.g'
include 'winerror.g'
include 'UIRibbon.g'

public EnableRibbonControlLogging ; IUIFramework*, hStdOut
public DisableRibbonControlLogging
public LoggingFlags
public LoggingModes
;
; IUIEventLogger - ribbon host implemented interface for event callback.
;
; After obtaining a framework interface (IUIFramework::Initialize) and loading
; a ribbon binary object (IUIFramework::LoadUI); event logging can assist in
; debugging ribbon dynamics or gathering usage metrics. Call this method to
; start logging. Use `LoggingFlags and `LoggingModes to limit output.
;
;	RCX : IUIFramework*
;	RDX : console output handle
:EnableRibbonControlLogging:
	enter .frame, 0
	mov [hOutput], rdx

	IUIFramework__QueryInterface rcx, IID_IUIEventingManager, & g_pEventingManager
	test eax, eax ; HRESULT, S_OK?
	js .fail_evtmgr
	test [g_pEventingManager], -1
	jz .fail_evtmgr

	← "[",27,'[96m',"RibbonControlLogger",27,'[m',"] "

	; static COM interface (m_Object) is private to this module

	IUIEventingManager__SetEventLogger [g_pEventingManager], & m_Object
	test eax, eax ; HRESULT, S_OK?
	js .fail_setlog

	← 27,'[33m',"Logging enabled successfully.",27,'[m',10

	leave
	retn

.fail_setlog:
	← "Error:",27,'[31m'," Failed to set the event logger.",27,'[m',10
	__fastfail 1

.fail_evtmgr:
	← "Error:",27,'[31m'," Failed to get IUIEventingManager.",27,'[m',10
	__fastfail 1


:DisableRibbonControlLogging:
	mov rcx, [g_pEventingManager]
	jrcxz .skip
	enter .frame, 0
	IUIEventingManager__SetEventLogger rcx, NULL ; disable
	IUIEventingManager__Release [g_pEventingManager]
	and [g_pEventingManager], 0
	← "[",27,'[96m',"RibbonControlLogger",27,'[m',"] ",\
		27,'[33m',"Logging disabled successfully.",27,'[m',10
	leave
.skip:	retn

;===============================================================================

BLOCK COFF.64.DATA
	m_Object		dq vtbl
	g_pEventingManager	dq ?
	hOutput			dq ?

	FLAG_ENABLE	:= 1

	LoggingFlags		dd FLAG_ENABLE
	LoggingModes		dd ?	; bit for each mode

	vtbl dq	QueryInterface,\; IUnknown methods:
		AddRef,\
		Release,\
		OnUIEvent	; IUIEventLogger method
END BLOCK

;------------------------------------------------------------ IUnknown Methods:

QueryInterface:				; (this, REFIID iid, void** ppv) HRESULT
	cmp r8, 0xFFFF
	jbe .null

	and qword [r8], 0		; errors zero out parameters when possible

	cmp rdx, 0xFFFF
	jbe .arg

	mov r10, qword [rdx]
	mov r11, qword [rdx + 8]
	iterate iid, IID_IUnknown, IID_IUIEventLogger
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

; ------------------------------------------------------ IUIEventLogger Method:

:OnUIEvent:	; Receives notifications that a ribbon event has occurred.
;RCX		IUIEventLogger	*this
;RDX	[in]	UI_EVENTPARAMS	*pEventParams
	enter .frame + .local, 0
	virtual at rbp - .local
		.buffer		rw 1024

		.arg_list:
		.arg_type	dq ?
		.arg_pcmd_id	dq ?
		.arg_pcmd_name	dq ?
		.arg_cmd_id	dq ?
		.arg_cmd_name	dq ?
		.arg_section	dq ?
		.arg_loc	dq ?

		.local := ($-$$+15) and (-16)
	end virtual

; The event type determines UI_EVENTPARAMS meaning. Unknown or undocumented
; `EventType are just dumped.

	mov eax, [rdx + UI_EVENTPARAMS.EventType]
	lea r10, [EventType_Table]
	cmp eax, EventType_Table.limit
	jnc .event_unknown ; Y: first entry is unknown value, out of range
	movzx eax, byte [r10 + rax - EventType_Table.limit]
	add r10, rax
	mov [.arg_type], r10 ; store type string

	cmp [rdx + UI_EVENTPARAMS.EventType], 1 + UI_EVENTTYPE_ApplicationModeSwitched
	jc .shortshow

; what event stats are present?

	mov eax, [rdx + UI_EVENTPARAMS.Params.CommandID]
	mov [.arg_cmd_id], rax
	mov rax, [rdx + UI_EVENTPARAMS.Params.CommandName]
	mov [.arg_cmd_name], rax

	mov eax, [rdx + UI_EVENTPARAMS.Params.ParentCommandID]
	mov [.arg_pcmd_id], rax
	mov rax, [rdx + UI_EVENTPARAMS.Params.ParentCommandName]
	mov [.arg_pcmd_name], rax

	mov eax, [rdx + UI_EVENTPARAMS.Params.SelectionIndex]
	mov [.arg_section], rax

	mov eax, [rdx + UI_EVENTPARAMS.Params.Location]
	lea r10, [EventLocation_Table]
	cmp eax, EventLocation_Table.limit
	jnc @F ; Y: first entry is unknown value, out of range
	movzx eax, byte [r10 + rax - EventLocation_Table.limit]
	add r10, rax
@@:	mov [.arg_loc], r10 ; store type location string
	wvsprintfW & .buffer, <W \
		'[',27,'[96m','RibbonControlLogger',27,'[m','] ',\
		27,'[32m','UI_EVENTTYPE_%S.',27,'[m',10,\
		9,	27,'[90m','Parent Command',27,'[m',9,	'0x%08X %s',10,\
		9,	27,'[90m','Command',27,'[m',9,9,	'0x%08X %s',10,\
		9,	27,'[90m','Selection Index',27,'[m',9,	'0x%08X',10,\
		9,	27,'[90m','Location',27,'[m',9,		'UI_EVENTLOCATION_%S',10\
		>, & .arg_list
	jmp @F

; Regardless of documentation, it's unclear which fields are valid for these
; events. Basically, the field are not valid if [UI_EVENTPARAMS.Modes] or
; [UI_EVENTPARAMS.Params.CommandID] is zero. Reverse engineering also shows:
;	+0	EventType
;	+4	00 00 00 00		these bytes align the union
;	+8	Modes/CommandID		if zero only event type valid
;	+C	FD FF 00 00

.event_unknown:
	mov [.arg_type], r10
.shortshow:
	mov [.arg_loc], rdx ; UI_EVENTPARAMS
	wvsprintfW & .buffer, <W \
			'[',27,'[96m','RibbonControlLogger',27,'[m','] ',\
			27,'[32m','UI_EVENTTYPE_%S.',27,'[m',10\
		>, & .arg_list
	xchg r8d, eax ; characters
	WriteConsoleW [hOutput], & .buffer, r8d, 0, 0

	; At least six qwords of data in UI_EVENTPARAMS, dump data:
	wvsprintfW & .buffer, <W 27,'[90m',\
		9,' %016IX  %016IX',10,\
		9,'[%016IX] %016IX',10,\
		9,'[%016IX] %016IX',27,'[m',10>, [.arg_loc]
@@:	xchg r8d, eax ; characters
	WriteConsoleW [hOutput], & .buffer, r8d, 0, 0
	xor eax, eax ; S_OK
	leave
	retn



iterate <NAME,TYPE>,\
	"ApplicationMenuOpened",	UI_EVENTTYPE_ApplicationMenuOpened,\
	"RibbonMinimized",		UI_EVENTTYPE_RibbonMinimized,\
	"RibbonExpanded",		UI_EVENTTYPE_RibbonExpanded,\
	"ApplicationModeSwitched",	UI_EVENTTYPE_ApplicationModeSwitched,\
	"TabActivated",			UI_EVENTTYPE_TabActivated,\
	"MenuOpened",			UI_EVENTTYPE_MenuOpened,\
	"CommandExecuted",		UI_EVENTTYPE_CommandExecuted,\
	"TooltipShown",			UI_EVENTTYPE_TooltipShown

	assert TYPE = %-1 ; lookup sanity

	if %=1
		repeat %%
			{const:1} db EventType_Table.% - EventType_Table
		end repeat
		{const:1} EventType_Table db 27,'[31m',"UNKNOWN",0
		{const:1} EventType_Table.limit := %%
	end if
	{const:1} EventType_Table.% db NAME,0
end iterate

iterate <NAME,TYPE>,\
	"Ribbon",		UI_EVENTLOCATION_Ribbon,\
	"QAT",			UI_EVENTLOCATION_QAT,\
	"ApplicationMenu",	UI_EVENTLOCATION_ApplicationMenu,\
	"ContextPopup",		UI_EVENTLOCATION_ContextPopup

	assert TYPE = %-1 ; lookup sanity

	if %=1
		repeat %%
			{const:1} db EventLocation_Table.% - EventLocation_Table
		end repeat
		{const:1} EventLocation_Table db 27,'[31m',"UNKNOWN",0
		{const:1} EventLocation_Table.limit := %%
	end if
	{const:1} EventLocation_Table.% db NAME,0
end iterate

macro ← line& ; terse console output macro
	local str,chars
	COFF.2.CONST str du line
	COFF.2.CONST chars := ($ - str) shr 1
	WriteConsoleW [hOutput], & str, chars, 0, 0
end macro
