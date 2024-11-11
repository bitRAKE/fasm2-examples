FASM2 = Y:\_base\bin\fasm2.cmd
UICC = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86\uicc.exe"

.SUFFIXES : .asm.obj

.asm.obj :
	$(FASM2) -e 5 $<
	@if not exist $(<:.asm=.obj) exit 1


all : app.exe tidy

# Sufficient dependencies to allow efficient build on project changes. Order
# is important to reducing verbosity. For example, building the resource first
# chains to all resource products - compiliing the ribbon:
#	app.exe -> app.res -> [app.rc] ->
#	ribbon.rc -> ribbon.h -> ribbon.bin -> [app.ribbon]
#
# TODO: All the resource images should be included.

ribbon.bin : app.ribbon
	$(UICC) app.ribbon ribbon.bin /header:ribbon.h /res:ribbon.rc

ribbon.h : ribbon.bin
ribbon.rc : ribbon.h


app.exe : app.res app.obj \
	impl_IUIApplication.obj \
	impl_IUICommandHandler.obj \
	impl_IUIEventLogger.obj
	link @$*.response $**

app.response : app.obj
app.obj : base.asm
app.rc : ribbon.rc



.SILENT :

tidy :
	del /S /Q ribbon.* >NUL 2>&1

clean : tidy
	del /S /Q *.response *.res *.obj *.exp *.lib *.dll *.exe *.zip >NUL 2>&1

package : clean
	tar -a -cf main.zip --exclude=main.zip *
