
; Console debugging support is gated here by the DEBUG symbol, or externally
; [at a higher scope] in the build system. Code shouldn't be peppered with
; DEBUG conditionals unless absolutely needed.

if definite DEBUG & DEBUG
if __SOURCE__ = __FILE__
	format MS64 COFF
	section '.bss$t' udata readable writeable align 64

	g_buffer	rw 2048

	; standard handles:
	hInput		dq ?
	hOutput		dq ?
	hError		dq ?

	public g_buffer

	public hInput
	public hOutput
	public hError
else;--------------------------------------------------------------------------
	if used g_buffer
		extrn g_buffer
	end if
	if used hInput
		extrn hInput
	end if
	if used hOutput
		extrn hOutput
	end if
	if used hError
		extrn hError
	end if

	macro debug_startup
		GetStdHandle STD_OUTPUT_HANDLE
		mov [hOutput], rax
	end macro

	macro ← line& ; terse console output macro
		local str,chars
		COFF.2.CONST str du line
		COFF.2.CONST chars := ($ - str) shr 1
		WriteConsoleW [hOutput], & str, chars, 0, 0
	end macro

	macro DebugLogMessage template*,params&
		iterate P,params ; rever order on the stack
			if % = 1
				repeat %% and 1
					push 0 ; align stack
				end repeat
			end if
			indx %%-%+1
			push qword P
		end iterate
		mov r8, rsp ; argv pointer
		sub rsp, 8*6
		wvsprintfW & g_buffer, <W template>, r8
		xchg r8d, eax ; characters
		WriteConsoleW [hOutput], & g_buffer, r8d, 0, 0
		iterate P,params ; rever order on the stack
			add rsp, 8*(6 + %% + (%% and 1))
			break
		end iterate
	end macro

	macro ABISAFE_DebugLogMessage template*,params&
		push r9 r8 rdx rcx
		DebugLogMessage <template>,params
		pop rcx rdx r8 r9
	end macro

end if ; __SOURCE__ = __FILE__

else ; console debug support are NOPs

	macro debug_startup
	end macro

	macro DebugLogMessage template*,params&
	end macro

	macro ← line&
	end macro

	; Event logging support are NOPs:

	macro EnableRibbonControlLogging framework*,handle*
	end macro

	macro DisableRibbonControlLogging
	end macro

end if ; definite DEBUG & DEBUG
