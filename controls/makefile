# NMAKE makefile
# see https://learn.microsoft.com/en-us/cpp/build/reference/nmake-reference

# set environment
fasm2 = c:\fasm2\fasm2.cmd

# restrict inference-rule matching (i.e. ignore most default rules)
.SUFFIXES : .asm.rc.res.obj

# specify timestamp dependent inference rules
.asm.obj :
	$(fasm2) -e 5 $<


DIALOGS = \
basics\AnimationDlg.obj \
basics\ComboBoxExDlg.obj \
basics\DateTimePickDlg.obj \
basics\HeaderDlg.obj \
basics\IPAddressDlg.obj \
basics\ListviewDlg.obj \
basics\MonthCalDlg.obj \
basics\ProgressDlg.obj \
basics\RebarDlg.obj \
basics\StatusbarDlg.obj \
basics\SysLinkDlg.obj \
basics\TabControlDlg.obj \
basics\ToolbarDlg.obj \
basics\TooltipDlg.obj \
basics\TrackbarDlg.obj \
basics\TreeviewDlg.obj \
basics\UpdownDlg.obj

RESOURCES = \
resources\upload.avi \
resources\manifest.xml \
resources\favicon.ico \
version.h


# LNK4281: triggers incorrectly, ASLR is not active for FIXED!

all : controls.exe

controls.exe : controls.obj controls.res $(DIALOGS)
	link @controls.response $**

controls.response : controls.obj
controls.obj : windows.g controls.h version.h
controls.res : controls.h version.h $(RESOURCES)

$(DIALOGS) : windows.g controls.h


.SILENT :

# rc.exe drops random temp files on error, like RCa10512
# executables in subdirectories are preserved to support alt build utilities
clean :
	del /S /Q *.obj >NUL 2>&1
	del /S /Q *.res >NUL 2>&1
	del /S /Q RCa*. >NUL 2>&1
	del /S /Q *.response >NUL 2>&1
	del /Q *.exe >NUL 2>&1
	del /Q *.zip >NUL 2>&1

package : clean
	tar -a -cf controls.zip --exclude=controls.zip *
