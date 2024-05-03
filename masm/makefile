# NMAKE makefile
# see https://learn.microsoft.com/en-us/cpp/build/reference/nmake-reference

# set environment
fasm2 = c:\fasm2\fasm2.cmd

# restrict inference-rule matching (i.e. ignore most default rules)
.SUFFIXES : .asm.rc.res

# specify timestamp dependent inference rules
.asm.exe :
	$(fasm2) -e 5 $<


main.exe : main.asm main.res


.SILENT :

clean :
	del /Q *.res 2>NUL
	del /Q *.exe 2>NUL
	del /Q *.zip 2>NUL

package : clean
	tar -a -cf main.zip *
