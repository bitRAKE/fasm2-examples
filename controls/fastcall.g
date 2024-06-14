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

;macro frame?
;	local size
;	define fastcall?.frame_size size
;	fastcall?.frame =: 0
;	sub rsp,size
;end macro
;
;macro end?.frame?
;	match size, fastcall?.frame_size
;		size := fastcall?.frame
;		add rsp,size
;	end match
;	restore fastcall?.frame,fastcall?.frame_size
;end macro
;
;macro endf?
;	end frame
;end macro
;
;macro fastcall?.inline_string var
;	local data,continue
;	jmp continue
;	if sizeof.TCHAR > 1
;		align sizeof.TCHAR,90h
;	end if
;	match value, var
;		data TCHAR value,0
;	end match
;	redefine var data
;	continue:
;end macro


macro fastcall?: proc*,args&
	local offset,framesize,type,value
	if framesize & fastcall?.frame < 0
		sub rsp,framesize
	end if
	offset = 0
	local nest,called
	called = 0
	iterate arg, args
		nest = 0
		match =invoke? func, arg
			nest = %
		else match =fastcall? func, arg
			nest = %
		end match
		if nest
			if called
				mov [rsp+8*(called-1)],rax
			end if
			frame
				arg
			end frame
			called = nest
		end if
	end iterate
	iterate arg, args
		match =float? val, arg
			type = 'f'
			value reequ val
			SSE.parse_operand@src val
		else match =addr? val, arg
			type = 'a'
			value reequ val
			x86.parse_operand@src [val]
		else match =invoke? func, arg
			if called = %
				type = 0
				value reequ rax
				x86.parse_operand@src rax
			else
				type = 'r'
			end if
		else match =fastcall? func, arg
			if called = %
				type = 0
				value reequ rax
				x86.parse_operand@src rax
			else
				type = 'r'
			end if
		else match first=,rest, arg
			type = 's'
			value reequ arg
		else
			type = 0
			value reequ arg
			SSE.parse_operand@src arg
			if @src.type = 'imm' & @src.size = 0
				if value eqtype ''
					type = 's'
				end if
			end if
		end match
		if type = 's'
			fastcall.inline_string value
			type = 'a'
		end if
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
					if type = 'r'
						@src.size = 8
						@src.type = 'mem'
						value equ [rsp+8*(%-1)]
					end if
					if @src.size = 8 | ~ @src.size
						redefine target fastcall.r#%
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.r#%
							mov fastcall.r#%,value
						end if
					else if @src.size = 4
						redefine target fastcall.rd#%
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.rd#%
							mov fastcall.rd#%,value
						end if
					else if @src.size = 2
						redefine target fastcall.r#%
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.rw#%
							mov fastcall.rw#%,value
						end if
					else if @src.size = 1
						redefine target fastcall.rb#%
						if @src.type <> 'reg' | ~ @src.imm eq fastcall.rb#%
							mov fastcall.rb#%,value
						end if
					else
						err 'invalid argument ',`arg
					end if
				end if
			end if
		else
			if type = 'r'
				; already on stack
			else if @src.type = 'reg'
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
			else if @src.type = 'imm'
				if @src.size = 8 | ~ @src.size
					if (value) relativeto 0 & (value) - 1 shl 64 >= -80000000h & (value) < 1 shl 64
						mov rax,(value) - 1 shl 64
						mov [rsp+offset],rax
					else if (value) relativeto 0 & ( (value) >= 80000000h | (value) < -80000000h )
						mov rax,value
						mov [rsp+offset],rax
					else
						mov qword [rsp+offset],value
					end if
				else if @src.size = 4
					mov dword [rsp+offset],value
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
