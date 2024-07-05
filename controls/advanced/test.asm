include 'macro\struct.inc'
include 'equates\user64.inc'

include 'dlg32.g'

;---------------------------------------------------------------------------TEST
; exact dialog from Raymond Chen's blog ...
;
; beautiful syntax, I like the verbosity. :-)

findtext DLGTEMPLATEEX title: "Replace",\
	style: WS_POPUP or WS_CAPTION or WS_SYSMENU or DS_MODALFRAME or DS_3DLOOK,\
	x: 36, y: 44, cx: 230, cy: 94,\
	pointsize: 8, typeface: "MS Shell Dlg"

DLGITEMTEMPLATEEX title: "Fi&nd What:", id: -1, windowClass: Static,\
	style: WS_GROUP or SS_LEFT or WS_VISIBLE or WS_CHILD,\
	x: 4, y: 9, cx: 48, cy: 8

DLGITEMTEMPLATEEX id: 0x0480, windowClass: Edit,\
	style: WS_GROUP or WS_BORDER or WS_TABSTOP or ES_AUTOHSCROLL or WS_VISIBLE or WS_CHILD,\
	x: 54, y: 7, cx: 114, cy: 12

DLGITEMTEMPLATEEX title: "Re&place with:", id: -1, windowClass: Static,\
	style: WS_GROUP or SS_LEFT or WS_VISIBLE or WS_CHILD,\
	x: 4, y: 26, cx: 48, cy: 8

DLGITEMTEMPLATEEX id: 0x0481, windowClass: Edit,\
	style: WS_GROUP or WS_BORDER or WS_TABSTOP or ES_AUTOHSCROLL or WS_VISIBLE or WS_CHILD,\
	x: 54, y: 24, cx: 114, cy: 12

DLGITEMTEMPLATEEX title: "Match &whole word only", id: 0x0410, windowClass: Button,\
	style: WS_GROUP or WS_TABSTOP or BS_AUTOCHECKBOX or WS_VISIBLE or WS_CHILD,\
	x: 5, y: 46, cx: 104, cy: 12

DLGITEMTEMPLATEEX title: "Match &case", id: 0x0411, windowClass: Button,\
	style: WS_TABSTOP or BS_AUTOCHECKBOX or WS_VISIBLE or WS_CHILD,\
	x: 5, y: 62, cx: 59, cy: 12

DLGITEMTEMPLATEEX title: "&Find Next", id: IDOK, windowClass: Button,\
	style: WS_GROUP or WS_TABSTOP or BS_DEFPUSHBUTTON or WS_VISIBLE or WS_CHILD,\
	x: 174, y: 4, cx: 50, cy: 14

DLGITEMTEMPLATEEX title: "&Replace", id: 0x0400, windowClass: Button,\
	style: WS_TABSTOP or BS_PUSHBUTTON or WS_VISIBLE or WS_CHILD,\
	x: 174, y: 21, cx: 50, cy: 14

DLGITEMTEMPLATEEX title: "Replace &All", id: 0x0401, windowClass: Button,\
	style: WS_TABSTOP or BS_PUSHBUTTON or WS_VISIBLE or WS_CHILD,\
	x: 174, y: 38, cx: 50, cy: 14

DLGITEMTEMPLATEEX title: "Cancel", id: IDCANCEL, windowClass: Button,\
	style: WS_TABSTOP or BS_PUSHBUTTON or WS_VISIBLE or WS_CHILD,\
	x: 174, y: 55, cx: 50, cy: 14

DLGITEMTEMPLATEEX title: "&Help", id: 0x040E, windowClass: Button,\
	style: WS_TABSTOP or BS_PUSHBUTTON or WS_VISIBLE or WS_CHILD,\
	x: 174, y: 75, cx: 50, cy: 14
