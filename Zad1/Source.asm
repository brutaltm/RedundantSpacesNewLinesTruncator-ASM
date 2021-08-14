.386
.MODEL FLAT, STDCALL

STD_INPUT_HANDLE	equ -10
STD_OUTPUT_HANDLE	equ -11
GENERIC_READ		equ 80000000h
GENERIC_WRITE		equ 40000000h
CREATE_NEW			equ 1
CREATE_ALWAYS		equ 2
OPEN_EXISTING       equ 3
OPEN_ALWAYS			equ 4
TRUNCATE_EXISTING	equ 5
FILE_BEGIN			equ 0h 
FILE_CURRENT        equ 1h 
FILE_END            equ 2h 

lstrcatA PROTO :DWORD,:DWORD
StdOut PROTO :DWORD
StdIn PROTO :DWORD,:DWORD
;wsprintfA PROTO C :VARARG

GetCurrentDirectoryA PROTO :DWORD,:DWORD
CreateFileA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ReadFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DeleteFileA PROTO :DWORD
MoveFileA PROTO :DWORD,:DWORD
GetFileSize PROTO :DWORD,:DWORD
CloseHandle PROTO :DWORD

SetDlgItemTextA		PROTO :DWORD,:DWORD, :DWORD
SetDlgItemInt		PROTO :DWORD,:DWORD, :DWORD, :DWORD
SendDlgItemMessageA	PROTO :DWORD,:DWORD, :DWORD, :DWORD, :DWORD
GetLastError PROTO
ExitProcess PROTO :DWORD

includelib .\masm32.lib
include grafika.inc

.DATA

	hinst	DWORD	0
	hicon	DWORD	0
	hcur 	DWORD	0
	hmenu	DWORD	0

	Bufor BYTE 255 dup(?),0
	WczytanoPomyslnie BYTE "Plik wczytano pomyœlnie",0
	Error2 BYTE "ERROR_FILE_NOT_FOUND - Nie znaleziono pliku w podanej lokalizacji",0Dh,0Ah,0
	ErrorDostepu BYTE "Wystapil problem z dostepem do pliku/katalogu",0Dh,0Ah,0
	niePoprawneZnaki BYTE "Wprowadzono niepoprawne kody ASCII",0
	zakonczonoPowodzeniem BYTE "Proces usuwania powtarzaj¹cych siê znaków zakoñczony.",0
	rozmiarZrodlowegoSzablon BYTE "Rozmiar pliku Ÿród³owego: %iB",0
	rozmiarDocelowegoSzablon BYTE "Rozmiar pliku docelowego: %iB",0
	usunieteZnakiSzablon BYTE "Usuniêto %i znaków",0
	tdlg1	BYTE "DLG1",0
	sciezka BYTE 255 dup(?),0
	sciezkaTemp BYTE 255 dup(?),0
	sciezkaUzytkownika BYTE 255 dup(?),0
	pliktymczasowy BYTE "\temp.txt",0
	A32 BYTE "32",0
	A09 BYTE "09",0
	liczbaA BYTE 10 dup(0)
	Znak1 BYTE 0
	Znak2 BYTE 0
	czyOK BYTE 0

	empty BYTE 0
	poprzedni BYTE ?
	aktualny BYTE ?

	sciezkaLength DWORD 256
	tmenu	BYTE "MENU1",0
	tOK		BYTE "OK",0
	terr 	BYTE 32 dup(0)	; bufor komunikatu
	tnagl	BYTE 32 dup(0)	; bufor nag³ówka
	buffor	BYTE 32 dup(0)
	fileHandle DWORD 0
	fileHandleTemp DWORD 0
	rout DWORD 0
	rout2 DWORD 0
	licznik DWORD 0

.CODE

