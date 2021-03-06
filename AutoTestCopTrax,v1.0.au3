#include <Constants.au3>
#include <File.au3>
;#RequireAdmin
;
; Testing on CopTrax Version: 1.0
; Language:       AutoIt
; Platform:       Win8
; Script Function:
;   Opens IncaXPCApp.exe, simulate mouse and keybaord to test the GUI of CopTrax Apps.
; Author: George Sun
; Oct., 2017
;

HotKeySet("{ESC}", "HotKeyPressed") ; ESC to trigger stop testing
HotKeySet("+!r", "HotKeyPressed") ; Shift-Alt-r, to trigger testing on record function
HotKeySet("+!s", "HotKeyPressed") ; Shift-Alt-s, to trigger testing on settings function
HotKeySet("+!c", "HotKeyPressed") ; Shift-Alt-c, to trigger testing on camera switch function
HotKeySet("+!p", "HotKeyPressed") ; Shift-Alt-p, to trigger testing on photo function
HotKeySet("+!m", "HotKeyPressed") ; Shift-Alt-m, to trigger testing on mode function
HotKeySet("+!w", "HotKeyPressed") ; Shift-Alt-w, to trigger testing on review function

; Prompt the user to run the script - use a Yes/No prompt with the flag parameter set at 4 (see the help file for more details)
Global $mMB = "CopTrax GUI Tester"
Global $logFile = @MyDocumentsDir & "\CopTraxTesting\test" & @MON & @MDAY & ".log"
ConsoleWrite($logFile & @CRLF)
FileOpen($logFile,1)
logCPUMemory()

;Run("CopTrax.bat")
;Sleep(2000)

Local $mClassName = "[CLASS:WindowsForms10.Window.208.app.0.182b0e9_r11_ad1]"
Local $mTitle = "CopTrax II v2.1.2.2 [testergs]"
$mTitle = "CopTrax Status"

WinActivate($mClassName)

If WinWaitClose($mTitle,5) = 0 Then
   MsgBox($MB_OK, $mMB, "Devices are not ready")
   logWrite("Devices are not ready")
EndIf

Global $mCopTrax = WinWaitActive($mClassName, "", 5)
; Retrieve the handle of the CopTrax window using the classname or Title.

Local $iAnswer = MsgBox($MB_OK, $mMB, "Gears are all ready. Testing start..." & $logFile & @CRLF & "Esc to quit" )

Global $testEnd = False
Global $hTimer = TimerInit()	; Begin the timer and store the handler
While Not $testEnd
   Sleep(100)
   Local $fDiff = TimerDiff($hTimer)
   If $fDiff > 1000*5 Then
	  logCPUMemory()		; log the CPU and memory usage every minutes
	  $hTimer = TimerInit()	; reset the timer
   EndIf
WEnd

FileClose($logFile)
MsgBox($MB_OK, $mMB, "Testing ends. Bye.",2)

; Finished!

Func stopCopTraxSAV()
   prepareTest()

   MsgBox($MB_OK, $mMB, "Testing Ends",2)

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

   $testEnd = True	;	Stop testing marker
   Exit

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, $mMB, "Cannot trigger the Info button. " & @CRLF & $mHandle,2)
	  logWrite("Click to info button failed.")
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
   ;ControlCommand($mTitle,"","WindowsForms10.EDIT.app.0.182b0e9_r11_ad11","135799{ENTER}")

   $testEnd = True;
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
   prepareTest()

   MouseClick(960, 460);

   Local $mTitle = "CopTrax II Setup"
   Local $hWnd = WinWaitActive($mTitle,"",10)
   MsgBox($MB_OK,"CopTrax Automate Testor", " Testing settings input..",2)
   Sleep(200)

   ControlClick($hWnd,"",4065668)

   ;MouseClick($MOUSE_CLICK_LEFT, 900,470)
   Sleep(2000)

   ;MouseClick($MOUSE_CLICK_LEFT, 950,560)
   ControlClick($mTitle,"",2951158)
   Sleep(400)
EndFunc

Func prepareTest()
   Local $hWnd = WinExists("Login")
   If $hWnd Then
	  WinClose($hWnd)
	  Sleep(100)
   EndIf

   $hWnd = WinExists("Menu Action")
   If $hWnd Then
	  WinClose($hWnd)
	  Sleep(100)
   EndIf

   $hWnd = WinExists("Report Taken")
   If $hWnd Then
	  WinClose($hWnd)
	  Sleep(100)
   EndIf

   WinActivate($mCopTrax)
   Sleep(100)

   Local $mTitle = WinGetTitle("[ACTIVE]")

   If Not StringCompare(StringTrimLeft($mTitle, 7), "CopTrax") Then
	  MsgBox($MB_SYSTEMMODAL, $mMB,"Current active window ontop is " & $mTitle)
	  logWrite("Prepare testing Error. The active window ontop is " & $mTitle)
   EndIf

   MouseMove(960,200)
   ControlEnable($mCopTrax,"","WindowsForms10.Window.8.app.0.182b0e9_r11_ad14")
   Sleep(100)
EndFunc

Func testCamera()
   logWrite("Begin Camera function testing.")
EndFunc

Func testPhoto()
   logWrite("Begin Photo function testing.")
EndFunc

Func testReview()
   logWrite("Begin Review function testing.")
EndFunc

Func logWrite($s)
   _FileWriteLog($logFile,$s)
EndFunc

