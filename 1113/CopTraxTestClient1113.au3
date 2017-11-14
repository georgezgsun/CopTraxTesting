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
#include <Date.au3>
#RequireAdmin

HotKeySet("q", "HotKeyPressed") ; q to stop testing
HotKeySet("+!t", "HotKeyPressed") ; Shift-Alt-t to stop CopTrax
HotKeySet("+!s", "HotKeyPressed") ; Shift-Alt-s, to start CopTrax

Global Const $mMB = "CopTrax GUI Test Client"

TCPStartup()
Global $ip =  TCPNameToIP("10.25.50.110")
Global $port = 16869
Global $Socket = -1
Global $boxName = "CopTrax11"
Global $filesToBeSent = ""
Global $fileContent
Global $bytesCounter
Global $fileToBeUpdate = ""
Global $workDir = "C:\CopTraxTest\tmp\"
Global $configFile = "C:\CopTraxTest\client.cfg"
configRead()
OnAutoItExitRegister("OnAutoItExit")	; Register OnAutoItExit to be called when the script is closed.

$fileContent = FileOpen($workDir & "restartclient.bat", 8+2)
FileWriteLine($fileContent, "cd C:\CopTraxTest")
FileWriteLine($fileContent, "copy tmp\coptraxtestclient.exe ")
FileWriteLine($fileContent, "start  /d C:\CopTraxTest coptraxtestclient.exe")
FileClose($fileContent)

Global $mCopTrax = 0
Global $title = ""
Global $userName = ""

MsgBox($MB_OK, $mMB, "Testing start. Connecting to" & $ip & "..." & @CRLF & "Esc to quit", 2)

Global $testEnd = False
Global $hTimer = TimerInit()	; Begin the timer and store the handler
Global $timeout =  TimerDiff($hTimer) + 1000*60
Global $chunkTime = 0
Global $sendBlock = False

Local $mClassName = "[CLASS:WindowsForms10.Window.208.app.0.182b0e9_r11_ad1]"
While Not $testEnd
   If $mCopTrax = 0 Then
	  $mCopTrax = WinWaitActive($mClassName, "", 1)
	  If $mCopTrax <> 0 Then
		 $userName = getUserName()
		 $title = WinGetTitle($mCopTrax, "")
	  EndIf
   EndIf
   If $Socket < 0 Then
	  $Socket = TCPConnect($ip, $port)
	  If $Socket >= 0 Then
		 logWrite("name " & $boxName & " " & $userName & " " & $title & getLastTime($workDir & "CopTraxTestClient.exe",0))
		 MsgBox($MB_OK, $mMB, "Connected to server",2)
	  EndIf
   Else
	  checkCommand()
	  If  TimerDiff($hTimer) > $timeout Then
		 logCPUMemory()		; log the CPU and memory usage every minute
	  EndIf
   EndIf
   Sleep(100)
WEnd

TCPShutdown() ; Close the TCP service.
MsgBox($MB_OK, $mMB, "Testing ends. Bye.",5)

; Finished!
Func getUserName()
   If $mCopTrax = 0 Then Return ""

   $Title = WinGetTitle($mCopTrax) ;"CopTrax Status"
   Local $s = StringSplit($Title, "[")
   Local $ss = StringSplit($s[2],"]")
   Return $ss[1]
EndFunc

Func stopCopTrax()
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
	  EndIf

   AutoItSetOption("SendKeyDelay", 200)
   MouseClick("",960,560)	; click on the info button
   Sleep(400)

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Cannot trigger the Info button. " & @CRLF,2)
	  logWrite("Click to info button failed.")
	  logWrite("Failed")
	  Return
   EndIf
   Sleep(100)

