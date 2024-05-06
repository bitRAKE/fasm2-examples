if ~ definite G_WINCON
G_WINCON := 1
;-------------------------------------------------------------------------------
; wincontypes.h -- data types exported by the NT console subsystem

struct COORD
	X dw ?
	Y dw ?
ends

struct SMALL_RECT
	Left	dw ?
	Top	dw ?
	Right	dw ?
	Bottom	dw ?
ends

struct KEY_EVENT_RECORD
	bKeyDown		dd ?
	wRepeatCount		dw ?
	wVirtualKeyCode		dw ?
	wVirtualScanCode	dw ?
	union
		UnicodeChar	dw ?
		AsciiChar	db ?
	ends
	dwControlKeyState	dd ?
ends

; dwControlKeyState flags
RIGHT_ALT_PRESSED	:=0x0001 ; right alt key is pressed
LEFT_ALT_PRESSED	:=0x0002 ; left alt key is pressed
RIGHT_CTRL_PRESSED	:=0x0004 ; right ctrl key is pressed
LEFT_CTRL_PRESSED	:=0x0008 ; left ctrl key is pressed
SHIFT_PRESSED		:=0x0010 ; shift key is pressed
NUMLOCK_ON		:=0x0020 ; numlock light is on
SCROLLLOCK_ON		:=0x0040 ; scrolllock light is on
CAPSLOCK_ON		:=0x0080 ; capslock light is on
ENHANCED_KEY		:=0x0100 ; key is enhanced
NLS_ALPHANUMERIC	:=0x00000000 ; DBCS for JPN: Alphanumeric mode
NLS_DBCSCHAR		:=0x00010000 ; DBCS for JPN: SBCS/DBCS mode
NLS_KATAKANA		:=0x00020000 ; DBCS for JPN: Katakana mode
NLS_HIRAGANA		:=0x00040000 ; DBCS for JPN: Hiragana mode
NLS_ROMAN		:=0x00400000 ; DBCS for JPN: Roman/Noroman mode
NLS_IME_CONVERSION	:=0x00800000 ; DBCS for JPN: IME conversion
ALTNUMPAD_BIT		:=0x04000000 ; AltNumpad OEM char ; internal_NT
NLS_IME_DISABLE		:=0x20000000 ; DBCS for JPN: IME enable/disable

struct MOUSE_EVENT_RECORD
	dwMousePosition		COORD
	dwButtonState		dd ?
	dwControlKeyState	dd ?
	dwEventFlags		dd ?
ends

; dwButtonState flags:
FROM_LEFT_1ST_BUTTON_PRESSED	:=0x0001
RIGHTMOST_BUTTON_PRESSED	:=0x0002
FROM_LEFT_2ND_BUTTON_PRESSED	:=0x0004
FROM_LEFT_3RD_BUTTON_PRESSED	:=0x0008
FROM_LEFT_4TH_BUTTON_PRESSED	:=0x0010

; dwEventFlags flags:
MOUSE_MOVED	:=0x0001
DOUBLE_CLICK	:=0x0002
MOUSE_WHEELED	:=0x0004
MOUSE_HWHEELED	:=0x0008

struct WINDOW_BUFFER_SIZE_RECORD
	dwSize COORD
ends
struct MENU_EVENT_RECORD
	dwCommandId	dd ?
ends
struct FOCUS_EVENT_RECORD
	bSetFocus	dd ?
ends

struct INPUT_RECORD
	EventType	dw ?,?
; NOTE : we skip the 'Event' scope to shorten access
	union
		KeyEvent		KEY_EVENT_RECORD
		MouseEvent		MOUSE_EVENT_RECORD
		WindowBufferSizeEvent	WINDOW_BUFFER_SIZE_RECORD
		MenuEvent		MENU_EVENT_RECORD
		FocusEvent		FOCUS_EVENT_RECORD
	ends
ends

; EventType flags:
; NOTE: why are these flags, only one type of event record possible?
KEY_EVENT		:= 0x0001
MOUSE_EVENT		:= 0x0002
WINDOW_BUFFER_SIZE_EVENT:= 0x0004
MENU_EVENT		:= 0x0008
FOCUS_EVENT		:= 0x0010

struct CHAR_INFO
	union
		UnicodeChar	dw ?
		AsciiChar	db ?
	ends
	Attributes dw ?
ends

struct CONSOLE_FONT_INFO
	nFont		dd ?
	dwFontSize	COORD
ends

;-------------------------------------------------------------------------------
; consoleapi.h -- ApiSet Contract for api-ms-win-core-console-l1

