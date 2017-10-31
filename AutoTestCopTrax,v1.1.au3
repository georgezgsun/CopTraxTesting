#include <Constants.au3>
#include <File.au3>
#include <ScreenCapture.au3>
#include <Array.au3>
#include <Timers.au3>
#RequireAdmin
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
HotKeySet("+!e", "HotKeyPressed") ; Shift-Alt-e, to trigger testing on record function
HotKeySet("+!s", "HotKeyPressed") ; Shift-Alt-s, to trigger testing on settings function
HotKeySet("+!c", "HotKeyPressed") ; Shift-Alt-c, to trigger testing on camera switch function
HotKeySet("+!p", "HotKeyPressed") ; Shift-Alt-p, to trigger testing on photo function
HotKeySet("+!m", "HotKeyPressed") ; Shift-Alt-m, to trigger testing on mode function
HotKeySet("+!w", "HotKeyPressed") ; Shift-Alt-w, to trigger testing on review function

Global $rTimerID	; TimerID for record function
Global $mRecord = 1000*5;
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
   If $fDiff > 1000*60 Then
	  logCPUMemory()		; log the CPU and memory usage every minute
	  $hTimer = TimerInit()	; reset the timer
   EndIf
WEnd

FileClose($logFile)
MsgBox($MB_OK, $mMB, "Testing ends. Bye.",2)

; Finished!

Func stopCopTrax()
   prepareTest()

   MouseClick("",960,560)	; click on the info button
   Sleep(400)

   $testEnd = True	;	Stop testing marker

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, $mMB, "Cannot trigger the Info button. " & @CRLF & $mHandle,2)
	  logWrite("Click to info button failed.")
	  Exit
   EndIf

;   MouseClick("", 450, 80)	; click the About
   ControlClick($mTitle,"","Apply")
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

   ;Send("135799{ENTER}")	; type the administator password
   ControlCommand($mTitle,"","WindowsForms10.EDIT.app.0.182b0e9_r11_ad11","135799{ENTER}")
EndFunc

   ; Now select Admin by send DOWN key 10 times and then ENTER key

Func testRecord()
   ;prepareTest()

   logWrite("Start Record function testing.")

   Local $mHandle = WinActivate($mCopTrax);

   If ControlClick($mCopTrax,"","WindowsForms10.Window.8.app.0.182b0e9_r11_ad14") = 0 Then
	  MsgBox($MB_OK,"Test elert", " Click on the main tool bar failed.",2)
	  logWrite("Click to start record failed.")
   EndIf

   Sleep(100)
   MouseClick("", 960, 80)	; click to start record

   Sleep(10000)	; Wait for 10sec for record begin recording
   If checkFile() Then	; check if the specified files appear or not
	  logWrite("Recording start successfully.")
	  logCPUMemory()
   Else
	  logWrite("Recording failed to start.")
	  Exit
   EndIf
EndFunc

