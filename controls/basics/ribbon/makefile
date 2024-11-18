FASM2 = Y:\_base\bin\fasm2.cmd
UICC = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86\uicc.exe"

.SUFFIXES : .asm.obj

.asm.obj :
	$(FASM2) -e 5 -i "DEBUG:=1" $<
	@if not exist $(<:.asm=.obj) exit 1


all : dbg_all.exe tidy


# change string resource reference (APPLICATION_RIBBON) into a number (1)
dbg_all.bin : dbg_all.xml
	$(UICC) dbg_all.xml dbg_all.bin /header:dbg_all.h /res:dbg_all.rc
	@if exist dbg_all.h echo #define APPLICATION_RIBBON 1 >>dbg_all.h

dbg_all.res : dbg_all.bin dbg_all.rc dbg_all.h


dbg_all.exe : dbg_all.res dbg_all.obj	\
	debug.obj			\
	_wait_for_key.obj		\
	impl_X_IUnknown.obj		\
	impl_Xd_IUIApplication.obj	\
	impl_Xd_IUICommandHandler.obj	\
	impl_X_IUIEventLogger.obj
	link @$*.response "/SUBSYSTEM:CONSOLE,6.02" $**

dbg_all.response : dbg_all.obj



.SILENT :

# tidy, leaves the end products
# clean, removes anything generated
# package, archives non-generated

tidy :
	del dbg_all.h dbg_all.rc dbg_all.bin
	del /S /Q *.response *.res *.obj >NUL 2>&1

clean : tidy
	del /S /Q *.exp *.lib *.dll *.exe *.zip >NUL 2>&1

package : clean
	tar -a -cf main.zip --exclude=main.zip *

# insure non-file targets don't conflict
.PHONY: tidy clean package
