;
; Test client for CopTrax Version: 1.0
; Language:       AutoIt
; Platform:       Win8
; Script Function:
;   Connect to a test server
;   Wait CopTrax app to , waiting its powerup and connection to the server;
;   Send test commands from the test case to individual target(client);
;	Receive test results from the target(client), verify it passed or failed, log the result;
;	Drop the connection to the client when the test completed.
; Author: George Sun
; Nov., 2017
;

#include <Constants.au3>
#include <File.au3>
#include <ScreenCapture.au3>
#include <Array.au3>
#include <Timers.au3>
#RequireAdmin

HotKeySet("{ESC}", "HotKeyPressed") ; Esc to stop testing
HotKeySet("+!t", "HotKeyPressed") ; Shift-Alt-t to stop CopTrax
HotKeySet("+!s", "HotKeyPressed") ; Shift-Alt-s, to start CopTrax

Global Const $mMB = "CopTrax GUI Test Client"

TCPStartup()
Local $ip =  TCPNameToIP("10.25.50.110")
Local $port = 16869
Global $Socket = -1
Global $boxName = "CopTrax11"

Local $mClassName = "[CLASS:WindowsForms10.Window.208.app.0.182b0e9_r11_ad1]"
Local $mTitle = "CopTrax Status"

Global $mCopTrax = WinActivate($mClassName)

If WinWaitClose($mTitle,5) = 0 Then
   MsgBox($MB_OK, $mMB, "Devices are not ready")
   Exit
EndIf

$mCopTrax = WinWaitActive($mClassName, "", 5) ; Retrieve the handle of the CopTrax window using the classname.

MsgBox($MB_OK, $mMB, "Gears are all ready. Testing start..." & @CRLF & "Esc to quit", 2)

Global $testEnd = False
Global $hTimer = TimerInit()	; Begin the timer and store the handler
Local $currentTime = TimerDiff($hTimer)
Global $timeout =  $currentTime + 1000*60
While Not $testEnd
   If $Socket < 0 Then
	  $Socket = TCPConnect($ip, $port)
	  If $Socket >= 0 Then
		 TCPSend($Socket,$boxName)
		 MsgBox($MB_OK, $mMB, "Connected to server",2)
	  EndIf
   Else
	  $currentTime = TimerDiff($hTimer)
	  If  $currentTime > $timeout Then
		 logCPUMemory()		; log the CPU and memory usage every minute
		 $timeout = $currentTime + 1000*60	; reset the timer
	  EndIf

	  checkCommand()
   EndIf
   Sleep(100)
WEnd

MsgBox($MB_OK, $mMB, "Testing ends. Bye.",2)

; Finished!

Func stopCopTrax()
   readyToTest()

   MouseClick("",960,560)	; click on the info button
   Sleep(400)

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, $mMB, "Cannot trigger the Info button. " & @CRLF & $mHandle,2)
	  logWrite("Click to info button failed.")
	  logWrite("Failed")
	  Exit
   EndIf
   Sleep(100)

;   MouseClick("", 450, 80)	; click the About
   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Sleep(500)
   Send("{DOWN 8}{ENTER}")	; choose the Administrator
   ControlClick($mTitle,"","Apply")

   Sleep(500)
   Local $mTitle = "Login"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  Local $mWinClassList = WinGetClassList($mCopTrax)
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the Login window. " & @CRLF & $mHandle,2)
	  ConsoleWriteError("Click to Login window failed at " & @HOUR & ":" & @MIN & ", " & @MON & " / " & @MDAY & @CRLF)
	  logWrite("Failed")
	  Exit
   EndIf

   Send("135799{ENTER}")	; type the administator password
   ;ControlCommand($mTitle,"","WindowsForms10.EDIT.app.0.182b0e9_r11_ad11","135799{ENTER}")
   logWrite("Continue")
EndFunc

   ; Now select Admin by send DOWN key 10 times and then ENTER key

Func testRecord()
   readyToTest()

   logWrite("Start Record function testing.")

   Local $mHandle = WinActivate($mCopTrax);

   If ControlClick($mCopTrax,"","WindowsForms10.Window.8.app.0.182b0e9_r11_ad14") = 0 Then
	  MsgBox($MB_OK, $mMB, "Click on the main tool bar failed.",2)
	  logWrite("Click to start record failed.")
	  logWrite("Failed")
EndIf

   Sleep(100)
   MouseClick("", 960, 80)	; click to start record

   Sleep(10000)	; Wait for 10sec for record begin recording
   If checkFile() Then	; check if the specified files appear or not
	  logWrite("Recording start successfully.")
	  logCPUMemory()
   Else
	  logWrite("Recording failed to start.")
	  logWrite("Failed")
	  Exit
   EndIf
   logWrite("Continue")
EndFunc

