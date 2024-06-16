; http://msdn.microsoft.com/en-us/library/bb775740.aspx
include '..\windows.g'
include '..\controls.h'

public ComboBoxExDlgProc
:ComboBoxExDlgProc:
	virtual at rbp - .local
		.cbei		COMBOBOXEXITEMW
				align.assume rbp,16
				align 16
		.local := $ - $$
				rq 2 ; old RBP and return
		.hDialog	dq ?
		.hComboEx	dq ?
		.hImageList	dq ?
	end virtual
	enter .frame + .local, 0
	mov [.hDialog], rcx

	cmp edx, WM_CLOSE
	jnz @F
	GetWindowLongPtrW rcx, GWLP_USERDATA ; hImageList
	ImageList_Destroy rax
	EndDialog [.hDialog], 0
	jmp @0F

@@:	cmp edx, WM_INITDIALOG
	jnz @0F
	SetWindowTextW rcx, r9 ; parent has given name

	; Load and register ComboBoxEx control class.
{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_USEREX_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @0F

	; Create the ComboBoxEx control.
	CreateWindowExW 0, W "ComboBoxEx32", 0, WS_CHILD or WS_VISIBLE or CBS_DROPDOWN,\
		20, 20, 280, 100, [.hDialog], IDC_COMBOBOXEX, __ImageBase, 0
	test rax, rax ; hComboEx
	jz @0F
	mov [.hComboEx], rax

	; Create an image list to hold icons for use by the ComboBoxEx control.
	ImageList_Create 16, 16, ILC_MASK or ILC_COLOR32, .nIconCount, 0
	test rax, rax
	jz @0F
	mov [.hImageList], rax
	SetWindowLongPtrW [.hDialog], GWLP_USERDATA, [.hImageList]

	iterate icon_id, IDI_APPLICATION,IDI_INFORMATION,IDI_QUESTION,IDI_EXCLAMATION,IDI_ASTERISK,IDI_WINLOGO,IDI_SHIELD
		if % = 1
			.nIconCount := %%
		end if
		LoadImageW 0, dword icon_id, IMAGE_ICON, 0, 0, LR_SHARED
		test rax, rax
		jz .%
		ImageList_AddIcon [.hImageList], rax
	.%:
	end iterate

	; Associate the image list with the ComboBoxEx common control
	SendMessageW [.hComboEx], CBEM_SETIMAGELIST, 0, [.hImageList]

	; Add nIconCount items to the ComboBoxEx common control
	mov [.cbei.mask], CBEIF_IMAGE or CBEIF_TEXT or CBEIF_SELECTEDIMAGE
	mov [.cbei.iItem], -1 ; append items to end
	repeat .nIconCount
{const:2} .%.txt du 'Item ',`%,0
		mov [.cbei.pszText], .%.txt
		mov [.cbei.iImage], %-1
		mov [.cbei.iSelectedImage], %-1
		SendMessageW [.hComboEx], CBEM_INSERTITEMW, 0, addr .cbei
	end repeat
@0:	xor eax, eax
	leave
	retn
