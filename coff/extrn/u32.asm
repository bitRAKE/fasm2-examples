if __FILE__ = __SOURCE__ ;				building object file

format MS64 COFF
section '.text$t' code executable readable align 64

public u32__ToString


; EAX : unsigned number to convert
; RDI : string buffer to receive digits

u32__ToString:
	push -1
.tens:	xor edx, edx
	div [.10]
	push rdx
	test eax, eax
	jnz .tens
	pop rax
.ascii:	add al, '0'
	stosb
	pop rax
	test eax, eax
	jns .ascii
	retn ; RAX : -1, RDX : 0-9, RDI++
.10	dd 10

else ;							including interface

extrn u32__ToString

end if

; ---------------------------------------------------------- common definitions