Func _endRecord()
   readyToTest()

   logCPUMemory()
   logWrite("Stop record function testing.")
   MouseClick("", 960, 80,2)	; click again to stop record

   Local $mTitle = "Report Taken"
   If WinWaitActive($mTitle,"",2) = 0 Then
	  MsgBox($MB_OK,  $mMB, "Cannot trigger the end record function",2)
	  logWrite("Click to stop record failed ")
	  logWrite("Failed")
	  Exit
   EndIf

   Sleep(2000)

   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:2]")
   AutoItSetOption("SendKeyDelay", 200)
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

   While WinWaitClose($mTitle,"",2) = 0
	  MsgBox($MB_OK,  $mMB, "Click on the OK button failed",2)
	  logWrite("Click on the OK button to stop record failed. ")
	  WinClose($mTitle)
   WEnd

   logWrite("Continue")
EndFunc

Func testSettings()
   If Not readyToTest() Then Return

   logWrite("Start settings function testing.")

   MouseClick("",960, 460)

   Local $mTitle = "CopTrax II Setup"
   Local $hWnd = WinWaitActive($mTitle,"",10)
      If WinWaitActive($mTitle,"",2) = 0 Then
	  MsgBox($MB_OK,  $mMB, "Cannot trigger the settings function.",2)
	  logWrite("Click to trigger the settings function failed ")
	  logWrite("Failed")
	  Exit
   EndIf

   ControlClick($hWnd,"","Test")
   Sleep(3000)

   MouseClick("", 60, 120) ;"Hardware Triggers")
   Sleep(2000)

   MouseClick("", 60, 180) ;"Speed Triggers")
   Sleep(2000)

   MouseClick("", 60, 240) ;"GPS & Radar")
   Sleep(200)

   MouseClick("", 930, 295) ;"Test")
   Sleep(2000)

   MouseClick("", 60, 300) ;"Security")
   Sleep(2000)

   MouseClick("", 60, 360) ;"Upload & Storage")
   Sleep(2000)

   MouseClick("", 60, 420) ;"Misc")
   Sleep(2000)

   MouseClick("", 60, 60) ;"Cameras")
   Sleep(2000)

   ControlClick($mTitle,"","Cancel")
   Sleep(2000)

   If WinWaitClose($mTitle,"",2) = 0 Then
	  MsgBox($MB_OK,  $mMB, "Click on the Cancel button failed",2)
	  logWrite("Click on the Cancel button to quit settings failed ")
	  logWrite("Failed")
	  Exit
   EndIf

   logWrite("Continue")
EndFunc

Func readyToTest()
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

   WinActivate($mCopTrax)
   Sleep(100)
   If WinWaitActive($mCopTrax, "", 2) = 0 Then
	  logWrite("Hold on! The CopTrax is not ready")
	  Return False
	  EndIf

   Local $mTitle = WinGetTitle("[ACTIVE]")

   If Not StringCompare(StringTrimLeft($mTitle, 7), "CopTrax") Then
	  MsgBox($MB_SYSTEMMODAL, $mMB,"Current active window ontop is " & $mTitle)
	  logWrite("Prepare testing Error. The active window ontop is " & $mTitle)
   EndIf
   Return True
EndFunc

Func testCamera()
   If Not readyToTest() Then Return
   ;readyToTest()
   logWrite("Begin Camera function testing.")

   MouseClick("",960,170)
   Sleep(1000)
   logWrite("Continue")
   Return

   Local $hBMP = _ScreenCapture_Capture("")
   Local $screenFile = "camera" & @MON & @MDAY & @HOUR & @MIN & ".jpg"
   logWrite("file " & $screenFile)
   $screenFile = @MyDocumentsDir & "\CopTraxTesting\" & $screenFile
   _ScreenCapture_SaveImage($screenFile,$hBMP)
   TCPSend($Socket,FileRead(FileOpen($screenFile)))
   FileClose($screenFile)

   Sleep(1000)
   logWrite("done")
   Sleep(500)
   logWrite("Continue")
EndFunc

Func testPhoto()
   If Not readyToTest() Then Return

   logWrite("Begin Photo function testing.")

   MouseClick("", 960, 350);

   Local $hWnd = WinWaitActive("Information", "", 5)
   Sleep(1000)
   ControlClick($hWnd,"","OK")
   Sleep(200)

   If WinWaitClose($hWnd,"",2) = 0 Then
	  MsgBox($MB_OK, $mMB, "Clickon the OK button to close the Photo failed.",2)
	  logWrite("Click on the OK button to quit Photo taking failed.")
	  logWrite("Failed")
	  Exit
   EndIf
   logWrite("Continue")
EndFunc

Func testReview()
   If Not readyToTest() Then Exit

   logWrite("Begin Review function testing.")

   Local $hWnd = ControlGetHandle($mCopTrax, "", "CLASSNAME OR CONTROL ID")
   MouseClick("", 960, 260);
   Local $hWnd = WinWaitActive("CopTrax | Video Playback", "", 5)
   Sleep(5000)
   WinClose($hWnd)
   Sleep(200)

   If WinWaitClose($hWnd,"",2) = 0 Then
	  MsgBox($MB_OK, $mMB, "Click to close the playback window failed.",2)
	  logWrite("Click to close the playback review function failed.")
	  logWrite("Failed")
	  Exit
   EndIf
   logWrite("Continue")