ENABLE_PROCESSED_INPUT	:= 0x0001
ENABLE_LINE_INPUT	:= 0x0002
ENABLE_ECHO_INPUT	:= 0x0004
ENABLE_WINDOW_INPUT	:= 0x0008
ENABLE_MOUSE_INPUT	:= 0x0010
ENABLE_INSERT_MODE	:= 0x0020
ENABLE_QUICK_EDIT_MODE	:= 0x0040
ENABLE_EXTENDED_FLAGS	:= 0x0080
ENABLE_AUTO_POSITION	:= 0x0100
ENABLE_VIRTUAL_TERMINAL_INPUT := 0x0200

ENABLE_PROCESSED_OUTPUT		:= 0x0001
ENABLE_WRAP_AT_EOL_OUTPUT	:= 0x0002
ENABLE_VIRTUAL_TERMINAL_PROCESSING := 0x0004
DISABLE_NEWLINE_AUTO_RETURN	:= 0x0008
ENABLE_LVB_GRID_WORLDWIDE	:= 0x0010

struct CONSOLE_READCONSOLE_CONTROL
	nLength dd ?
	nInitialChars dd ?
	dwCtrlWakeupMask dd ?
	dwControlKeyState dd ?
ends

;CTRL_C_EVENT		:= 0
;CTRL_BREAK_EVENT	:= 1
;CTRL_CLOSE_EVENT	:= 2
;	reserved!	:= 3
;	reserved!	:= 4
;CTRL_LOGOFF_EVENT	:= 5
;CTRL_SHUTDOWN_EVENT	:= 6


;-------------------------------------------------------------------------------
; consoleapi2.h -- ApiSet Contract for api-ms-win-core-console-l2

FOREGROUND_BLUE			:=0x0001
FOREGROUND_GREEN		:=0x0002
FOREGROUND_RED			:=0x0004
FOREGROUND_INTENSITY		:=0x0008
BACKGROUND_BLUE			:=0x0010
BACKGROUND_GREEN		:=0x0020
BACKGROUND_RED			:=0x0040
BACKGROUND_INTENSITY		:=0x0080
COMMON_LVB_LEADING_BYTE		:=0x0100
COMMON_LVB_TRAILING_BYTE	:=0x0200
COMMON_LVB_GRID_HORIZONTAL	:=0x0400
COMMON_LVB_GRID_LVERTICAL	:=0x0800
COMMON_LVB_GRID_RVERTICAL	:=0x1000
COMMON_LVB_REVERSE_VIDEO	:=0x4000
COMMON_LVB_UNDERSCORE		:=0x8000

COMMON_LVB_SBCSDBCS		:=0x0300

struct CONSOLE_SCREEN_BUFFER_INFO ; 22 bytes
	dwSize			COORD
	dwCursorPosition	COORD
	wAttributes		dw ?
	srWindow		SMALL_RECT
	dwMaximumWindowSize	COORD
ends

struct CONSOLE_SCREEN_BUFFER_INFOEX ; 96 bytes
	cbSize			dd ?

; CONSOLE_SCREEN_BUFFER_INFO:
	dwSize			COORD
	dwCursorPosition	COORD
	wAttributes		dw ?
	srWindow		SMALL_RECT
	dwMaximumWindowSize	COORD

	wPopupAttributes	dw ?
	bFullscreenSupported	dd ?
	ColorTable		dd 16 dup (?) ; COLORREF
ends

;-------------------------------------------------------------------------------
; consoleapi3.h -- ApiSet Contract for api-ms-win-core-console-l3

struct CONSOLE_FONT_INFOEX
	cbSize			dd ?
	nFont			dd ?
	dwFontSize		COORD
	FontFamily		dd ?
	FontWeight		dd ?
	FaceName		du 32 dup (?) ; gdi.LF_FACESIZE
ends

CONSOLE_NO_SELECTION		:=0x0000
CONSOLE_SELECTION_IN_PROGRESS	:=0x0001
CONSOLE_SELECTION_NOT_EMPTY	:=0x0002
CONSOLE_MOUSE_SELECTION		:=0x0004
CONSOLE_MOUSE_DOWN		:=0x0008

struct CONSOLE_SELECTION_INFO
	dwFlags			dd ?
	dwSelectionAnchor	COORD
	srSelection		SMALL_RECT
ends

HISTORY_NO_DUP_FLAG := 1

struct CONSOLE_HISTORY_INFO
	cbSize			dd ?
	HistoryBufferSize	dd ?
	NumberOfHistoryBuffers	dd ?
	dwFlags			dd ?
ends

CONSOLE_FULLSCREEN		:= 1
CONSOLE_FULLSCREEN_HARDWARE	:= 2

CONSOLE_FULLSCREEN_MODE		:= 1
CONSOLE_WINDOWED_MODE		:= 2

end if ; G_WINCON
