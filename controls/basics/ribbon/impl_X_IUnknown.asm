;
; IUnknown static is an interface inherrited by other interfaces.
;
; By using an array of supported interfaces, the parent interface can reuse this code:
;
;	{const:16} .iids UUID IID_IUnknown, ..., ?+.iids
;	QueryInterface:	lea rax, [.iids]
;			jmp xQueryInterface
;
; Trade-offs:	(new)				(old)
;	data	16*(N+1) bytes			16*N		(N=interfaces)
;	code	12 bytes + (100 bytes)		96 bytes
;
; :NOTE: This isn't a typical COM object:
;	- no function table (only inheritable by `special interfaces)
;	- no reference counting
;	- single static object without any dynamic data
;	- no factory to create instances - public object!

include 'windows.g'
include 'winerror.g'

; Good for ALL static IID_IUICommandHandler interfaces:
public xQueryInterface	as "X_IUnknown.xQueryInterface"
public AddRef		as "X_IUnknown.AddRef"
public Release		as "X_IUnknown.Release"

;------------------------------------------------------------ IUnknown Methods:
;	QueryInterface: ; (IUnknown* this, REFIID iid, void** ppv) HRESULT
;		lea rax, [.iids]
xQueryInterface:
; RAX : array of IID_*, self-terminated
	cmp rax, 0xFFFF
	jbe .fatal

	cmp r8, 0xFFFF
	jbe .null

	and qword [r8], 0		; errors zero out parameters when possible

	cmp rdx, 0xFFFF
	jbe .arg

	mov r10, [rdx]
	mov r11, [rdx + 8]

; reduce data by putting IID_Unknown test here

.more:	cmp [rax], r10
	jnz .next
	cmp [rax + 8], r11
	jz .ok

.next:	add rax, 16
	cmp [rax], rax
	jnz .more
	cmp [rax + 8], rax
	jnz .more

	mov eax, E_NOINTERFACE
	retn

.fatal:	__fastfail 7 ; Program state unknown - just stop.

.null:	mov eax, E_POINTER
	retn

.arg:	mov eax, E_INVALIDARG
	retn

.ok:	mov [r8], rcx
	xor eax, eax ; S_OK
	retn

AddRef:					; IUnknown* this
Release:				; IUnknown* this
	mov eax, 1			; return current reference count
	retn