WndProc PROC uses EBX ESI EDI windowHandle:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

	.IF uMSG ==  WM_INITDIALOG
		jmp	wmINITDIALOG
	.ENDIF

	.IF uMSG ==  WM_CLOSE
		jmp	wmCLOSE
	.ENDIF

	.IF uMSG ==  WM_COMMAND
		jmp	wmCOMMAND
	.ENDIF

	.IF uMSG ==  WM_MOUSEMOVE
		jmp	wmMOUSEMOVE
	.ENDIF

	 mov	EAX, 0
	 jmp	konWNDPROC 

	wmINITDIALOG:

		INVOKE LoadIcon, hinst,11         
		mov hicon, EAX                     

		INVOKE SendMessageA , windowHandle , WM_SETICON , ICON_SMALL , hicon

		INVOKE LoadCursorA,hinst,12
		mov hcur,EAX

		INVOKE LoadMenu,hinst,OFFSET tmenu
		mov hmenu,EAX
		INVOKE SetMenu, windowHandle, hmenu 

		INVOKE LoadString, hinst,1,OFFSET buffor,32 


		
		INVOKE GetCurrentDirectoryA, sciezkaLength,ADDR sciezkaTemp
		INVOKE lstrcatA, ADDR sciezkaTemp,ADDR pliktymczasowy
		INVOKE GetCurrentDirectoryA, sciezkaLength,ADDR sciezka
		MOV sciezkaLength,EAX
		INVOKE SetDlgItemTextA, windowHandle, 1, offset sciezka	

		mov EAX, 1
		jmp	konWNDPROC 

	wmCLOSE:
		INVOKE DestroyMenu,hmenu
		INVOKE EndDialog, windowHandle, 0	
		 
		 mov EAX, 1
		jmp	konWNDPROC

	wmCOMMAND: 
		.IF wParam ==  3 ;identyfikator kliknietego elementu nadany mu w pliku zasobow tutaj to button "START"
		    INVOKE SendDlgItemMessageA , windowHandle , 1 , WM_GETTEXT , 255 , offset sciezkaUzytkownika
			MOV EBX,OFFSET sciezkaUzytkownika
			MOV czyOK,0

			INVOKE SetDlgItemTextA, windowHandle, 4, offset empty	
			INVOKE SetDlgItemTextA, windowHandle, 8, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 11, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 12, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 13, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 14, offset empty
			.IF fileHandle!=0
				INVOKE CloseHandle, fileHandle
			.ENDIF
			INVOKE CreateFileA, ADDR sciezkaUzytkownika,GENERIC_READ,0,0,OPEN_EXISTING,0,0
			MOV fileHandle,EAX
			CALL GetLastError
			.IF EAX==2
				INVOKE SetDlgItemTextA, windowHandle, 4, ADDR Error2
				MOV fileHandle,0
			.ELSEIF EAX>2
				INVOKE SetDlgItemTextA, windowHandle, 4, ADDR errorDostepu
				MOV fileHandle,0
			.ELSE
				INC czyOK
				INVOKE SetDlgItemTextA, windowHandle, 4, ADDR wczytanoPomyslnie
				INVOKE GetFileSize, fileHandle,0
				INVOKE wsprintfA, ADDR Bufor,ADDR rozmiarZrodlowegoSzablon,EAX
				INVOKE SetDlgItemTextA, windowHandle, 11, ADDR Bufor
			.ENDIF

			mov EAX, 1
			jmp	konWNDPROC
		.ENDIF

		.IF wParam == 9 
			.IF czyOK != 0 
				INVOKE SendDlgItemMessageA , windowHandle , 6 , WM_GETTEXT , 4 , offset liczbaA
				PUSH OFFSET liczbaA
				CALL atoi
				MOV Znak1,AL
				INVOKE SendDlgItemMessageA , windowHandle , 7 , WM_GETTEXT , 4 , offset liczbaA
				PUSH OFFSET liczbaA
				CALL atoi
				MOV Znak2,AL
				

				.IF znak1>=0 && znak1<128 && znak2>=0 && znak2<128
					INVOKE SetDlgItemTextA, windowHandle, 14, offset empty
					INVOKE CreateFileA, ADDR sciezkaTemp,GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
					MOV fileHandleTemp,EAX
					INVOKE ReadFile, fileHandle,ADDR poprzedni,1,ADDR rout,0
					INVOKE WriteFile, fileHandleTemp,ADDR poprzedni,1,ADDR rout2,0
					MOV AL,poprzedni
					MOV licznik,0
					.WHILE rout!=0
	
						INVOKE ReadFile, fileHandle,ADDR aktualny,1,ADDR rout,0
						MOV AL,aktualny
						.IF rout==0
							.BREAK
						.ENDIF

						.IF AL==znak2 || AL==znak1
							.IF AL!=poprzedni
								MOV poprzedni,AL
								INVOKE WriteFile, fileHandleTemp,ADDR aktualny,1,ADDR rout2,0
							.ELSE
								INC licznik
							.ENDIF
						.ELSEIF AL==0Dh
							.IF poprzedni==0Ah
								INVOKE ReadFile, fileHandle,ADDR aktualny,1,ADDR rout,0
								.IF aktualny!=0Ah
									MOV AL,aktualny
									MOV poprzedni,AL
									INVOKE WriteFile, fileHandleTemp,ADDR aktualny,1,ADDR rout2,0
								.ELSE
									INC licznik
									INC licznik
								.ENDIF
							.ELSE
								MOV poprzedni,AL
								INVOKE WriteFile, fileHandleTemp,ADDR aktualny,1,ADDR rout2,0
							.ENDIF
						.ELSEIF AL==0Ah
							.IF poprzedni!=0Ah
								MOV poprzedni,AL
								INVOKE WriteFile, fileHandleTemp,ADDR aktualny,1,ADDR rout2,0
							.ELSE
								INC licznik
							.ENDIF
						.ELSE
							MOV poprzedni,AL
							INVOKE WriteFile, fileHandleTemp,ADDR aktualny,1,ADDR rout2,0
						.ENDIF
					.ENDW
					INVOKE CloseHandle, fileHandle
					MOV fileHandle,0
					MOV czyOK,0
					INVOKE SetDlgItemTextA, windowHandle, 4, offset empty	

					INVOKE GetFileSize, fileHandleTemp,0
					INVOKE wsprintfA, ADDR bufor,ADDR rozmiarDocelowegoSzablon,EAX
					INVOKE SetDlgItemTextA, windowHandle, 12, offset bufor
					INVOKE CloseHandle, fileHandleTemp

					INVOKE DeleteFileA, ADDR sciezkaUzytkownika
					INVOKE MoveFileA, ADDR sciezkaTemp,ADDR sciezkaUzytkownika

					INVOKE wsprintfA, ADDR bufor,ADDR usunieteZnakiSzablon,licznik
					INVOKE SetDlgItemTextA, windowHandle, 13, offset bufor
					INVOKE SetDlgItemTextA, windowHandle, 8, offset zakonczonoPowodzeniem
				.ELSE
					INVOKE SetDlgItemTextA, windowHandle, 14, offset niePoprawneZnaki
				.ENDIF

			.ENDIF
			mov EAX, 1
			jmp	konWNDPROC
		.ENDIF

		.IF wParam ==  101 ;identyfikator kliknietego elementu nadany mu w pliku zasobow tutaj to button "START"
			INVOKE DestroyMenu , hmenu ; uchwyt menu
			INVOKE EndDialog , windowHandle , 0 ; uchwyt okna dialogowego
			;( pierwszy parametr WNDPROC )

			mov EAX, 1
			jmp	konWNDPROC
		.ENDIF
		
		.IF wParam ==  104 ;identyfikator kliknietego elementu nadany mu w pliku zasobow tutaj to button "START"
			INVOKE LoadString, hinst,3,OFFSET buffor,32 

			.IF fileHandle!=0
				INVOKE CloseHandle, fileHandle
			.ENDIF
			MOV fileHandle,0
			INVOKE SetDlgItemTextA, windowHandle, 4, offset empty	
			INVOKE SetDlgItemTextA, windowHandle, 1, offset sciezka	
			INVOKE SetDlgItemTextA, windowHandle, 6, offset A32
			INVOKE SetDlgItemTextA, windowHandle, 7, offset A09
			INVOKE SetDlgItemTextA, windowHandle, 8, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 11, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 12, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 13, offset empty
			INVOKE SetDlgItemTextA, windowHandle, 14, offset empty

			mov EAX, 1
			jmp	konWNDPROC
		.ENDIF


		
	wmMOUSEMOVE:
		INVOKE SetCursor,hcur
		
		mov EAX, 1
		jmp	konWNDPROC


	konWNDPROC:	
		ret