Func _endRecord()
   ;prepareTest()

   logCPUMemory()
   logWrite("Stop record function testing.")
   MouseClick("", 960, 80,2)	; click again to stop record

   Local $mTitle = "Report Taken"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the record function in CopTrax. " & @CRLF & $mWinClassLise,2)
	  logWrite("Click to stop record failed ")
	  Exit
   EndIf

   Sleep(200)

   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:2]")
   AutoItSetOption("SendKeyDelay", 100)
   Send("{DOWN 3}{ENTER}")
   Sleep(100)

   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Send("jj{ENTER}")
   Sleep(100)

   ControlClick($mTitle,"","[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Send("This is a test input by CopTrax testing team.")
   Sleep(100)

   ControlClick($mTitle,"","[CLASS:WindowsForms10.BUTTON.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Sleep(100)
EndFunc

Func testSettings()
   ;prepareTest()
   MouseClick("",960, 460)

   Local $mTitle = "CopTrax II Setup"
   Local $hWnd = WinWaitActive($mTitle,"",10)

   ControlClick($hWnd,"","Test")
   ;MouseClick($MOUSE_CLICK_LEFT, 900,470)
   Sleep(3000)

   ;MouseClick($MOUSE_CLICK_LEFT, 950,560)
   ControlClick($mTitle,"","Cancel")
   Sleep(400)
EndFunc

Func prepareTest()
   If  WinExists("Login") Then
	  WinClose("Login")
	  Sleep(100)
   EndIf

   If WinExists("Menu Action") Then
	  WinClose("Menu Action")
	  Sleep(100)
   EndIf

   If WinExists("Report Taken") Then
	  WinClose("Report Taken")
	  Sleep(100)
   EndIf

   WinActive($mCopTrax)
   Sleep(100)

   Local $mTitle = WinGetTitle("[ACTIVE]")

   If Not StringCompare(StringTrimLeft($mTitle, 7), "CopTrax") Then
	  MsgBox($MB_SYSTEMMODAL, $mMB,"Current active window ontop is " & $mTitle)
	  logWrite("Prepare testing Error. The active window ontop is " & $mTitle)
   EndIf

   MouseMove(600,200)
  ; ControlEnable($mCopTrax,"","[CLASS:WindowsForms10.Window.8.app.0.182b0e9_r11_ad1; INSTANCE:3]")
EndFunc

Func testCamera()
   logWrite("Begin Camera function testing.")

   ;prepareTest()

   MouseClick("",960,170)
   Sleep(1000)

   Local $hBMP = _ScreenCapture_Capture("")
   Local $screenFile = @MyDocumentsDir & "\CopTraxTesting\camera" & @MON & @MDAY & @HOUR & @MIN & ".jpg"
   _ScreenCapture_SaveImage($screenFile,$hBMP)
   logWrite("The camera Switched. The screen capture is saved as " & $screenFile);
EndFunc

Func testPhoto()
   logWrite("Begin Photo function testing.")

   MouseClick("", 960, 350);

   Local $mTitle = "Information"
   Local $hWnd = WinWaitActive($mTitle,"",5)
   Sleep(200)
   ControlClick($hWnd,"","OK")
   Sleep(200)
EndFunc

Func testReview()
   logWrite("Begin Review function testing.")
EndFunc

Func logWrite($s)
   _FileWriteLog($logFile,$s)
EndFunc

Func checkFile()
   local $aFileList = _FileListToArray(@MyDocumentsDir & "\CopTraxTemp","Rec_*.mp4", Default, True)
   If @error = 4 Then
	  Return False
   EndIf

   Return $aFileList[0] >= 1
EndFunc


Func HotKeyPressed()
    Switch @HotKeyPressed ; The last hotkey pressed.
        Case "{ESC}" ; String is the {ESC} hotkey. to stop testing and quit
            MsgBox($MB_OK, $mMB, "Stop testing. Bye",2)
            stopCopTrax()

        Case "+!r" ; String is the Shift-Alt-r hotkey. to testing the record function
            MsgBox($MB_OK, $mMB, "Testing the record function",2)
			testRecord()

        Case "+!e" ; String is the Shift-Alt-r hotkey. to testing the record function
            MsgBox($MB_OK, $mMB, "Testing the end record function",2)
			_endRecord()

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

        Case "+!1" ; String is the Shift-Alt-1 hotkey. to set record length 5 mins
            MsgBox($MB_OK, $mMB, "Record length is 5 minutes now.",2)
			$mRecord = 1000*60*5

        Case "+!2" ; String is the Shift-Alt-1 hotkey. to set record length 5 mins
            MsgBox($MB_OK, $mMB, "Record length is 10 minutes now.",2)
			$mRecord = 1000*60*10

        Case "+!3" ; String is the Shift-Alt-1 hotkey. to set record length 5 mins
            MsgBox($MB_OK, $mMB, "Record length is 20 minutes now.",2)
			$mRecord = 1000*60*20

        Case "+!4" ; String is the Shift-Alt-1 hotkey. to set record length 5 mins
            MsgBox($MB_OK, $mMB, "Record length is 30 minutes now.",2)
			$mRecord = 1000*60*30

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
