fasm2 = c:\fasm2\fasm2.cmd

.SUFFIXES : .asm.obj

.asm.obj :
	$(fasm2) -e 5 $<


# LNK4281: triggers incorrectly, ASLR is not active for FIXED!

random.exe : random.obj \
	extrn\pcg32.obj \
	extrn\u32.obj
	link /IGNORE:4281 /FIXED $**

random.obj : consoleApp.g wincon.g \
	extrn\pcg32.asm \
	extrn\u32.asm


.SILENT :

clean :
	del /S /Q *.obj 2>NUL
	del /Q *.exe 2>NUL
	del /Q *.zip 2>NUL
