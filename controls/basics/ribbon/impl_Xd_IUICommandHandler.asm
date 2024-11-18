;
; IUICommandHandler is an interface required to link commands to methods.
;
; :HACK: No command should actually use this handler. Except debugging.
;
include 'windows.g'
include 'winerror.g'
include 'UIRibbon.g'
include 'debug.asm'

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

:UpdateProperty:;	IUICommandHandler* this
;			UINT nCmdID
;	__in		REFPROPERTYKEY key
;	__in_opt const	PROPVARIANT* ppropvarCurrentValue
;	__out		PROPVARIANT* ppropvarNewValue
	enter .frame, 0
	virtual at rbp+16
					rq 4 ; shadow-space
		.ppropvarNewValue	dq ?
	end virtual

	debug_command_handler_update_property

	leave
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
	enter .frame, 0
	virtual at rbp+16
						rq 4 ; shadow-space
		.ppropvarValue			dq ?
		.pCommandExecutionProperties	dq ?
	end virtual

	debug_command_handler_execute

	leave
	xor eax, eax ; S_OK
	retn



:debug_PKEY_index2name:
iterate <INDEX,	NAME,TYPE>,\
	1,	UI_PKEY_Enabled,VT_BOOL,\
	2,	UI_PKEY_LabelDescription,VT_LPWSTR,\
	3,	UI_PKEY_Keytip,VT_LPWSTR,\
	4,	UI_PKEY_Label,VT_LPWSTR,\
	5,	UI_PKEY_TooltipDescription,VT_LPWSTR,\
	6,	UI_PKEY_TooltipTitle,VT_LPWSTR,\
	7,	UI_PKEY_LargeImage,VT_UNKNOWN,\
	8,	UI_PKEY_LargeHighContrastImage,VT_UNKNOWN,\
	9,	UI_PKEY_SmallImage,VT_UNKNOWN,\
	10,	UI_PKEY_SmallHighContrastImage,VT_UNKNOWN,\
	100,	UI_PKEY_CommandId,VT_UI4,\
	101,	UI_PKEY_ItemsSource,VT_UNKNOWN,\
	102,	UI_PKEY_Categories,VT_UNKNOWN,\
	103,	UI_PKEY_CategoryId,VT_UI4,\
	104,	UI_PKEY_SelectedItem,VT_UI4,\
	105,	UI_PKEY_CommandType,VT_UI4,\
	106,	UI_PKEY_ItemImage,VT_UNKNOWN,\
	200,	UI_PKEY_BooleanValue,VT_BOOL,\
	201,	UI_PKEY_DecimalValue,VT_DECIMAL,\
	202,	UI_PKEY_StringValue,VT_LPWSTR,\
	203,	UI_PKEY_MaxValue,VT_DECIMAL,\
	204,	UI_PKEY_MinValue,VT_DECIMAL,\
	205,	UI_PKEY_Increment,VT_DECIMAL,\
	206,	UI_PKEY_DecimalPlaces,VT_UI4,\
	207,	UI_PKEY_FormatString,VT_LPWSTR,\
	208,	UI_PKEY_RepresentativeString,VT_LPWSTR,\
	300,	UI_PKEY_FontProperties,VT_UNKNOWN,\
	301,	UI_PKEY_FontProperties_Family,VT_LPWSTR,\
	302,	UI_PKEY_FontProperties_Size,VT_DECIMAL,\
	303,	UI_PKEY_FontProperties_Bold,VT_UI4,\
	304,	UI_PKEY_FontProperties_Italic,VT_UI4,\
	305,	UI_PKEY_FontProperties_Underline,VT_UI4,\
	306,	UI_PKEY_FontProperties_Strikethrough,VT_UI4,\
	307,	UI_PKEY_FontProperties_VerticalPositioning,VT_UI4,\
	308,	UI_PKEY_FontProperties_ForegroundColor,VT_UI4,\
	309,	UI_PKEY_FontProperties_BackgroundColor,VT_UI4,\
	310,	UI_PKEY_FontProperties_ForegroundColorType,VT_UI4,\
	311,	UI_PKEY_FontProperties_BackgroundColorType,VT_UI4,\
	312,	UI_PKEY_FontProperties_ChangedProperties,VT_UNKNOWN,\
	313,	UI_PKEY_FontProperties_DeltaSize,VT_UI4,\
	350,	UI_PKEY_RecentItems,VT_ARRAY or VT_UNKNOWN,\
	351,	UI_PKEY_Pinned,VT_BOOL,\
	400,	UI_PKEY_Color,VT_UI4,\
	401,	UI_PKEY_ColorType,VT_UI4,\
	402,	UI_PKEY_ColorMode,VT_UI4,\
	403,	UI_PKEY_ThemeColorsCategoryLabel,VT_LPWSTR,\
	404,	UI_PKEY_StandardColorsCategoryLabel,VT_LPWSTR,\
	405,	UI_PKEY_RecentColorsCategoryLabel,VT_LPWSTR,\
	406,	UI_PKEY_AutomaticColorLabel,VT_LPWSTR,\
	407,	UI_PKEY_NoColorLabel,VT_LPWSTR,\
	408,	UI_PKEY_MoreColorsLabel,VT_LPWSTR,\
	409,	UI_PKEY_ThemeColors,VT_VECTOR or VT_UI4,\
	410,	UI_PKEY_StandardColors,VT_VECTOR or VT_UI4,\
	411,	UI_PKEY_ThemeColorsTooltips,VT_VECTOR or VT_LPWSTR,\
	412,	UI_PKEY_StandardColorsTooltips,VT_VECTOR or VT_LPWSTR,\
	1000,	UI_PKEY_Viewable,VT_BOOL,\
	1001,	UI_PKEY_Minimized,VT_BOOL,\
	1002,	UI_PKEY_QuickAccessToolbarDock,VT_UI4,\
	1100,	UI_PKEY_ContextAvailable,VT_UI4,\
	2000,	UI_PKEY_GlobalBackgroundColor,VT_UI4,\
	2001,	UI_PKEY_GlobalHighlightColor,VT_UI4,\
	2002,	UI_PKEY_GlobalTextColor,VT_UI4

	if 1 = %
		.key_count:=%%+1
		{data:1} label .pkeys:%%
		repeat %%
			indx %
			{data:1} dw INDEX
		end repeat
		{data:1} dw 0
		repeat %%
			{data:1} dw .% - .pkeys
		end repeat
		{data:1} dw .0 - .pkeys
		{data:1} .0 db 27,'[31m',"key not found",0
		indx 1
	end if
	{data:1} .% db `NAME,0
end iterate

	lea r11, [.pkeys]
	xor r10, r10
.more:	cmp ax, [r11 + r10*2]
	jz .found
	inc r10
	cmp word [r11 + r10*2], 0
	jnz .more
.found:
	movzx r10, word [r11 + 2*(r10 + .key_count)]
	add r10, r11
	xchg rax, r10
	retn

; DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG

macro debug_command_handler_update_property
	mov eax, [r8] ; key index
	call debug_PKEY_index2name
	ABISAFE_DebugLogMessage <\
		27,'[34m',"IUICommandHandler::UpdateProperty",27,'[m',"(",\
		27,'[90m'," *this : %p",10,\
		27,'[90m',"               UINT                       nCmdID : ",27,'[m',"%d",10,\
		27,'[90m',"__in           REFPROPERTYKEY                key : ",27,'[35m',"%hs",10,\
		27,'[90m',"__in_opt const PROPVARIANT* ppropvarCurrentValue : %p",10,\
		27,'[90m',"__out          PROPVARIANT*     ppropvarNewValue : %p",10,\
		27,'[m',")",10>, rcx, rdx, rax, r9, [.ppropvarNewValue]
end macro

macro debug_command_handler_execute
	xor eax, eax
	test r9, r9
	jz @F
	mov eax, [r9] ; optional, key index, CMOVNZ doesn't work here :-)
@@:	call debug_PKEY_index2name

	iterate verb_string,\
		"_EXECUTE",\
		"_PREVIEW",\
		"_CANCELPREVIEW",\
		<27,'[31m'," not found">
		if 1 = %
			{const:1} label .verbs:%%
			repeat %%
				{const:1} db .verbs.% - .verbs
			end repeat
		end if
		{const:1} .verbs.% db verb_string,0
	end iterate
	mov r11d, sizeof .verbs - 1
	cmp r8d, r11d
	cmovc r11d, r8d
	lea r10, [.verbs]
	movzx r11, byte [r10 + r11]
	add r10, r11

	ABISAFE_DebugLogMessage <\
		27,'[32m',"IUICommandHandler::Execute",27,'[m',"(",\
		27,'[90m'," *this : %p",10,\
		27,'[90m',"               UINT                nCmdID : ",27,'[m',"%d",10,\
		27,'[90m',"               UI_EXECUTIONVERB      verb : ",27,'[32m',"UI_EXECUTIONVERB%hs",10,\
		27,'[90m',"__in_opt const PROPERTYKEY*           key : ",27,'[35m',"%hs",10,\
		27,'[90m',"__in_opt const PROPVARIANT* ppropvarValue : %p",10,\
		27,'[90m',"__in_opt UISimplePropertySet* pCommandExecutionProperties : %p",10,\
		27,'[m',")",10>, rcx, rdx, r10, rax, [.ppropvarValue], [.pCommandExecutionProperties]
end macro
