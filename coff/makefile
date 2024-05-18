fasm2 = c:\fasm2\fasm2.cmd

.SUFFIXES : .asm.obj

.asm.obj :
	$(fasm2) -e 5 $<


# LNK4281: triggers incorrectly, ASLR is not active for FIXED!

all : random.exe gdi_pts.exe gdi_gfx.exe

random.exe : random.obj \
	extrn\prng\pcg32.obj \
	extrn\u32.obj
	link /IGNORE:4281 /FIXED $**

random.obj : AppConsole.g wincon.g


gdi_pts.obj gdi_gfx.obj : AppWindow.g


gdi_pts.exe : gdi_pts.obj
	link @gdi_pts.response $**

gdi_pts.response : gdi_pts.obj


gdi_gfx.exe : gdi_gfx.obj
	link @gdi_gfx.response $**

gdi_gfx.response : gdi_gfx.obj




gfx_dx12.exe : gfx_dx12.obj
	link @gfx_dx12.response $**

gfx_vk.exe : gfx_vk.obj
	link /IGNORE:4281 /FIXED $**

gfx_checker.exe : gfx_checker.obj
	link /IGNORE:4281 /FIXED $**



.SILENT :

clean :
	del /S /Q *.obj >NUL 2>&1
	del /Q *.response 2>NUL
	del /Q *.exe 2>NUL
	del /Q *.zip 2>NUL
