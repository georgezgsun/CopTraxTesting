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

Global Const $mMB = "CopTrax GUI Test Client"

TCPStartup()
Local $ip =  TCPNameToIP("10.0.7.58")
Local $port = 16869
Global $Socket
Global $boxName = "CopTrax9"

Do
   $Socket = TCPConnect($ip, $port)
Until $Socket <> -1
TCPSend($Socket,$boxName)

MsgBox($MB_OK, $mMB, "Connected to server",2)

Global $testEnd = False
Global $hTimer = TimerInit()	; Begin the timer and store the handler
Local $timeout = TimerDiff($hTimer) + 1000*60
While Not $testEnd
   Sleep(100)
   Local $fDiff = TimerDiff($hTimer)
   If TimerDiff($hTimer) > $timeout Then
	  logCPUMemory()		; log the CPU and memory usage every minute
	  $timeout += 1000*60	; reset the timer
   EndIf

   checkCommand()
WEnd

MsgBox($MB_OK, $mMB, "Testing ends. Bye.",2)

; Finished!

Func stopCopTrax()
   prepareTest()

   logWrite("135799")
   logWrite("Continue")
EndFunc

   ; Now select Admin by send DOWN key 10 times and then ENTER key

Func testRecord()
   prepareTest()

   logWrite("Start Record function testing.")
   Sleep(5000)
   logWrite("Continue")
EndFunc

Func _endRecord()
   prepareTest()

   logCPUMemory()
   logWrite("Stop record function testing.")

   Sleep(5000)
   logWrite("Continue")
EndFunc

Func testSettings()
   logWrite("Start settings function testing.")
   prepareTest()

   Sleep(15000)
   logWrite("Continue")
EndFunc

Func prepareTest()

EndFunc

Func testCamera()
   logWrite("Begin Camera function testing.")

   Local $hBMP = _ScreenCapture_Capture("")
   Local $screenFile = "camera" & @MON & @MDAY & @HOUR & @MIN & ".jpg"
   $screenFile = @MyDocumentsDir & "\CopTraxTesting\" & $screenFile
   _ScreenCapture_SaveImage($screenFile,$hBMP)
   Sleep(5000)
   ;logWrite("Screen")
   ;logWrite(FileRead(FileOpen($screenFile)))
   FileClose($screenFile)
   logWrite("Continue")
EndFunc

Func testPhoto()
   logWrite("Begin Photo function testing.")
   Sleep(5000)
   logWrite("Continue")
EndFunc

Func testReview()
   logWrite("Begin Review function testing.")
   Sleep(5000)
   logWrite("Continue")
EndFunc

Func logWrite($s)
   TCPSend($Socket,$s)
   Sleep(1000)
EndFunc

Func checkFile()
   local $aFileList = _FileListToArray(@MyDocumentsDir & "\CopTraxTemp","Rec_*.mp4", Default, True)
   If @error = 4 Then
	  Return False
   EndIf

   Return $aFileList[0] >= 1
EndFunc

Func checkCommand()
   Local $Recv = StringLower(TCPRecv($Socket, 1000))

   Switch $Recv ; The command received from the server
        Case "Esc" ; get a stop command, going to stop testing and quit
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

        Case "camera" ; Get a stop camera command, going to test the camera switch function
            MsgBox($MB_OK, $mMB, "Testing the camera switch function",2)
			testCamera()

        Case "photo" ; Get a stop photo command, going to test the photo function
            MsgBox($MB_OK, $mMB, "Testing the photo function",2)
			testPhoto()

        Case "review" ; Get a stop review command, going to test the review function
            MsgBox($MB_OK, $mMB, "Testing the review function",2)
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
