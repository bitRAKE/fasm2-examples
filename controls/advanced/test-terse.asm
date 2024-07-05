include 'macro\struct.inc'
include 'equates\user64.inc'

include 'dlg32.g'
include 'RC-terse.g' ; terse RC CONTROL keywords


;---------------------------------------------------------------------------TEST
; exact dialog from Raymond Chen's blog ...
;
; not my flavor, syntax-wise :/
; yet, if tooling is producing the script - does it matter?

findtext DLGTEMPLATEEX title: "Replace",\
	style: WS_POPUP or WS_CAPTION or WS_SYSMENU or DS_MODALFRAME or DS_3DLOOK,\
	x: 36, y: 44, cx: 230, cy: 94,\
	pointsize: 8, typeface: "MS Shell Dlg"

LTEXT "Fi&nd What:",-1, 4,9,48,8, WS_GROUP
EDITTEXT 0x0480, 54,7,114,12, WS_GROUP or ES_AUTOHSCROLL

LTEXT "Re&place with:",-1, 4,26,48,8, WS_GROUP
EDITTEXT 0x0481, 54,24,114,12, WS_GROUP or ES_AUTOHSCROLL

AUTOCHECKBOX	"Match &whole word only",	0x0410, 5,46,104,12, WS_GROUP
AUTOCHECKBOX	"Match &case",			0x0411, 5,62,59,12

DEFPUSHBUTTON	"&Find Next",	IDOK,		174,4,50,14, WS_GROUP
PUSHBUTTON	"&Replace",	0x0400,		174,21,50,14
PUSHBUTTON	"Replace &All",	0x0401,		174,38,50,14
PUSHBUTTON	"Cancel",	IDCANCEL,	174,55,50,14
PUSHBUTTON	"Replace &All",	0x040E,		174,75,50,14
