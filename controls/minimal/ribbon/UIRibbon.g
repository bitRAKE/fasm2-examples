if ~ definite __UIRibbon_g__
__UIRibbon_g__ := 1
;
; Interface hiarchy for the Windows Ribbon Framework:
;
; CLSID_UIRibbonImageFromBitmapFactory
;   IUIImageFromBitmap - IUIImage factory
;     IUIImage - methods to retrieve images for ribbon display
;
; CLSID_UIRibbonFramework
;   IUIFramework - core functionality
;     IUIRibbon - specify settings and properties for ribbon
;     IUIContextualUI - context popup view functionality
;     IUIEventingManager - event notification functionality
;     IUICollection - collection-based control manipulation
;
; Implemented by the Ribbon host application (the client connection sink):
;    IUIApplication - methods for the framework
;    IUICommandHandler - methods supporting command events/info from framework
;    IUICollectionChangedEvent - method required to handle collection changes
;    IUIEventLogger - defines ribbon event methods
;    IUIImage - methods to retrieve images for ribbon display
;
; IUISimplePropertySet - readonly property value method
;


include 'IUnknown.g'
include 'wtypes.g'

IUISimplePropertySet interface C205BB48-5B1C-4219-A106-15BD0A5F24E2,\
	EXTENDS__IUnknown,\
	GetValue


; (least dynamic)	Property >> Value >> State	(most dynamic)
; PROPERTYKEY structures for IUISimplePropertySet__GetValue use
iterate <INDEX,NAME,TYPE>,\
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

	; PKEY_* is for numerical comparison of PROPERTYKEY.pid member
	NAME := INDEX

	; UI_PKEY_* is for REFPROPERTYKEY parameter of methods:
	if used UI_#NAME
		{const:4} UI_#NAME PROPERTYKEY \
			fntid: UUID FFFFFFFF-7363-696E-8441798ACF5AEBB7,\
			pid: TYPE
		store INDEX:4 at UI_#NAME.fntid
	end if ; used UI_#NAME
end iterate

;typedef DWORD UI_HSBCOLOR;
;__inline UI_HSBCOLOR UI_HSB(BYTE hue, BYTE saturation, BYTE brightness) {
;    return hue | (saturation << 8) | (brightness << 16);
;}

; enum UI_CONTEXTAVAILABILITY
UI_CONTEXTAVAILABILITY_NOTAVAILABLE	:= 0
UI_CONTEXTAVAILABILITY_AVAILABLE	:= 1
UI_CONTEXTAVAILABILITY_ACTIVE		:= 2

; enum UI_FONTPROPERTIES
UI_FONTPROPERTIES_NOTAVAILABLE	:= 0
UI_FONTPROPERTIES_NOTSET	:= 1
UI_FONTPROPERTIES_SET		:= 2

; enum UI_FONTVERTICALPOSITION
UI_FONTVERTICALPOSITION_NOTAVAILABLE	:= 0
UI_FONTVERTICALPOSITION_NOTSET		:= 1
UI_FONTVERTICALPOSITION_SUPERSCRIPT	:= 2
UI_FONTVERTICALPOSITION_SUBSCRIPT	:= 3

; enum UI_FONTUNDERLINE
UI_FONTUNDERLINE_NOTAVAILABLE	:= 0
UI_FONTUNDERLINE_NOTSET		:= 1
UI_FONTUNDERLINE_SET		:= 2

; enum UI_FONTDELTASIZE
UI_FONTDELTASIZE_GROW	:= 0
UI_FONTDELTASIZE_SHRINK	:= 1

; enum UI_CONTROLDOCK
UI_CONTROLDOCK_TOP	:= 1
UI_CONTROLDOCK_BOTTOM	:= 3

; enum UI_SWATCHCOLORTYPE
UI_SWATCHCOLORTYPE_NOCOLOR	:= 0
UI_SWATCHCOLORTYPE_AUTOMATIC	:= 1
UI_SWATCHCOLORTYPE_RGB		:= 2

; enum UI_SWATCHCOLORMODE
UI_SWATCHCOLORMODE_NORMAL	:= 0
UI_SWATCHCOLORMODE_MONOCHROME	:= 1

; enum UI_EVENTTYPE
UI_EVENTTYPE_ApplicationMenuOpened	:= 0
UI_EVENTTYPE_RibbonMinimized		:= 1
UI_EVENTTYPE_RibbonExpanded		:= 2
UI_EVENTTYPE_ApplicationModeSwitched	:= 3
UI_EVENTTYPE_TabActivated		:= 4
UI_EVENTTYPE_MenuOpened			:= 5
UI_EVENTTYPE_CommandExecuted		:= 6
UI_EVENTTYPE_TooltipShown		:= 7

; enum UI_EVENTLOCATION
UI_EVENTLOCATION_Ribbon		:= 0
UI_EVENTLOCATION_QAT		:= 1
UI_EVENTLOCATION_ApplicationMenu:= 2
UI_EVENTLOCATION_ContextPopup	:= 3



IUIRibbon interface 803982AB-370A-4F7E-A9E7-8784036A6E26,\
	EXTENDS__IUnknown,\
	GetHeight,LoadSettingsFromStream,SaveSettingsToStream

IUIFramework interface F4F0385D-6872-43A8-AD09-4C339CB3F5C5,\
	EXTENDS__IUnknown,\
	Initialize,Destroy,LoadUI,GetView,GetUICommandProperty,SetUICommandProperty,InvalidateUICommand,FlushPendingInvalidations,SetModes