;   MouseClick("", 450, 80)	; click the About
   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Sleep(500)
   Send("{DOWN 10}{ENTER}")	; choose the Administrator
   ControlClick($mTitle,"","Apply")

   Sleep(500)
   $mTitle = "Login"
   If WinWaitActive($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the Login window. " & @CRLF,2)
	  logWrite("Click on Apply button to close the Login window failed.")
	  logWrite("Failed")
	  WinClose($mTitle)
	  Return
   EndIf

   Send("135799{ENTER}")	; type the administator password
   logWrite("Continue")
EndFunc

Func login($name, $password)
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
   EndIf

   AutoItSetOption("SendKeyDelay", 200)
   MouseClick("",960,560)	; click on the info button
   Sleep(400)

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Cannot trigger the info window. " & @CRLF,2)
	  logWrite("Click to open info window failed.")
	  logWrite("Failed")
	  WinClose($mTitle)
	  Return
   EndIf
   Sleep(100)

   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Sleep(500)
   Send("s")	; choose switch Account
   ControlClick($mTitle,"","Apply")

   Sleep(500)
   Local $mTitle = "CopTrax - Login / Create Account"
   If WinWaitActive($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK, "Test Alert", "Cannot trigger the CopTrax-Login/Create Account window. " & @CRLF,2)
	  logWrite("Click Apply button to trigger the CopTrax-Login/Create Account window failed.")
	  logWrite("Failed")
	  Return
   EndIf

   ControlClick($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:4]")
   Send($name)	; type the new username
   Sleep(500)
   ControlClick($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:3]]")
   Send($password)	; type the user password
   Sleep(500)
   ControlClick($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:2]")
   Send($password)	; re-type the user password

   Sleep(2500)
   ControlClick($mTitle, "", "Register")

   If WinWaitClose($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Clickon the Register button to close the Photo failed.",2)
	  logWrite("Click on the Register button to exit failed.")
	  logWrite("Failed")
	  WinClose($mTitle)
	  Return
   EndIf

   Sleep(3000)

   $userName = getUserName()
   If $userName <> $name Then
	  logWrite("Switch to new user failed. Current user is " & $userName)
	  logWrite("Failed")
	  Return
   EndIf

   logWrite("Continue")
EndFunc

Func testRecord()
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
   EndIf

   logWrite("Testing start record function.")

   Local $mHandle = WinActivate($mCopTrax);
   If ControlClick($mCopTrax,"","WindowsForms10.Window.8.app.0.182b0e9_r11_ad14") = 0 Then
	  logWrite("Click to start record failed.")
	  MsgBox($MB_OK, $mMB, "Click on the main tool bar failed.",2)
	  logWrite("Failed")
   EndIf

   Sleep(100)
   MouseClick("", 960, 80)	; click to start record

   Sleep(15000)	; Wait for 15sec for record begin recording
   If checkFile() Then	; check if the specified *.mp4 files appear or not
	  logWrite("Recording start successfully.")
	  logWrite("Continue")
   Else
	  logWrite("Recording failed to start.")
	  logWrite("Failed")
	  Return
   EndIf
EndFunc

Func _endRecord()
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("continue")
	  Return
   EndIf

   logWrite("Testing stop record function.")
   MouseClick("", 960, 80)	; click again to stop record
   MouseMove(300,100)
   Sleep(1000)

   Local $mTitle = "Report Taken"
   If WinWaitActive($mTitle,"",15) = 0 Then
	  logWrite("Click to stop record failed. ")
	  MsgBox($MB_OK,  $mMB, "Cannot trigger the end record function",2)
	  logWrite("Failed")
	  Return
   EndIf

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

   While WinWaitClose($mTitle,"",10) = 0
	  MsgBox($MB_OK,  $mMB, "Click on the OK button failed",2)
	  logWrite("Click on the OK button to stop record failed. ")
	  WinClose($mTitle)
   WEnd

   logWrite("Continue")
   uploadFile()
EndFunc

Func testSettings($pre, $chunk)
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
	  EndIf

   logWrite("Start settings function testing.")

   MouseClick("",960, 460)

   Local $mTitle = "CopTrax II Setup"
   Local $hWnd = WinWaitActive($mTitle,"",10)
      If WinWaitActive($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK,  $mMB, "Cannot trigger the settings function.",2)
	  logWrite("Click to trigger the settings function failed ")
	  logWrite("Failed")
	  Return
	  EndIf

   ControlClick($hWnd,"","Test")
   Sleep(500)
   MouseClick("",260,285)
   Sleep(200)
   Switch $pre
	  Case 0
		 Send("0{ENTER}")
	  Case 15
		 Send("0{DOWN}{ENTER}")
	  Case 30
		 Send("3{ENTER}")
	  Case 45
		 Send("4{ENTER}")
	  Case 60
		 Send("6{ENTER}")
	  Case 90
		 Send("9{ENTER}")
	  Case 120
		 Send("9{DOWN}{ENTER}")
   EndSwitch
   Sleep(3000)

   MouseClick("", 60, 120) ;"Hardware Triggers")
   Sleep(1000)
   ControlClick($hWnd, "", "Identify")
   Sleep(2000)

   Local $versionTxt = StringTrimLeft(WinGetText("[ACTIVE]"),2)
   logWrite("The current firmware version is " & $versionTxt)

   ControlClick("CopTrax", "", "OK")
   Sleep(200)

   MouseClick("", 60, 240) ;"Upload & Storage")
   Sleep(500)

   MouseClick("", 600,165)
   Sleep(500)
   Send("{BS 4} " & $chunk)
   Sleep(1000)

   ControlClick($mTitle,"","Apply")
   Sleep(2000)

   If WinWaitClose($mTitle,"",10) = 0 Then
	  MsgBox($MB_OK,  $mMB, "Click on the Apply button failed",2)
	  logWrite("Click on the Apply button to quit settings failed ")
	  logWrite("Failed")
	  WinClose($mTitle)
	  Return
   EndIf

   $chunkTime = $chunk
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
	  Return False
	  EndIf

   Local $mTitle = WinGetTitle("[ACTIVE]")

   If Not StringCompare(StringTrimLeft($mTitle, 7), "CopTrax") Then
	  MsgBox($MB_SYSTEMMODAL, $mMB,"Current active window ontop is " & $mTitle)
	  logWrite("Prepare testing Error. The active window ontop is " & $mTitle)
   EndIf
   Return True
