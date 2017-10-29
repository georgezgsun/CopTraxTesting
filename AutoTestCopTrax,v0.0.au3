#include <Constants.au3>
#RequireAdmin

;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win8
; Script Function:
;   Opens IncaXPCApp.exe, move mouse to specific position and simulate click to trigger the function.

HotKeySet("{ESC}", "stopCopTrax")
HotKeySet("^r", "testRecord")
;

; Prompt the user to run the script - use a Yes/No prompt with the flag parameter set at 4 (see the help file for more details)
Local $iAnswer = MsgBox(BitOR($MB_YESNO, $MB_SYSTEMMODAL), "CopTrax Tester", "This test will start CopTrax, simulate mouse movements and clicks to trigger the function.  Do you want to run it?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $iAnswer = 7 Then
	MsgBox($MB_SYSTEMMODAL, "CopTrax", "OK.  Bye!")
	Exit
EndIf

Run("CopTrax.bat")

; Wait for the CopTrax to become active. The classname "WindowsForms10.Window.208.app.0.182b0e9_r11_ad1" is monitored instead of the window title
Local $mCopTrax = WinWaitActive("[CLASS:WindowsForms10.Window.208.app.0.182b0e9_r11_ad1]",5)
; Wait for the CopTrax to become active. The window title "CopTrax II v.2.1.2 [testergs]"

; Sngle click at the record button with x, y position of 960, 80. This may trigger the record function.
MouseClick($MOUSE_CLICK_LEFT, 960, 80)
; Wait for 5sec for function and then recording
Sleep(5000)
; Sngle click at the record button with x, y position of 960, 80.  This may stop the record function.
MouseClick($MOUSE_CLICK_LEFT, 960, 80)
Sleep(2000)

; move the mouse to Incident Type InputBox
MouseClick($MOUSE_CLICK_LEFT, 175,12)
AutoItSetOption("SendKeyDelay", 100)
Send("N")
MouseClick($MOUSE_CLICK_LEFT, 175,12)
Sleep(1000)

; move the mouse to Operating User InputBox
MouseClick($MOUSE_CLICK_LEFT, 175,85)
; AutoItSetOption("SendKeyDelay", 100)
Send("jj")
MouseClick($MOUSE_CLICK_LEFT, 175,85)
Sleep(100)

; move the mouse to Comments InputBox
MouseClick($MOUSE_CLICK_LEFT, 175,175)
; AutoItSetOption("SendKeyDelay", 100)
Send("This is a test input by George Sun in CopTrax testing team.")
Sleep(100)

; move the mouse to OK button and click it
MouseClick($MOUSE_CLICK_LEFT, 175,270)
Sleep(1000)

; Finished!