; enum UI_INVALIDATIONS
UI_INVALIDATIONS_STATE		:= 0x1
UI_INVALIDATIONS_VALUE		:= 0x2
UI_INVALIDATIONS_PROPERTY	:= 0x4
UI_INVALIDATIONS_ALLPROPERTIES	:= 0x8

UI_ALL_COMMANDS := 0



IUIEventLogger interface EC3E1034-DBF4-41A1-95D5-03E0F1026E05,\
	EXTENDS__IUnknown,\
	OnUIEvent

struct UI_EVENTPARAMS_COMMAND
	CommandID		dd ?
		__align0	dd ?
	CommandName		dq ?	; PCWSTR
	ParentCommandID		dd ?
		__align1	dd ?
	ParentCommandName	dq ?	; PCWSTR
	SelectionIndex		dd ?
	Location		dd ?	; UI_EVENTLOCATION
ends

struct UI_EVENTPARAMS
	EventType		dd ?	; UI_EVENTTYPE
		__align0	dd ?
	union
		Modes		dd ?
		Params		UI_EVENTPARAMS_COMMAND
	ends
ends



IUIEventingManager interface 3BE6EA7F-9A9B-4198-9368-9B0F923BD534,\
	EXTENDS__IUnknown,\
	SetEventLogger

IUIContextualUI interface EEA11F37-7C46-437C-8E55-B52122B29293,\
	EXTENDS__IUnknown,\
	ShowAtLocation

IUICollection interface DF4F45BF-6F9D-4DD7-9D68-D8F9CD18C4DB,\
	EXTENDS__IUnknown,\
	GetCount,GetItem,Add,Insert,RemoveAt,Replace,Clear
   
IUICollectionChangedEvent interface 6502AE91-A14D-44b5-BBD0-62AACC581D52,\
	EXTENDS__IUnknown,\
	OnChanged

; enum UI_COLLECTIONCHANGE
UI_COLLECTIONCHANGE_INSERT	:= 0
UI_COLLECTIONCHANGE_REMOVE	:= 1
UI_COLLECTIONCHANGE_REPLACE	:= 2
UI_COLLECTIONCHANGE_RESET	:= 3

UI_COLLECTION_INVALIDINDEX := 0xFFFFFFFF



IUICommandHandler interface 75AE0A2D-DC03-4C9F-8883-069660D0BEB6,\
	EXTENDS__IUnknown,\
	Execute,UpdateProperty

; enum UI_EXECUTIONVERB
UI_EXECUTIONVERB_EXECUTE	:= 0
UI_EXECUTIONVERB_PREVIEW	:= 1
UI_EXECUTIONVERB_CANCELPREVIEW	:= 2



IUIApplication interface D428903C-729A-491d-910D-682A08FF2522,\
	EXTENDS__IUnknown,\
	OnViewChanged,OnCreateUICommand,OnDestroyUICommand

; enum UI_COMMANDTYPE
UI_COMMANDTYPE_UNKNOWN		:= 0
UI_COMMANDTYPE_GROUP		:= 1
UI_COMMANDTYPE_ACTION		:= 2
UI_COMMANDTYPE_ANCHOR		:= 3
UI_COMMANDTYPE_CONTEXT		:= 4
UI_COMMANDTYPE_COLLECTION	:= 5
UI_COMMANDTYPE_COMMANDCOLLECTION:= 6
UI_COMMANDTYPE_DECIMAL		:= 7
UI_COMMANDTYPE_BOOLEAN		:= 8
UI_COMMANDTYPE_FONT		:= 9
UI_COMMANDTYPE_RECENTITEMS	:= 10
UI_COMMANDTYPE_COLORANCHOR	:= 11
UI_COMMANDTYPE_COLORCOLLECTION	:= 12

; enum UI_VIEWTYPE
UI_VIEWTYPE_RIBBON := 1

; enum UI_VIEWVERB
UI_VIEWVERB_CREATE	:= 0
UI_VIEWVERB_DESTROY	:= 1
UI_VIEWVERB_SIZE	:= 2
UI_VIEWVERB_ERROR	:= 3



IUIImage interface 23C8C838-4DE6-436B-AB01-5554BB7C30DD,\
	EXTENDS__IUnknown,\
	GetBitmap

IUIImageFromBitmap interface 18ABA7F3-4C1C-4BA2-BF6C-F5C3326FA816,\
	EXTENDS__IUnknown,\
	CreateImage

; enum UI_OWNERSHIP
UI_OWNERSHIP_TRANSFER	:= 0
UI_OWNERSHIP_COPY	:= 1



;#define UI_MAKEAPPMODE(x) (1 << (x))

define UUID.CLSID_UIRibbonFramework 926749FA-2615-4987-8845-C33E65F2B957
define UUID.CLSID_UIRibbonImageFromBitmapFactory 0F7434B6-59B6-4250-999E-D168D6AE4293
define UUID.LIBID_UIRibbon 942F35C2-E83B-45EF-B085-AC295DD63D5B

; these are not part of an interface, so a helper is needed to create them automatically
iterate uuid, CLSID_UIRibbonFramework,CLSID_UIRibbonImageFromBitmapFactory,LIBID_UIRibbon
	if used uuid
		{const:16} uuid UUID uuid ; instantiate from namespace
	end if
end iterate

end if ;~ definite __UIRibbon_g__