WndProc	ENDP


main PROC

	INVOKE GetModuleHandleA, 0
	mov	hinst, EAX
	
	INVOKE DialogBoxParamA, hinst,OFFSET tdlg1, 0, OFFSET WndProc, 0
	;tworzenie okna dialogowego
	.IF EAX == 0
			jmp	etkon
	.ENDIF

	.IF EAX == -1
		jmp	err0
	.ENDIF	

	

	err0:
		INVOKE LoadString, hinst,2,OFFSET terr,32
		INVOKE MessageBoxA,0,OFFSET terr,OFFSET tnagl,0

	etkon:

	INVOKE ExitProcess, 0

main ENDP

atoi proc uses esi edx inputBuffAddr:DWORD
	mov esi, inputBuffAddr
	xor edx, edx
	xor EAX, EAX
	mov AL, BYTE PTR [esi]
	cmp eax, 2dh
	je parseNegative

	.Repeat
		lodsb
		.Break .if !eax
		imul edx, edx, 10
		sub eax, "0"
		add edx, eax
	.Until 0
	mov EAX, EDX
	jmp endatoi

	parseNegative:
	inc esi
	.Repeat
		lodsb
		.Break .if !eax
		imul edx, edx, 10
		sub eax, "0"
		add edx, eax
	.Until 0

	xor EAX,EAX
	sub EAX, EDX
	jmp endatoi

	endatoi:
	ret
atoi endp


END