Func HotKeyPressed()
    Switch @HotKeyPressed ; The last hotkey pressed.
        Case "{ESC}" ; String is the {ESC} hotkey. to stop testing and quit
            MsgBox($MB_OK, $mMB, "Stop testing. Bye",2)
            stopCopTrax()

        Case "+!r" ; String is the Shift-Alt-r hotkey. to testing the record function
            MsgBox($MB_OK, $mMB, "Testing the record function",2)
			testRecord()

        Case "+!s" ; String is the Shift-Alt-s hotkey. to testing the record function
            MsgBox($MB_OK, $mMB, "Testing the settings function",2)
			testSettings()

        Case "+!c" ; String is the Shift-Alt-c hotkey. to testing the record function
            MsgBox($MB_OK, $mMB, "Testing the camera switch function",2)
			testCamera()

        Case "+!p" ; String is the Shift-Alt-s hotkey. to testing the record function
            MsgBox($MB_OK, $mMB, "Testing the photo function",2)
			testPhoto()

        Case "+!w" ; String is the Shift-Alt-w hotkey. to testing the review function
            MsgBox($MB_OK, $mMB, "Testing the photo function",2)
			testReview()

    EndSwitch
 EndFunc   ;==>HotKeyPressed

Func logCPUMemory()
   Local $logLine = ""
   Local $aMem = MemGetStats()
   $logLine = "Memory usage " & $aMem[0] & "%; "

   Local $aUsage = _GetCPUUsage()
   For $i = 1 To $aUsage[0]
	  $logLine = $logLine & 'CPU #' & $i & ' - ' & $aUsage[$i] & '%; '
   Next
   logWrite($logLine)
   ConsoleWrite($logLine & @crlf)
EndFunc


;#####################################################################
;# Function: _GetCPUUsage()
;# Gets the utilization of the CPU, compatible with multicore
;# Return:   Array
;#           Array[0] Count of CPU, error if negative
;#           Array[n] Utilization of CPU #n in percent
;# Error:    -1 Error at 1st Dll-Call
;#           -2 Error at 2nd Dll-Call
;#           -3 Error at 3rd Dll-Call
;# Author:   Bitboy  (AutoIt.de)
;#####################################################################
Func _GetCPUUsage()
    Local Const $SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = 8
    Local Const $SYSTEM_TIME_INFO = 3
    Local Const $tagS_SPPI = "int64 IdleTime;int64 KernelTime;int64 UserTime;int64 DpcTime;int64 InterruptTime;long InterruptCount"

    Local $CpuNum, $IdleOldArr[1],$IdleNewArr[1], $tmpStruct
    Local $timediff = 0, $starttime = 0
    Local $S_SYSTEM_TIME_INFORMATION, $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION
    Local $RetArr[1]

    Local $S_SYSTEM_INFO = DllStructCreate("ushort dwOemId;short wProcessorArchitecture;dword dwPageSize;ptr lpMinimumApplicationAddress;" & _
    "ptr lpMaximumApplicationAddress;long_ptr dwActiveProcessorMask;dword dwNumberOfProcessors;dword dwProcessorType;dword dwAllocationGranularity;" & _
    "short wProcessorLevel;short wProcessorRevision")

    $err = DllCall("Kernel32.dll", "none", "GetSystemInfo", "ptr",DllStructGetPtr($S_SYSTEM_INFO))

    If @error Or Not IsArray($err) Then
        Return $RetArr[0] = -1
    Else
        $CpuNum = DllStructGetData($S_SYSTEM_INFO, "dwNumberOfProcessors")
        ReDim $RetArr[$CpuNum+1]
        $RetArr[0] = $CpuNum
    EndIf
    $S_SYSTEM_INFO = 0

    While 1
        $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = DllStructCreate($tagS_SPPI)
        $StructSize = DllStructGetSize($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION)
        $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = DllStructCreate("byte puffer[" & $StructSize * $CpuNum & "]")
        $pointer = DllStructGetPtr($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION)

        $err = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", _
            "int", $SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION, _
            "ptr", DllStructGetPtr($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION), _
            "int", DllStructGetSize($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION), _
            "int", 0)

        If $err[0] Then
            Return $RetArr[0] = -2
        EndIf

        Local $S_SYSTEM_TIME_INFORMATION = DllStructCreate("int64;int64;int64;uint;int")
        $err = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", _
            "int", $SYSTEM_TIME_INFO, _
            "ptr", DllStructGetPtr($S_SYSTEM_TIME_INFORMATION), _
            "int", DllStructGetSize($S_SYSTEM_TIME_INFORMATION), _
            "int", 0)

        If $err[0] Then
            Return $RetArr[0] = -3
        EndIf

        If $starttime = 0 Then
            ReDim $IdleOldArr[$CpuNum]
            For $i = 0 to $CpuNum -1
                $tmpStruct = DllStructCreate($tagS_SPPI, $Pointer + $i*$StructSize)
                $IdleOldArr[$i] = DllStructGetData($tmpStruct,"IdleTime")
            Next
            $starttime = DllStructGetData($S_SYSTEM_TIME_INFORMATION, 2)
            Sleep(100)
        Else
            ReDim $IdleNewArr[$CpuNum]
            For $i = 0 to $CpuNum -1
                $tmpStruct = DllStructCreate($tagS_SPPI, $Pointer + $i*$StructSize)
                $IdleNewArr[$i] = DllStructGetData($tmpStruct,"IdleTime")
            Next

            $timediff = DllStructGetData($S_SYSTEM_TIME_INFORMATION, 2) - $starttime

            For $i=0 to $CpuNum -1
                $RetArr[$i+1] = Round(100-(($IdleNewArr[$i] - $IdleOldArr[$i]) * 100 / $timediff))
            Next

            Return $RetArr
        EndIf

        $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = 0
        $S_SYSTEM_TIME_INFORMATION = 0
        $tmpStruct = 0
    WEnd
EndFunc