EndFunc

Func logWrite($s)
   Local $rst = TCPSend($Socket, $s & " ")
   If ($Socket < 0) Or ( $rst = 0) Then
	  $Socket = -1
	  MsgBox($MB_OK, $mMB, "Connection to server lost",2)
	  Return
	  EndIf

   $timeout = TimerDiff($hTimer) + 1000*60
   Sleep(500)
EndFunc

Func checkFile()
   local $aFileList = _FileListToArray(@MyDocumentsDir & "\CopTraxTemp","Rec_*.mp4", Default, True)
   If @error = 4 Then
	  Return False
   EndIf

   Return $aFileList[0] >= 1
EndFunc

Func checkCommand()
   Local $Recv = StringSplit(StringLower(TCPRecv($Socket, 100000)), " ")

   Switch $Recv[1] ; The last hotkey pressed.
	  Case "esc" ; get a stop command, going to stop testing and quit
		 MsgBox($MB_OK, $mMB, "Stop testing. Bye",2)
		 stopCopTrax()

	  Case "record" ; Get a record command. going to test the record function
		 MsgBox($MB_OK, $mMB, "Testing the record function",2)
		 testRecord()

	  Case "endrecord" ; Get a stop record command, going to end the record function
		 MsgBox($MB_OK, $mMB, "Testing the end record function",2)
		 _endRecord()

	  Case "settings" ; Get a stop setting command, going to test the settings function
		 MsgBox($MB_OK, $mMB, "Testing the settings function",2)
		 testSettings()
		 Sleep(1000)

	  Case "camera" ; Get a stop camera command, going to test the camera switch function
		 MsgBox($MB_OK, $mMB, "Testing the camera switch function",2)
		 testCamera()

	  Case "photo" ; Get a stop photo command, going to test the photo function
		 MsgBox($MB_OK, $mMB, "Testing the photo function",2)
		 testPhoto()

	  Case "review" ; Get a stop review command, going to test the review function
		 MsgBox($MB_OK, $mMB, "Testing the review function",2)
		 testReview()

	  Case "upload"
		 MsgBox($MB_OK, $mMB, "Testing file upload function",2)
		 uploadFile($Recv[2])

	  Case "update"
		 MsgBox($MB_OK, $mMB, "Testing file update function",2)
		 updateFile($Recv[2])
   EndSwitch
 EndFunc

Func uploadFile($filename)
EndFunc

Func updateFile($filename)
EndFunc

Func HotKeyPressed()
   Switch @HotKeyPressed ; The last hotkey pressed.
	  Case "{ESC}" ; KeyStroke is the {ESC} hotkey. to stop testing and quit
	  $testEnd = True	;	Stop testing marker

	  Case "+!t" ; Keystroke is the Shift-Alt-t hotkey, to stop the CopTrax
		 MsgBox($MB_OK, $mMB, "Terminating the CopTrax. Bye",2)
		 stopCopTrax()

	  Case "+!s" ; Keystroke is the Shift-Alt-s hotkey, to start the CopTrax
		 MsgBox($MB_OK, $mMB, "Starting the CopTrax",2)
		 Run("IncaXPCApp.exe", "c:\Program Files (x86)\IncaX\CopTrax")

    EndSwitch
 EndFunc   ;==>HotKeyPressed

Func logCPUMemory()
   Local $logLine = ""
   Local $aMem = MemGetStats()
   $logLine = " Memory usage " & $aMem[0] & "%; "

   Local $aUsage = _GetCPUUsage()
   For $i = 1 To $aUsage[0]
	  $logLine = $logLine & 'CPU #' & $i & ' - ' & $aUsage[$i] & '%; '
   Next
   logWrite($logLine)
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

Func _MouseClick($hWnd, $x, $y, $times=1, $delay=250)
   If $hWnd = 0 Then
	  SetError(-1)
	  Return
   EndIf

   Local $ix
   Local $lParam = BitOR($y * 0x10000, BitAND($x, 0xFFFF))
   Local $user32 = DllOpen("user32.dll")

   For $ix = 1 To $times
	  DllCall($user32, "int", "PostMessage", "hwnd", $hWnd, "int", 0x200, "int", 0, "long", $lParam)
	  DllCall($user32, "int", "PostMessage", "hwnd", $hWnd, "int", 0x201, "int", 1, "long", $lParam)
	  DllCall($user32, "int", "PostMessage", "hwnd", $hWnd, "int", 0x202, "int", 0, "long", $lParam)

	  If $ix < $times Then Sleep($delay)
   Next
   If $user32 <> -1 Then DllClose($user32)
EndFunc
