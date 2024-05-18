if __FILE__ = __SOURCE__ ; ------------------------------- building object file

	format MS64 COFF
	section '.text$t' code executable readable align 64

	include 'macro\struct.inc'
	public pcg32_initialize
	public pcg32_random_r

pcg32_initialize:
	rdrand rax
	mov [rbp + pcg32.state], rax

	rdrand rax
	or al, 1
	mov [rbp + pcg32.increment], rax
	retn

pcg32_random_r: ; https://www.pcg-random.org
	mov rcx, [rbp + pcg32.state]
	mov rax, 6364136223846793005
	imul rax, rcx
	add rax, [rbp + pcg32.increment]
	mov [rbp + pcg32.state], rax
	mov rax, rcx
	shr rax, 18
	xor rax, rcx
	shr rcx, 59
	shr rax, 27
	ror eax, cl
	retn

else ; ---------------------------------------------------- including interface

	extrn pcg32_initialize
	extrn pcg32_random_r

end if

; ---------------------------------------------------------- common definitions

struct pcg32
	state		dq ?
	increment	dq ?
ends