EndFunc

Func testCamera($n)
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
   EndIf

   logWrite("Begin Camera function testing.")

   takeScreenCapture("Original Cam")

   MouseClick("",960,170)
   Sleep(2000)

   takeScreenCapture("Switched Cam1")
   If $n >= 1 Then
	  MouseClick("", 200,170)	; click to switch camera
	  Sleep(1000)
	  takeScreenCapture("Switched Cam2")
   EndIf

   If BitAND($n,1) = 0 Then
	  MouseClick("", 200,170)	; click to switch camera if n=2,4,6,...
	  Sleep(1000)
   EndIf

   logWrite("Continue")
   uploadFile()
EndFunc

Func takeScreenCapture($cam)
   Local $hBMP = _ScreenCapture_Capture("")
   Local $screenFile = $boxName & Chr(Random(65,90,1)) & Chr(Random(65,90,1)) & Chr(Random(65,90,1)) & ".jpg"
   logWrite($cam & ": screen captured file " & $screenFile & " is on the way sending to server.")
   $screenFile = $workDir & $screenFile
   _ScreenCapture_SaveImage($screenFile,$hBMP)
   $filesToBeSent =  $screenFile & "|" & $filesToBeSent
EndFunc

Func testPhoto()
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
   EndIf

   logWrite("Begin Photo function testing.")

   MouseClick("", 960, 350);

   Local $hWnd = WinWaitActive("Information", "", 5)
   Sleep(2000)
   ControlClick($hWnd,"","OK")
   Sleep(200)

   If WinWaitClose($hWnd,"",10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Clickon the OK button to close the Photo failed.",2)
	  logWrite("Click on the OK button to quit Photo taking failed.")
	  logWrite("Failed")
	  Return
   EndIf
   logWrite("Continue")
   uploadFile()
EndFunc

Func testReview()
   If Not readyToTest() Then
	  logWrite("Hold on! The CopTrax is not ready.")
	  logWrite("Failed")
	  Return
   EndIf

   logWrite("Begin Review function testing.")

   MouseClick("", 960, 260);
   Local $hWnd = WinWaitActive("CopTrax | Video Playback", "", 10)
   Sleep(5000)
   WinClose($hWnd)
   Sleep(200)

   If WinWaitClose($hWnd,"",10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Click to close the playback window failed.",2)
	  logWrite("Click to close the playback review function failed.")
	  logWrite("Failed")
	  Return
   EndIf
   logWrite("Continue")
EndFunc

Func logWrite($s)
   If $sendBlock Then Return
   TCPSend($Socket, $s & " ")
   $timeout = TimerDiff($hTimer) + 1000*60
   Sleep(1000)
EndFunc

Func checkFile()
   local $aFileList = _FileListToArray(@MyDocumentsDir & "\CopTraxTemp","Rec_*.mp4", Default, True)
   If @error = 4 Then
	  Return False
   EndIf

   Return $aFileList[0] >= 1
EndFunc

Func checkRecord()
   logWrite("Begin to review the records to check the chunk time.")

   If checkRecordFiles("") Then
	  logWrite("For main camera, the chunk set correct.")
   Else
	  logWrite("For main camera, the chunk set in-correct.")
   EndIf

   If checkRecordFiles("\cam2") Then
	  logWrite("For main camera, the chunk set correct.")
   Else
	  logWrite("For main camera, the chunk set in-correct.")
   EndIf

   logWrite("continue")
EndFunc

Func checkRecordFiles($append)
   $userName = getUserName()
   Local $month[13] = ["","Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
   Local $path = @LocalAppDataDir & "\coptrax\" & $userName & "\" & @MDAY & "-" & $month[@MON] & "-" & @YEAR & $append
   Local $fileTypes = ["*.*","*.wmv", "*.jpg", "*.gps", "*.txt", "*.rdr", "*.vm", "*.trax", "*.rp"]
   Local $latestFiles[9]

   Local $i
   logWrite("For " & $path & ", the setup chunk time is " & $chunkTime & " minutes.")
   For	$i = 0 To 8
	  $latestFiles[$i] = getLatestFile($path, $fileTypes[$i])
	  ;logWrite($latestFiles[$i])
   Next

   Local $createTime0 = getLastTime($latestFiles[0],1)

   For $i = 1 To 3
	  Local $fileName = $latestFiles[$i]
	  Local $fileSize = FileGetSize($fileName) / 1024 /1024
	  Local $createTime = getLastTime($fileName,1)
	  Local $modifiedTime = getLastTime($fileName,0)
	  Local $netFileName = StringSplit($fileName, "\")
	  Local $chunk = _DateDiff("m", $modifiedTime, $createTime)

	  logWrite($netFileName[$netFileName[0]] & " created at " & $createTime & ", closed at " & $modifiedTime & ", size of " & $fileSize & "MB, and chunk is " & $chunk & " minutes.")

	  If (_DateDiff("s", $createTime, $createTime0) > 3) Or ($chunk > $chunkTime*60 + 10) Then
		 Return False	; return False when .gps or .wmv or .jpg files were missing,
	  EndIf
   Next
   Return True
EndFunc

Func getLatestFile($path,$type)
    ; List the files only in the directory using the default parameters.
    Local $aFileList = _FileListToArray($path, $type, 1, True)

    If @error <> 0 Then
	  Return ""
    EndIf

   Local $i, $latestFile, $fileData = "20101101121030", $fileDate
   For $i = 1 to $aFileList[0]
	  $fileDate = FileGetTime($aFileList[$i], 1, 1)	; get last create time in String format
	  if Number($fileDate) > Number($fileData) Then
		 $fileData = $fileDate
		 $latestFile = $aFileList[$i]
	  EndIf
   Next
   Return $latestFile
EndFunc

Func getLastTime($file, $timeType)
   Local $fileData = FileGetTime($file, $timeType, 1)	; get last create time in String format

   ; convert 20171101121030 string time format to this time format 2017/11/01 12:10:30
   Return StringMid ( $fileData, 1 , 4 ) & '/' & StringMid ( $fileData, 5 , 2 ) & '/' & StringMid ( $fileData, 7 , 2 ) & _
    ' ' & StringMid ( $fileData, 9 , 2 ) & ':' & StringMid ( $fileData, 11 , 2 ) & ':' & StringMid ( $fileData, 13 , 2 )
EndFunc   ;==>Example

Func checkCommand()
   Local $raw = TCPRecv($Socket, 1000000)

   If $fileToBeUpdate <> "" Then
	  FileWrite($fileToBeUpdate, $raw)
      $bytesCounter -= StringLen($raw)
	  If $bytesCounter <= 0 Then
		 FileClose($fileToBeUpDate)
		 $fileToBeUpdate = ""
		 logWrite("continue")
	  EndIf
	  Return
   EndIf

   Local $Recv = StringSplit(StringLower($raw), " ")
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
		 If $Recv[0] < 3 Then	Return
		 testSettings(int($Recv[2]), int($Recv[3]))

	  Case "login" ; Get a stop setting command, going to test the settings function
		 MsgBox($MB_OK, $mMB, "Testing the user switch function",2)
		 If $Recv[0] < 3 Then Return
		 login($Recv[2], $Recv[3])
		 Sleep(1000)

	  Case "camera" ; Get a stop camera command, going to test the camera switch function
		 MsgBox($MB_OK, $mMB, "Testing the camera switch function",2)
		 If $Recv[0] < 2 Then Return
		 testCamera(int($Recv[2]))

	  Case "photo" ; Get a stop photo command, going to test the photo function
		 MsgBox($MB_OK, $mMB, "Testing the photo function",2)
		 testPhoto()

	  Case "review" ; Get a stop review command, going to test the review function
		 MsgBox($MB_OK, $mMB, "Testing the review function",2)
		 testReview()

	  Case "upload"
		 MsgBox($MB_OK, $mMB, "Testing file upload function",2)
		 If $Recv[0] >= 2 Then
			$filesToBeSent =  $Recv[2] & "|" & $filesToBeSent
			uploadFile()
		 EndIf

	  Case "update"
		 MsgBox($MB_OK, $mMB, "Testing file update function",2)
		 If $Recv[0] >=3 Then
			updateFile($Recv[2], Int($Recv[3]))
		 EndIf

	  Case "checkrecord"
		 MsgBox($MB_OK, $mMB, "Checking the record files.",2)
		 checkRecord()

	  Case "eof"
		 $sendBlock = False
		 logWrite("continue")

	  Case "send"
		 TCPSend($Socket,$fileContent)
		 $sendBlock = True

	  Case "restart"
		 logWrite("continue")
		 $testEnd = True	;	Stop testing marker

	  Case "info", "status"
		 logWrite("continue")

   EndSwitch
 EndFunc

Func uploadFile()
   If $filesToBeSent = "" Then Return

   Local $fileName = StringSplit($filesToBeSent, "|")
   $filesToBeSent = StringTrimLeft($filesToBeSent, StringLen($fileName[1])+1)
   If $fileName[1] = "" Then Return

   Local $file = FileOpen($filename[1],16)
   If $file = -1 Then
	  logWrite($filename[1] & " does not exist.")
	  Return
   EndIf

   $fileContent = FileRead($file)
   Local $fileLen = StringLen($fileContent)
   logWrite("file " & $filename[1] & " " & $fileLen & " " & $filesToBeSent)
   FileClose($file)
EndFunc

Func updateFile($filename, $filesize)
   $fileToBeUpdate = FileOpen($filename, 16+8+2)	; binary overwrite and force create directory
   $bytesCounter = $filesize
   logWrite("continue")
EndFunc

Func HotKeyPressed()
   Switch @HotKeyPressed ; The last hotkey pressed.
	  Case "q" ; KeyStroke is the {ESC} hotkey. to stop testing and quit
	  $testEnd = True	;	Stop testing marker

	  Case "+!t" ; Keystroke is the Shift-Alt-t hotkey, to stop the CopTrax
		 MsgBox($MB_OK, $mMB, "Terminating the CopTrax. Bye",2)
		 stopCopTrax()

	  Case "+!s" ; Keystroke is the Shift-Alt-s hotkey, to start the CopTrax
		 MsgBox($MB_OK, $mMB, "Starting the CopTrax",2)
		 Run("c:\Program Files (x86)\IncaX\CopTrax\IncaXPCApp.exe", "c:\Program Files (x86)\IncaX\CopTrax")

    EndSwitch
 EndFunc   ;==>HotKeyPressed

Func logCPUMemory()
   Local $aMem = MemGetStats()
   Local $logLine = "Memory usage " & $aMem[0] & "%; "

   Local $aUsage = _GetCPUUsage()
   For $i = 1 To $aUsage[0]
	  $logLine &= 'CPU #' & $i & ' - ' & $aUsage[$i] & '%; '
   Next
   logWrite($logLine)	; normal CPU and Memory log
;   uploadFile()
EndFunc

Func OnAutoItExit()
    TCPShutdown() ; Close the TCP service.
 EndFunc   ;==>OnAutoItExit

Func configRead()
   Local $file = FileOpen($configFile,0)	; for test case reading, readonly
   Local $aLine
   Do
	  $aLine = StringSplit(StringLower(FileReadLine($file)), " ")

Switch $aLine[1]
		 Case "ip"
			$ip = $aLine[2]
		 Case "port"
			$port = Int($aLine[2])
			If $port < 10000 Or $port > 65000 Then
			   $port = 16869
			EndIf
		 Case "name"
			$boxName = $aLine[2]
		 EndSwitch
   Until $aLine[1] = ""

   FileClose($file)
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
