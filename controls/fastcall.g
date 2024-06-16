define fastcall? fastcall

fastcall.r1 equ rcx
fastcall.rd1 equ ecx
fastcall.rw1 equ cx
fastcall.rb1 equ cl
fastcall.rf1 equ xmm0

fastcall.r2 equ rdx
fastcall.rd2 equ edx
fastcall.rw2 equ dx
fastcall.rb2 equ dl
fastcall.rf2 equ xmm1

fastcall.r3 equ r8
fastcall.rd3 equ r8d
fastcall.rw3 equ r8w
fastcall.rb3 equ r8b
fastcall.rf3 equ xmm2

fastcall.r4 equ r9
fastcall.rd4 equ r9d
fastcall.rw4 equ r9w
fastcall.rb4 equ r9b
fastcall.rf4 equ xmm3

fastcall?.frame = -1

macro fastcall?.inline_string type,var
	local data
	if type = 2 ; WIDE
		match value, var
			COFF.2.CONST data du value,0
		end match
		redefine var data
	else if type = 1 ; ANSI/UTF8
		match value, var
			COFF.1.CONST data db value,0
		end match
		redefine var data
	else if type = -1 ; BSTR
		err 'not implemented'
;			match value, var
;				COFF.1.CONST data db value,0
;			end match
;			redefine var data
	else if type = 0 ; raw statements
		match value, var
			COFF.1.CONST data value
		end match
		redefine var data
	else
		err 'unknown string type'
	end if
end macro

; TODO: the optimization should be in the MOV instruction. Global optimization
; flags are needed to track how much machine state can be disregarded.
;	+ flags can be modified
;	+ lower stack can be modified
;	+ ABI volatile registers can be modified
;	+ etc.

macro fastcall? proc*,args&
	local offset,framesize,type,value,target
	if framesize & fastcall?.frame < 0
		sub rsp,framesize
	end if
	offset = 0
	iterate arg, args
		match =float? val, arg
			type = 'f'
			value reequ val
			SSE.parse_operand@src val
		else match =addr? val, arg
			type = 'a'
			value reequ val
			x86.parse_operand@src [val]
		else match =&val, arg
			type = 'a'
			value reequ val
			x86.parse_operand@src [val]
		else match first=,rest, arg ; group <>
			type = 'a'
			value reequ arg
			fastcall.inline_string 0,value
		else match =A rest, arg ; ANSI
			type = 'a'
			value reequ rest
			fastcall.inline_string 1,value
		else match =B rest, arg ; BSTR
			type = 'a'
			value reequ rest
			fastcall.inline_string -1,value
		else match =W rest, arg ; WIDE
			type = 'a'
			value reequ rest
			fastcall.inline_string 2,value
		else
			type = 0
			value reequ arg
			SSE.parse_operand@src arg
			if @src.type = 'imm' & @src.size = 0
				if value eqtype ''
					err 'no default string type, use string prefix'
				end if
			end if
		end match
;------------------------------------------------------------------------------
		if % < 5
			if type = 'f'
				if @src.size = 8 | ~ @src.size | @src.type = 'mmreg'
					if @src.type = 'imm'
						mov rax,value
						movq fastcall.rf#%,rax
					else
						movq fastcall.rf#%,value
					end if
				else if @src.size = 4
					if @src.type = 'imm'
						mov eax,value
						movd fastcall.rf#%,eax
					else
						movd fastcall.rf#%,value
					end if
				else
					err 'invalid argument ',`arg
				end if
			else
				if type = 'a'
					lea fastcall.r#%,[value]
				else
					if @src.size = 8 | ~ @src.size
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.r#%
if @src.type = 'imm' & (@src.imm) relativeto 0
	if 0 = @src.imm
		xor fastcall.rd#%,fastcall.rd#%
	else if -129 < (@src.imm) & (@src.imm) < 128
		push value
		pop fastcall.r#%
	else
		mov fastcall.r#%, value
	end if
else
	mov fastcall.r#%,value
end if
						end if
					else if @src.size = 4
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.rd#%
if @src.type = 'imm' & (@src.imm) relativeto 0
	if 0 = @src.imm
		xor fastcall.rd#%,fastcall.rd#%
	else if -129 < (@src.imm) & (@src.imm) < 128
		push value
		pop fastcall.r#%
	else
		mov fastcall.rd#%,value
	end if
else
	mov fastcall.rd#%,value
end if
							mov fastcall.rd#%,value
						end if
					else if @src.size = 2
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.rw#%
							mov fastcall.rw#%,value
						end if
					else if @src.size = 1
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.rb#%
							mov fastcall.rb#%,value
						end if
					else
						err 'invalid argument ',`arg
					end if
				end if
			end if
		else ;------------------------------------------------memory destinations:
			if @src.type = 'reg'
				mov [rsp+offset],value
			else if @src.type = 'mem'
				if type = 'a'
					lea rax,[value]
					mov [rsp+offset],rax
				else
					if @src.size = 8 | ~ @src.size
						mov rax,value
						mov [rsp+offset],rax
					else if @src.size = 4
						mov eax,value
						mov [rsp+offset],eax
					else if @src.size = 2
						mov ax,value
						mov [rsp+offset],ax
					else if @src.size = 1
						mov al,value
						mov [rsp+offset],al
					else
						err 'invalid argument ',`arg
					end if
				end if
; optimize for size
			else if @src.type = 'imm'
				if @src.size = 8 | ~ @src.size
if (value) relativeto 0
	if 0 = value
		and qword [rsp+offset],0
	else if -1 = value | 0xFFFF_FFFF_FFFF_FFFF = value
		or qword [rsp+offset],-1
	else if -129 < (value) & (value) < 128
		push value
		pop [rsp+offset]
	else if -0x8000_0001 < (value) & (value) < 0x8000_0000
		mov qword [rsp+offset], value
	else if (value)shr 64 = 0 | (value)shr 64 = -1
		mov rax,(value) and 0xFFFF_FFFF_FFFF_FFFF
		mov [rsp+offset],rax
	end if
else
	mov qword [rsp+offset],value
end if
				else if @src.size = 4
if (value) relativeto 0
	if 0 = value
		and dword [rsp+offset],0
	else if -1 = value | 0xFFFF_FFFF = value
		or dword [rsp+offset],-1
	else if -129 < (value) & (value) < 128
		push value
		pop [rsp+offset]
	else if (value)shr 32 = 0 | (value)shr 32 = -1
		mov [rsp+offset],value
	end if
else
	mov dword [rsp+offset],value
end if
				else if @src.size = 2
					mov word [rsp+offset],value
				else if @src.size = 1
					mov byte [rsp+offset],value
				else
					err 'invalid argument ',`arg
				end if
			else if type = 'f' & @src.type = 'mmreg' & @src.size = 16
				movq [rsp+offset],value
			else
				err 'invalid argument ',`arg
			end if
		end if
		offset = offset + 8
	end iterate
	pcountcheck proc,offset/8
	if offset < 20h
		offset = 20h
	end if
	framesize = offset + offset and 8
	call proc
	if framesize & fastcall?.frame < 0
		add rsp,framesize
	else if fastcall?.frame >= 0 & framesize > fastcall?.frame
		fastcall?.frame = framesize
	end if
end macro

macro pcountcheck? proc*,args*
end macro

define pcountsuffix %
