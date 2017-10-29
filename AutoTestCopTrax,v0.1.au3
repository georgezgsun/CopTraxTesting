#include <Constants.au3>

;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win9x/NT
; Script Function:
;   Opens IncaXPCApp.exe, move mouse to specific position and simulate click to trigger the function.
;

; Prompt the user to run the script - use a Yes/No prompt with the flag parameter set at 4 (see the help file for more details)
Local $iAnswer = MsgBox(BitOR($MB_YESNO, $MB_SYSTEMMODAL), "Using AutoIt to test CopTrax", "This test will start CopTrax, simulate mouse movements and clicks to trigger the function.  Do you want to run it?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $iAnswer = 7 Then
	MsgBox($MB_SYSTEMMODAL, "CopTrax testing ends.", "OK.  Bye!")
	Exit
EndIf

; Run Notepad
Run("CopTrax.bat")
Sleep(2000)

Local $mClassName = "[CLASS:WindowsForms10.Window.208.app.0.182b0e9_r11_ad1]"
Local $mTitle = "CopTrax II v2.1.2 [testergs]"
$mTitle = WinGetTitle("[ACTIVE]")

; Wait for the CopTrax to become active. The classname "WindowsForms10.Window.208.app.0.182b0e9_r11_ad1" is monitored instead of the window title
Local $mCopTrax = WinWaitActive($mTitle, "", 5)
; Retrieve the handle of the CopTrax window using the classname or Title.

If @error Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the main window handle of CopTrax.")
   StopCopTrax()
   Exit
EndIf

;Sleep(1000)
;stopCopTrax()
;Exit

; Get the handle of the CopTrax window.
Local $mPos = WinGetPos("[ACTIVE]")
; MsgBox($MB_SYSTEMMODAL,"Current Window orin is now at ", "(" & $mPos[0] & ", " & $mPos[1] & ").")

; Wait for the CopTrax to become active. The window title "CopTrax II v.2.1.2 [testergs]"



Local $iAnswer = MsgBox(BitOR($MB_YESNO, $MB_SYSTEMMODAL), "Using AutoIt to test CopTrax", "Now testing Reord function.  Do you want to run it?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $iAnswer = 7 Then
   stopCopTrax()
   Exit
EndIf

Local $i
For $i = 1 To 5 Step 1
   testRecord($i)
Next

stopCopTrax()
Exit

; Finished!

Func stopCopTrax()
   WinSetOnTop($mCopTrax,"",$WINDOWS_ONTOP)
   WinSetState($mCopTrax,"",@SW_ENABLE)

   $mTitle = WinGetTitle("[ACTIVE]")
   Sleep(1000)

   MouseMove(960,560)
   MouseClick($MOUSE_CLICK_LEFT,500,160)
   Sleep(100)
   MouseClick($MOUSE_CLICK_LEFT,960,560)
   Sleep(100)


   ; Menu Action
   ; WindowsForms10.Window.8.app.0.182b0e9_r11_ad1
   ; WindowsForms10.BUTTON.app.0.182b0e9_r11_ad1
   ; ID 4261668

   ;ControlClick($mHandle,"","WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad11",'left')	; click the title
   Sleep(100);
   MouseClick($MOUSE_CLICK_LEFT,960,560)
   Local $mPos = MouseGetPos();
   MsgBox($MB_OK,"CopTrax Autotester", "Testing Admin action",2)
  ; MsgBox($MB_SYSTEMMODAL,"Current mouse is now at ", "(" & $mPos[0] & ", " & $mPos[1] & ").")

   $mTitle = "Menu Action"
   WinWaitActive($mTitle,"",10)
   MsgBox($MB_OK,"CopTrax Tester", "Admin action testing... to terminate the gear",2)

   WinSetOnTop($mTitle,"",$WINDOWS_ONTOP)
   WinSetState($mTitle,"",@SW_ENABLE)
   Sleep(100);
   MouseClick($MOUSE_CLICK_LEFT,450,82,2)
   Sleep(200)
   MouseDown($MOUSE_CLICK_LEFT)

   ;ControlCommand($mHandle,"","WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad11","ShowDropDown")
   AutoItSetOption("SendKeyDelay", 100)
   Send("AA")

   Sleep(100);
   MouseMove(450,250)
   MouseDown($MOUSE_CLICK_LEFT)

   $mTitle = "Login"
   WinWaitActive($mTitle,"",10)
   WinSetOnTop($mTitle,"",$WINDOWS_ONTOP)
   WinSetState($mTitle,"",@SW_ENABLE)
   MsgBox($MB_OK,"CopTrax Tester", "Admin password input... ",2)

   Sleep(100);
   MouseClick($MOUSE_CLICK_LEFT,590,100,2)
   Sleep(200)
   MouseDown($MOUSE_CLICK_LEFT)

   Sleep(400)
   Send("135799{ENTER}")

   ControlCommand($mTitle,"","WindowsForms10.EDIT.app.0.182b0e9_r11_ad1","135799{ENTER}")
   Exit

   ; Now select Admin by send DOWN key 10 times and then ENTER key
   Send("{DOWN 10}{ENTER}")
   Sleep(500)
   ControlClick("Login","","WindowsForms10.BUTTON.app.0.182b0e9_r11_ad11")
   Sleep(500)
   Send("135799{ENTER}")
   Exit
EndFunc

Func testRecord($n)
   WinSetOnTop($mCopTrax,"",$WINDOWS_ONTOP)
   WinSetState($mCopTrax,"",@SW_ENABLE)

   ; Sngle click at the record button with x, y position of 960, 80. This may trigger the record function.
   MouseMove(500,200)
   MouseClick($MOUSE_CLICK_LEFT, 960, 80)
   ; Wait for 5sec for function and then recording
   Sleep(5000)

   Local $mTitle = "Report Taken"
   WinWaitActive($mTitle,"",10)
   MsgBox($MB_OK,"CopTrax Automate Testor", $n & " Testing record input..",2)

   WinSetOnTop($mTitle,"",$WINDOWS_ONTOP)
   WinSetState($mTitle,"",@SW_ENABLE)

   MouseClick($MOUSE_CLICK_LEFT, 475,20)
   AutoItSetOption("SendKeyDelay", 100)
   Send("N")
   MouseClick($MOUSE_CLICK_LEFT, 475,20)
   Sleep(100)

   ; move the mouse to Operating User InputBox
   MouseClick($MOUSE_CLICK_LEFT, 475,100)
   ; AutoItSetOption("SendKeyDelay", 100)
   Send("jj")
   MouseClick($MOUSE_CLICK_LEFT, 475,100)
   Sleep(100)

   ; move the mouse to Comments InputBox
   MouseClick($MOUSE_CLICK_LEFT, 475,250)
   ; AutoItSetOption("SendKeyDelay", 100)
   Send("This is a test input by George Sun in CopTrax testing team.")
   Sleep(100)
EndFunc
