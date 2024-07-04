;░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
; Adapt template to RC CONTROL statement terse syntax:

calminstruction CONTROL TITLE:'',ID:-1,WINDOWCLASS*,X:0,Y:0,CX:0,CY:0,STYLE:0,EXSTYLE:0,HELPID:0
	call DLGITEMTEMPLATEEX helpID: HELPID, exStyle: EXSTYLE, style: STYLE, x: X, y: Y, cx: CX, cy: CY, id: ID, windowClass: WINDOWCLASS, title: TITLE
end calminstruction

;-------------------------------------------------------------------------------
; RC Script Control Keyword Mappings
;	+ simplified syntax is easier to read/write
;	+ common default control styling
;
; AUTO3STATE		automatic three-state check box
; AUTOCHECKBOX		automatic check box
; AUTORADIOBUTTON	automatic radio button
; CHECKBOX		check box
; COMBOBOX		combo box
; CONTROL		application-defined
; CTEXT			centered-text
; DEFPUSHBUTTON		default pushbutton
; EDITTEXT		edit
; GROUPBOX		group box
; ICON			icon
; LISTBOX		list box
; LTEXT			left-aligned text
; PUSHBOX		push box
; PUSHBUTTON		push button
; RADIOBUTTON		radio button
; RTEXT			right-aligned
; SCROLLBAR		scroll bar
; STATE3		three-state check box

calminstruction AUTO3STATE text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_AUTO3STATE or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction AUTOCHECKBOX text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_AUTOCHECKBOX or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction AUTORADIOBUTTON text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_AUTORADIOBUTTON or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction CHECKBOX text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_CHECKBOX or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction COMBOBOX id,x,y,width,height,style:0,extended:0
call CONTROL "",id,"COMBOBOX",x,y,width,height,\
	CBS_SIMPLE or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction CTEXT text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"STATIC",x,y,width,height,\
	SS_CENTER or WS_GROUP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction DEFPUSHBUTTON text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_DEFPUSHBUTTON or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction EDITTEXT id,x,y,width,height,style:0,extended:0
call CONTROL "",id,"EDIT",x,y,width,height,\
	ES_LEFT or WS_BORDER or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction GROUPBOX text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_GROUPBOX or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction ICON text,id,x,y,width:0,height:0,style:0,extended:0
call CONTROL text,id,"STATIC",x,y,width,height,\
	SS_ICON or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction LISTBOX id,x,y,width,height,style:0,extended:0
call CONTROL "",id,"LISTBOX",x,y,width,height,\
	LBS_NOTIFY or WS_BORDER or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction LTEXT text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"STATIC",x,y,width,height,\
	SS_LEFT or WS_GROUP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction PUSHBOX text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_PUSHBOX or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction PUSHBUTTON text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_PUSHBUTTON or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction RADIOBUTTON text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_RADIOBUTTON or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction RTEXT text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"STATIC",x,y,width,height,\
	SS_RIGHT or WS_GROUP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction SCROLLBAR id,x,y,width,height,style:0,extended:0
call CONTROL "",id,"SCROLLBAR",x,y,width,height,\
	SBS_HORZ or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction
calminstruction STATE3 text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"BUTTON",x,y,width,height,\
	BS_3STATE or WS_TABSTOP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction

;░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

; could extend the concept to common control use ...

calminstruction BITMAP text,id,x,y,width,height,style:0,extended:0
call CONTROL text,id,"STATIC",x,y,width,height,\
	SS_BITMAP or WS_VISIBLE or WS_CHILD or style,extended
end calminstruction

if 0 ; WIP

; configure control defaults:

ACS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP or ACS_TRANSPARENT
CBS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP or CBS_SIMPLE
DTS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
HDS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
IPS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
LVS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
LWS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
MCS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
PBS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
RBS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
SBT_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
TBS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
TCS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
TTS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
TVS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
UDS_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP
TBSTYLE_DEFAULT:=WS_CHILD or WS_VISIBLE or WS_TABSTOP


calminstruction ANIMATE text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysAnimate32",x,y,width,height,ACS_DEFAULT or style,extended
end calminstruction

calminstruction COMBOBOXEX text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"ComboBoxEx32",x,y,width,height,CBS_DEFAULT or style,extended
end calminstruction

calminstruction DATETIME text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysDateTimePick32",x,y,width,height,DTS_DEFAULT or style,extended
end calminstruction

calminstruction HEADER text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysHeader32",x,y,width,height,HDS_DEFAULT or style,extended
end calminstruction

calminstruction IPADDR text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysIPAddress32",x,y,width,height,IPS_DEFAULT or style,extended
end calminstruction

calminstruction LISTVIEW text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysListView32",x,y,width,height,LVS_DEFAULT or style,extended
end calminstruction

calminstruction MONTHCAL text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysMonthCal32",x,y,width,height,MCS_DEFAULT or style,extended
end calminstruction

calminstruction PROGRESS text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"msctls_progress32",x,y,width,height,PBS_DEFAULT or style,extended
end calminstruction

calminstruction REBAR text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"ReBarWindow32",x,y,width,height,RBS_DEFAULT or style,extended
end calminstruction

calminstruction STATUSBAR text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"msctls_statusbar32",x,y,width,height,SBT_DEFAULT or style,extended
end calminstruction

calminstruction SYSLINK text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysLink",x,y,width,height,LWS_DEFAULT or style,extended
end calminstruction

calminstruction TABS text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysTabControl32",x,y,width,height,TCS_DEFAULT or style,extended
end calminstruction

calminstruction TOOLBAR text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"ToolbarWindow32",x,y,width,height,TBSTYLE_DEFAULT or style,extended
end calminstruction

calminstruction TOOLTIP text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"tooltips_class32",x,y,width,height,TTS_DEFAULT or style,extended
end calminstruction

calminstruction TRACKBAR text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"msctls_trackbar32",x,y,width,height,TBS_DEFAULT or style,extended
end calminstruction

calminstruction TREEVIEW text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"SysTreeView32",x,y,width,height,TVS_DEFAULT or style,extended
end calminstruction

calminstruction UPDOWN text,id,x,y,width,height,style:0,extended:0
	call CONTROL text,id,"msctls_updown32",x,y,width,height,UDS_DEFAULT or style,extended
end calminstruction

end if ; WIP
