#include <Constants.au3>
#RequireAdmin
;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win8
; Script Function:
;   Opens IncaXPCApp.exe, move mouse to specific position and simulate click to trigger the function.
;

HotKeySet("{ESC}", "stopCopTrax")
HotKeySet("^r", "testRecord")

; Prompt the user to run the script - use a Yes/No prompt with the flag parameter set at 4 (see the help file for more details)
Local $iAnswer = MsgBox(BitOR($MB_YESNO, $MB_SYSTEMMODAL), "Using AutoIt to test CopTrax", "This test will start CopTrax, simulate mouse movements and clicks to trigger the function.  Do you want to run it?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $iAnswer = 7 Then
	MsgBox($MB_SYSTEMMODAL, "CopTrax testing ends.", "OK.  Bye!")
	Exit
EndIf

Run("CopTrax.bat")
Sleep(2000)

Local $mClassName = "[CLASS:WindowsForms10.Window.208.app.0.182b0e9_r11_ad1]"
Local $mTitle = "CopTrax II v2.1.2.2 [testergs]"
$mTitle = "CopTrax Status"

WinActivate($mClassName)

If WinWaitClose($mTitle,5) = 0 Then
   MsgBox($MB_SYSTEMMODAL, "CopTrax Error","Devices are not ready")
EndIf

Global $mCopTrax = WinWaitActive($mClassName, "", 5)
; Retrieve the handle of the CopTrax window using the classname or Title.

Local $iAnswer = MsgBox(BitOR($MB_YESNO, $MB_SYSTEMMODAL), "CopTrax testing", "Gears are all ready." & @CRLF & "^r to test Record function." & @CRLF & "Esc to quit" )

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $iAnswer = 7 Then
   stopCopTrax()
   Exit
EndIf

While 1
WEnd

stopCopTrax()

; Finished!

Func stopCopTraxSAV()
   prepareTest()

   MsgBox($MB_OK,"CopTrax Tester", "Testing Ends",2)

   MouseClick("",960,560)	; click the Info button
   Sleep(400)

   Local $mTitle = "Menu Action"
   WinActivate($mTitle)
   Local $mHandle = WinWaitActive($mTitle,"",2)
   If  $mHandle = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the Info function in CopTrax. " & @CRLF & $mWinClassList,2)
	  Exit
   EndIf

   ControlClick($mHandle,"","WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad11",'left')	; click the title
   Sleep(100)

   ;MouseClick("",450,82)
   ;Sleep(200)
   ;MouseDown($MOUSE_CLICK_LEFT)

   ControlClick($mHandle,"","WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad11")
   AutoItSetOption("SendKeyDelay", 100)
   Send("{DOWN 8}{ENTER}")

   Sleep(100);
   MouseMove(450,250)
   MouseDown($MOUSE_CLICK_LEFT)
   Sleep(400)

   $mTitle = "Login"
   If  WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the Admin password input. " & @CRLF & $mWinClassList,2)
	  Exit
   EndIf

   Sleep(100);
   MouseClick($MOUSE_CLICK_LEFT,590,100)
   Sleep(100);
   Send("135799{ENTER}")

   ;ControlCommand($mTitle,"","WindowsForms10.EDIT.app.0.182b0e9_r11_ad11","135799{ENTER}")

EndFunc

Func stopCopTrax()
   prepareTest()

   MouseClick("",960,560)	; click on the info button
   Sleep(400)

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the Info button. " & @CRLF & $mHandle,2)
	  ConsoleWriteError("Click to info button failed at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)
	  Exit
   EndIf

   MouseClick("", 450, 80)	; click the About
   Sleep(100)
   Send("{DOWN 8}{ENTER}{TAB}{ENTER}")	; choose the Administrator

   Sleep(100)
   Local $mTitle = "Login"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the Login window. " & @CRLF & $mHandle,2)
	  ConsoleWriteError("Click to Login window failed at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)
	  Exit
   EndIf

   Send("135799{ENTER}")	; type the administator password
EndFunc

   ; Now select Admin by send DOWN key 10 times and then ENTER key

Func testRecord()
   prepareTest()

   Local $i;

   For $i=1 To 1000
	  testR($i)
   Next
EndFunc

Func testR($n)
   ConsoleWrite("Begin the test of record function. #" & $n & " at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)

   Local $mHandle = WinActivate($mCopTrax);

   If ControlClick($mCopTrax,"","WindowsForms10.Window.8.app.0.182b0e9_r11_ad14") = 0 Then
	  MsgBox($MB_OK,"Test elert", " Click on the main tool bar failed.",2)
	  ConsoleWriteError("Click to start record failed at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)
   EndIf

   Sleep(100)
   MouseClick("", 960, 80)	; click to start record

   Sleep(10000)	; Wait for 10sec for record begin recording
   If Not checkFile() Then	; check if the specified files appear or not
	  ConsoleWriteError("Recording failed to start at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)
	  Exit
   EndIf

   MouseClick("", 960, 80)	; click again to stop record

   Local $mTitle = "Report Taken"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the record function in CopTrax. " & @CRLF & $mHandle,2)
	  ConsoleWriteError("Click to stop record failed at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)
	  Exit
   EndIf

   Sleep(200)

   MouseClick("", 475,60)
   ControlFocus($mTitle,"",5114438)
   AutoItSetOption("SendKeyDelay", 100)
   Send("N")
   MouseClick($MOUSE_CLICK_LEFT, 475,60)
   Sleep(100)

   ; move the mouse to Operating User InputBox
   MouseClick($MOUSE_CLICK_LEFT, 475,130)
   Send("jj")
   MouseClick($MOUSE_CLICK_LEFT, 475,130)
   Sleep(100)

   ; move the mouse to Comments InputBox
   MouseClick($MOUSE_CLICK_LEFT, 475,250)
   ; AutoItSetOption("SendKeyDelay", 100)
   Send("This is a test input by CopTrax testing team.")
   Sleep(100)

   ;Click the OK button
   MouseClick("",500,330)
EndFunc

Func testSettings()
   Local $mTitle = "CopTrax II Setup"

   WinWaitActive($mTitle,"",10)
   MsgBox($MB_OK,"CopTrax Automate Testor", " Testing settings input..",2)
   Sleep(2000)

   WinSetOnTop($mTitle,"",$WINDOWS_ONTOP)
   WinSetState($mTitle,"",@SW_ENABLE)
   WinActivate($mTitle)

   ; Retrieve the classlist of the Notepad window using the handle returned by WinWait.
    Local $mClassList = WinGetClassList($mTitle)

    ; Display the classlist.
    ;MsgBox($MB_SYSTEMMODAL, "", $mClassList)

   ControlClick($mTitle,"",4065668)

   ;MouseClick($MOUSE_CLICK_LEFT, 900,470)
   Sleep(2000)

   ;MouseClick($MOUSE_CLICK_LEFT, 950,560)
   ControlClick($mTitle,"",2951158)
   Sleep(400)
EndFunc

Func prepareTest()
   WinClose("Login")
   WinClose("Menu Action")
   WinClose("Report Taken")

   WinSetOnTop($mCopTrax,"",$WINDOWS_ONTOP)
   WinSetState($mCopTrax,"",@SW_ENABLE)
   WinActivate($mCopTrax)
   ControlFocus($mCopTrax, "", "[CLASS:WindowsForms10.Window.8.app.0.182b0e9_r11_ad1; INSTANCE:4]")
   Sleep(100)

   Local $mTitle = WinGetTitle("[ACTIVE]")

   If Not ($mTitle == "CopTrax II v2.1.2.2 [testergs]") Then
	  MsgBox($MB_SYSTEMMODAL, "CopTrax Testing Error","Current active window ontop is " & $mTitle)
   EndIf

    If ControlClick($mCopTrax, "", "[CLASS:WindowsForms10.Window.8.app.0.182b0e9_r11_ad1; INSTANCE:4]") = 0 Then
	  MsgBox($MB_SYSTEMMODAL, "CopTrax Testing Error","Current active window ontop is " & $mTitle)
   EndIf

   MouseMove(960,200)
   ControlEnable($mCopTrax,"","WindowsForms10.Window.8.app.0.182b0e9_r11_ad14")
   Sleep(100)
EndFunc
