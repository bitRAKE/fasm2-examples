fasm2 = c:\fasm2\fasm2.cmd

.SUFFIXES : .asm.obj

.asm.obj :
	$(fasm2) -e 5 $<

DlgFade.exe : DlgFade.obj
	link @DlgFade.response $**

DlgFade.obj : AppWindow.g

DlgFade.response : DlgFade.obj
