#RequireAdmin

#pragma compile(FileVersion, 2.11.24.9)
#pragma compile(FileDescription, Automation test client)
#pragma compile(ProductName, AutomationTest)
#pragma compile(ProductVersion, 2.11)
#pragma compile(CompanyName, 'Lele & Ben International')
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
#include <Misc.au3>

_Singleton("Automation test client")	; Make sure only one instance can be run

HotKeySet("{Esc}", "HotKeyPressed") ; Esc to stop testing
HotKeySet("+!c", "HotKeyPressed") ; Manually send a continue reply
HotKeySet("+!t", "HotKeyPressed") ; Shift-Alt-t to stop CopTrax
HotKeySet("+!s", "HotKeyPressed") ; Shift-Alt-s, to start CopTrax

TCPStartup()
Global $ip =  TCPNameToIP("10.25.50.110")
Global $port = 16869
Global $Socket = -1
Global $boxID = "undefined"
Global $filesToBeSent = ""
Global $fileContent
Global $bytesCounter
Global $fileToBeUpdate = ""
Global $configFile = "C:\CopTraxTest\client.cfg"
_configRead()
OnAutoItExitRegister("OnAutoItExit")	; Register OnAutoItExit to be called when the script is closed.

Global $workDir = "C:\CopTraxTest\"
Global $testEnd = FileGetVersion($workDir & "CopTraxTestClient.exe") <> FileGetVersion($workDir & "tmp\CopTraxTestClient.exe")
Global $restart = False
$workDir = "C:\CopTraxTest\tmp\"

Global $mCopTrax = 0
Global $title = "CopTrax II is not up yet"
Global $userName = ""
Global Const $mMB = "CopTrax GUI Automation Test"

MsgBox($MB_OK, $mMB, "Automation testing start. Connecting to" & $ip & "..." & @CRLF & "Esc to quit", 2)

Global $hTimer = TimerInit()	; Begin the timer and store the handler
Global $timeout =  TimerDiff($hTimer) + 1000*60
Global $chunkTime = 0
Global $sendBlock = False

AutoItSetOption ("WinTitleMatchMode", 2)
Global $mTitleName = "CopTrax II v"

If StringLower($boxID) = "tbd" Then
   _testSettings(0,10)
EndIf

While Not $testEnd
   If $mCopTrax = 0 Then
	  $mCopTrax = WinActivate($mTitleName)
	  If $mCopTrax <> 0 Then
		 $userName = _getUserName()
	  EndIf
   EndIf

   If $Socket < 0 Then
	  $Socket = TCPConnect($ip, $port)
	  If $Socket >= 0 Then
		 _logWrite("name " & $boxID & " " & $userName & " " & FileGetVersion($workDir & "CopTraxTestClient.exe") & " " & $title)
		 MsgBox($MB_OK, $mMB, "Connected to server",2)
	  EndIf
   Else
	  _listenNewCommand()
	  If  TimerDiff($hTimer) > $timeout Then
		 _logWrite("quit")		; log the CPU and memory usage every minute
		 $Socket = -1
		 $timeout = TimerDiff($hTimer) + 2000*60
	  EndIf
   EndIf
   Sleep(100)
WEnd

_logWrite("quit")
TCPShutdown() ; Close the TCP service.
FileClose($fileToBeUpdate)

If $restart Then
	Run($workDir & "restartclient.bat")	; restart the test client
	MsgBox($MB_OK, $mMB, "Restarting...",1)
Else
	MsgBox($MB_OK, $mMB, "Testing ends. Bye.",5)
EndIf

Exit

Func _getUserName()
   If $mCopTrax = 0 Then Return ""

   $title = WinGetTitle($mCopTrax) ;"CopTrax Status"
   Local $s = StringSplit($title, "[")
   Local $ss = StringSplit($s[2],"]")
   Return $ss[1]
EndFunc

Func _quitCopTrax()
   If Not _readyToTest() Then  Return False

   AutoItSetOption("SendKeyDelay", 200)
   MouseClick("",960,560)	; click on the info button
   Sleep(400)

   Local $mTitle = "Menu Action"
   If WinWaitActive($mTitle, "", 10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Cannot trigger the Info window. " & @CRLF,2)
	  _logWrite("Click on the info button failed.")
	  WinClose($mTitle)
	  Return False
   EndIf
   Sleep(100)

;   MouseClick("", 450, 80)	; click the About
   ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:1]")
   Sleep(500)
   Send("{DOWN 10}{ENTER}")	; choose the Administrator
   ControlClick($mTitle,"","Apply")

   Sleep(500)
   $mTitle = "Login"
   If WinWaitActive($mTitle, "", 10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Cannot trigger the Login window. " & @CRLF,2)
	  _logWrite("Click on Apply button to close the Login window failed.")
	  WinClose($mTitle)
	  Return False
   EndIf

   Send("135799{ENTER}")	; type the administator password
   MouseClick("", 500, 150)
   Return True
EndFunc

Func login($name, $password)
	If Not _readyToTest() Then  Return False

	AutoItSetOption("SendKeyDelay", 200)
	MouseClick("",960,560)	; click on the info button
	Sleep(400)

	Local $mTitle = "Menu Action"
	If WinWaitActive($mTitle,"",10) = 0 Then
		MsgBox($MB_OK, $mMB, "Cannot trigger the info window. " & @CRLF,2)
		_logWrite("Click to open info window failed.")
		WinClose($mTitle)
		Return False
	EndIf
	Sleep(100)

	ControlClick($mTitle,"","[CLASS:WindowsForms10.COMBOBOX.app.0.182b0e9_r11_ad1; INSTANCE:1]")
	Sleep(500)
	Send("s")	; choose switch Account
	ControlClick($mTitle,"","Apply")

	Sleep(500)
	Local $mTitle = "CopTrax - Login / Create Account"
	$mTitle = WinWaitActive($mTitle,"",10)
	If $mTitle = 0 Then
		MsgBox($MB_OK, "Test Alert", "Cannot trigger the CopTrax-Login/Create Account window. " & @CRLF,2)
		_logWrite("Click Apply button to trigger the CopTrax-Login/Create Account window failed.")
		Return False
	EndIf

	ControlSetText($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:4]", $name)
	Sleep(500)

	;ControlSetText($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:3]]", $password)
	ControlClick($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:3]]")
	Send($password)	; type the user password
	Sleep(500)
	;ControlSetText($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:2]", $password)
	ControlClick($mTitle, "", "[CLASS:WindowsForms10.EDIT.app.0.182b0e9_r11_ad1; INSTANCE:2]")
	Send($password)	; re-type the user password
	MouseClick("", 500, 230)

	Sleep(2500)
	Send("{ENTER}")
	ControlClick($mTitle, "", "Register")

	If WinWaitClose($mTitle,"",10) = 0 Then
		MsgBox($MB_OK, $mMB, "Clickon the Register button to close the window failed.",2)
		_logWrite("Click on the Register button to exit failed.")
		WinClose($mTitle)
		Return False
	EndIf

	Sleep(1000)

	$userName = _getUserName()
	If $userName <> $name Then
		_logWrite("Switch to new user failed. Current user is " & $userName)
		Return False
	EndIf

	Return True
EndFunc

Func _startRecord()
   If Not _readyToTest() Then  Return False

   _logWrite("Testing start record function.")

   MouseClick("", 960, 80)	; click on the button to start record
   Sleep(15000)	; Wait for 15sec for record begin recording
   If _checkRecordingFiles() Then	; check if the specified *.mp4 files appear or not
	  _logWrite("Recording start successfully.")
	  Return True
   Else
	  _logWrite("Recording failed to start.")
	  Return False
   EndIf
EndFunc

Func _endRecord()
   If Not _readyToTest() Then  Return False

   _logWrite("Testing stop record function.")
   MouseClick("", 960, 80)	; click again to stop record
   MouseMove(400,100)
   Sleep(1000)

   Local $mTitle = "Report Taken"
   If WinWaitActive($mTitle,"",15) = 0 Then
	  _logWrite("Click to stop record failed. ")
	  MsgBox($MB_OK,  $mMB, "Cannot trigger the end record function",2)
	  Return False
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
   MouseClick("", 670,90)

   ControlClick($mTitle,"","OK")
   Sleep(100)

   While WinWaitClose($mTitle,"",10) = 0
	  MsgBox($MB_OK,  $mMB, "Click on the OK button failed",2)
	  _logWrite("Click on the OK button to stop record failed. ")
	  WinClose($mTitle)
   WEnd

   Return True
EndFunc

Func _testSettings($pre, $chunk)
	If Not _readyToTest() Then  Return False

	_logWrite("Start settings function testing.")
	MouseClick("",960, 460)

	Local $mTitle = "CopTrax II Setup"
	Local $hWnd = WinWaitActive($mTitle, "", 10)
	If WinWaitActive($hWnd, "", 10) = 0 Then
		MsgBox($MB_OK, $mMB, "Cannot trigger the settings function.", 2)
		_logWrite("Click to trigger the settings function failed.")
		Return False
	EndIf

	ControlClick($hWnd, "", "Test")
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
	Sleep(1000)

	MouseClick("", 60, 120) ;"Hardware Triggers")
	Sleep(1000)
	ControlClick($hWnd, "", "Identify")
	Sleep(2000)

	Local $txt = StringTrimLeft(WinGetText("[ACTIVE]"), 2)
	_logWrite("The current box ID and firmware are " & $txt)
	$readTxt = StringSplit($txt, ",")
	Local $serialTxt =  StringSplit($readTxt[3], " ")
	Local $readID = StringStripWS($serialTxt[4],3)
;	_logWrite("The current box ID is " & $readID & ". The box ID in config file is " & $boxID)
;	_logWrite("The current box ID in binary is " & StringToBinary($readID) & ". The box ID in config file in binary is " & StringToBinary($boxID))
	If StringCompare($readID, $boxID) <> 0 Then
		_logWrite("Changed the box ID in config file.")
		$boxID = $readID
		_renewConfig()
	EndIf

	ControlClick("CopTrax", "", "OK")
	Sleep(200)

	MouseClick("", 60, 240) ;"Upload & Storage")
	Sleep(500)

	MouseClick("", 600,165)
	Sleep(500)
	Send("{BS 4}" & $chunk)
	Sleep(1000)
	MouseClick("", 650,100)

	ControlClick($hWnd, "", "Apply")
	Sleep(2000)

	If WinWaitClose($hWnd, "", 10) = 0 Then
		MsgBox($MB_OK, $mMB, "Click on the Apply button failed", 2)
		_logWrite("Click on the Apply button to quit settings failed.")
		WinClose($hWnd)
		Return False
	EndIf

	$chunkTime = $chunk
	Return True
EndFunc

Func _readyToTest()
   If $mCopTrax = 0 Then Return False

   If WinExists("Login") Then
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
	  _logWrite("Hold on! The CopTrax is not ready.")
	  Return False
   EndIf

   Return True
EndFunc

Func _testCameraSwitch($n)
   If Not _readyToTest() Then  Return False

   _logWrite("Begin Camera switch function testing.")

   _takeScreenCapture("Original Cam", $mCopTrax)

   MouseClick("",960,170)
   Sleep(1000)

   _takeScreenCapture("Switched Cam1", $mCopTrax)
   If $n >= 1 Then
	  MouseClick("", 200,170)	; click to switch camera
	  Sleep(1000)
	  _takeScreenCapture("Switched Cam2", $mCopTrax)
   EndIf

   If BitAND($n,1) = 0 Then
	  MouseClick("", 200,170)	; click to switch camera if n=2,4,6,...
	  Sleep(1000)
   EndIf

   Return True
EndFunc

Func _takeScreenCapture($cam, $hWnd)
    Local $screenFile = $boxID & Chr(Random(65,90,1)) & Chr(Random(65,90,1)) & Chr(Random(65,90,1)) & ".jpg"
	_logWrite("Captured " & $cam & " screen file " & $screenFile & " is on the way sending to server.")
	$screenFile = $workDir & $screenFile
	If _ScreenCapture_CaptureWnd($screenFile, $hWnd) Then
		$filesToBeSent =  $screenFile & "|" & $filesToBeSent
	EndIf

EndFunc

Func _testPhoto()
   If Not _readyToTest() Then Return False

   _logWrite("Begin Photo function testing.")
   MouseClick("", 960, 350);

   Local $hWnd = WinWaitActive("Information", "", 5)
   Sleep(2000)
   ControlClick($hWnd,"","OK")
   Sleep(200)

   If WinWaitClose($hWnd, "", 10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Clickon the OK button to close the Photo failed.",2)
	  _logWrite("Click on the OK button to quit Photo taking failed.")
	  WinClose($hWnd)
	  Return False
   EndIf

   Return True
EndFunc

Func _testRadar()
	If Not _readyToTest() Then Return False

	_logWrite("Begin RADAR function testing.")

	Local $radar0 = WinExists("RadarDisplay")
	MouseClick("", 55, 580)

	Local $hWnd = WinWaitActive("RadarDisplay", "", 10)
	If $hWnd <> 0 Then
		_takeScreenCapture("RADAR On", $hWnd)
	EndIf

	Sleep(5000)

	Return $radar0 <> WinExists("RadarDisplay")
EndFunc

Func _testReview()
   If Not _readyToTest() Then Return False

   _logWrite("Begin Review function testing.")

   MouseClick("", 960, 260);
   Local $hWnd = WinWaitActive("CopTrax | Video Playback", "", 10)
   Sleep(5000)
   WinClose($hWnd)
   Sleep(200)

   If WinWaitClose($hWnd, "", 10) = 0 Then
	  MsgBox($MB_OK, $mMB, "Click to close the playback window failed.",2)
	  _logWrite("Click to close the playback review function failed.")
	  Return False
   EndIf
   Return True
EndFunc

Func _logWrite($s)
   If $sendBlock Or $Socket < 0 Then Return
   TCPSend($Socket, $s & " ")
   Sleep(1000)
EndFunc

Func _checkRecordingFiles()
   local $aFileList = _FileListToArray(@MyDocumentsDir & "\CopTraxTemp","Rec_*.mp4", Default, True)
   If @error = 4 Then
	  Return False
   EndIf

   Return $aFileList[0] >= 1
EndFunc

Func _checkRecordedFiles()
   _logWrite("Begin to review the records to check the chunk time.")

   $userName = _getUserName()
   Local $month = ["","Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
   Local $path1 = @LocalAppDataDir & "\coptrax\" & $userName & "\" & @MDAY & "-" & $month[@MON] & "-" & @YEAR
   Local $path2 = $path1 & "\cam2"
   Local $fileTypes = ["*.*","*.wmv", "*.jpg", "*.gps", "*.txt", "*.rdr", "*.vm", "*.trax", "*.rp"]
   Local $latestFiles[9+9]
   _logWrite("The setup chunk time is " & $chunkTime & " minutes.")

   Local $i
   For	$i = 0 To 8
	  $latestFiles[$i] = _getLatestFile($path1, $fileTypes[$i])
	  $latestFiles[$i+9] = _getLatestFile($path2, $fileTypes[$i])
   Next

	Local $file0 = _getLatestFile($path1, "*.avi")
	Local $time0 = _readFilenameTime($file0)
	Local $time1 = _readFilenameTime($latestFiles[1])
	If $time0 > $time1 Then $latestFiles[1] = $file0
	$file0 = _getLatestFile($path2, "*.avi")
	$time0 = _readFilenameTime($file0)
	$time1 = _readFilenameTime($latestFiles[10])
	If $time0 > $time1 Then $latestFiles[10] = $file0

	$time0 = _readFilenameTime($latestFiles[0])	; $time0 is of format yyyymmddhhmmss
	$time1 = _readFilenameTime($latestFiles[9])
	If _getTimeDiff($time0,$time1) > 0 Then
		$time0 = $time1
	EndIf

	$file0 = _getLatestFile("C:\CopTrax-Backup", "*.avi")
	$time1 = _readFilenameTime($file0)

	_logWrite($path1 & " " & $time0)
	Local $fileName, $fileSize, $createTime
	Local $chk = True
	For $i = 1 To 17
		If $i = 9 Then
			_logWrite($path2)
			ContinueLoop
		EndIf

		$fileName = $latestFiles[$i]
		$fileSize = FileGetSize($fileName)
		$createTime = _readFilenameTime($fileName)

		Local $n = $i < 9 ? $i : $i-9
		If $fileSize > 10 Then
			_logWrite("Last " & $fileTypes[$n] & " was created at " & $createTime & " with size of " & $fileSize)
		EndIf

		If ($i = 1 Or $i = 2 Or $i = 3 Or $i = 10 Or $i = 11 Or $i=12) And (_getTimeDiff($createTime, $time0) > 3) Then
			_logWrite("Find critical file " & $fileTypes[$n] & " missed in records.")
			$chk = False	; return False when .gps or .wmv or .jpg files were missing,
			If ($i = 1 Or $i = 10) And Abs(_getTimeDiff($time1, $time0)) < 3 Then
				_logWrite("Find " & $file0 & " in backup folder.")
			EndIf
		EndIf
	Next

	Local $chunk1 = _getChunkTime($latestFiles[1])
	Local $chunk2 = _getChunkTime($latestFiles[10])
	_logWrite("For the latest *.wmv or *.avi, the chunk time is " & $chunk1 & " and " & $chunk2 & " seconds.")
   If $chunk1 > $chunkTime*60 + 30 Then $chk = False
   If $chunk2 > $chunkTime*60 + 30 Then $chk = False

   Return $chk
EndFunc

Func _getLatestFile($path,$type)
    ; List the files only in the directory using the default parameters.
    Local $aFileList = _FileListToArray($path, $type, 1, True)

    If @error <> 0 Then Return ""

	Local $i, $latestFile, $date0 = "00000000000000", $fileDate
	For $i = 1 to $aFileList[0]
		Local $fileDate = _readFilenameTime($aFileList[$i])	; get last create time in String format
		if _getTimeDiff($fileDate, $date0) < 0 Then
			$date0 = $fileDate
			$latestFile = $aFileList[$i]
		EndIf
	Next
	Return $latestFile
EndFunc

Func _readFilenameTime($file)
   Local $fileData = StringSplit($file, "\")
   Local $netFilename = $fileData[$fileData[0]]	; get net file name without path and extension
   If StringLen($netFilename) < 10 Then Return "00000000000000"
   ; convert ddmmyyyyhhmmss to yyyymmddhhmmss
   Return StringMid($netFilename, 5 , 4 ) & StringMid($netFilename, 3 , 2) & StringMid($netFilename, 1 , 2) & StringMid($netFilename, 9 , 6)
EndFunc   ;==>Example

Func _getChunkTime($file)
   Local $createTime = _readFilenameTime($file)	; get create time from filename
   Local $modifiedTime = FileGetTime($file, 0, 1)	; get modified time from meta data

   Return _getTimeDiff($createTime,$modifiedTime)
EndFunc

Func _getTimeDiff($time1,$time2)
   If StringLen($time1 & $time2) < 26 Then Return 100000
   Local $t0 = (Number(StringMid($time2, 1, 8)) - Number(StringMid($time1, 1, 8)))*24*3600
   ; get the time difference in format yyyymmddhhmmss
   Local $t1 = Number(StringMid($time1, 9, 2)) * 3600 + Number(StringMid($time1, 11, 2)) * 60 + Number(StringMid($time1, 13, 2))
   Local $t2 = Number(StringMid($time2, 9, 2)) * 3600 + Number(StringMid($time2, 11, 2)) * 60 + Number(StringMid($time2, 13, 2))
   Return $t2 - $t1 + $t0
EndFunc

Func _listenNewCommand()
	Local $raw = TCPRecv($Socket, 1000000)
	If $raw = "" Then Return
	$timeout = TimerDiff($hTimer) + 1000*120

	If $fileToBeUpdate <> "" Then
		FileWrite($fileToBeUpdate, $raw)
		$len = StringLen($raw)
		_logWrite("Received " & $len & " bytes, write them to file.")
		$bytesCounter -= $len
		If $bytesCounter <= 10 Then
			FileClose($fileToBeUpdate)
			$fileToBeUpdate = ""
			_logWrite("continue")
		EndIf
		Return
	EndIf

	Local $Recv = StringSplit($raw, " ")
	Switch StringLower($Recv[1]) ; The last hotkey pressed.
		Case "runapp" ; get a stop command, going to stop testing and quit
			MsgBox($MB_OK, $mMB, "Re-starting the CopTrax",2)
			Run("c:\Program Files (x86)\IncaX\CopTrax\IncaXPCApp.exe", "c:\Program Files (x86)\IncaX\CopTrax")
			_logWrite("PASSED Start the CopTrax")

		Case "stopapp" ; get a stop command, going to stop testing and quit
			MsgBox($MB_OK, $mMB, "Stop CopTrax App",2)
			If _quitCopTrax() Then
				_logWrite("PASSED")
			Else
				_logWrite("FAILED to stop CopTrax II")
			EndIf

		Case "record" ; Get a record command. going to test the record function
			MsgBox($MB_OK, $mMB, "Testing the record function",2)
			If _startRecord() Then
				_logWrite("PASSED the test on start record function")
			Else
				_logWrite("FAILED to start record")
			EndIf

		Case "endrecord" ; Get a stop record command, going to end the record function
			MsgBox($MB_OK, $mMB, "Testing the end record function",2)
			If _endRecord() Then
				_logWrite("PASSED the test on end record function")
			Else
				_logWrite("FAILED to end record")
			EndIf

		Case "settings" ; Get a stop setting command, going to test the settings function
			MsgBox($MB_OK, $mMB, "Testing the settings function",2)
			If ($Recv[0] >= 3) And _testSettings(int($Recv[2]), int($Recv[3])) Then
				_logWrite("PASSED the test on new settings")
			Else
				_logWrite("FAILED the test on new settings")
			EndIf

		Case "login" ; Get a stop setting command, going to test the settings function
			MsgBox($MB_OK, $mMB, "Testing the user switch function",2)
			If ($Recv[0] >= 3) And login($Recv[2], $Recv[3]) Then
				_logWrite("PASSED the test on user switch function")
			Else
				_logWrite("FAILED to switch the user")
			EndIf

		Case "camera" ; Get a stop camera command, going to test the camera switch function
			MsgBox($MB_OK, $mMB, "Testing the camera switch function",2)
			If ($Recv[0] >= 2) And _testCameraSwitch(int($Recv[2])) Then
				_logWrite("PASSED the test on camera switch function")
			Else
				_logWrite("FAILED to switch the camera")
			EndIf

		Case "photo" ; Get a stop photo command, going to test the photo function
			MsgBox($MB_OK, $mMB, "Testing the photo function",2)
			If _testPhoto() Then
				_logWrite("PASSED the test to take photo")
			Else
				_logWrite("FAILED to take a photo")
			EndIf

		Case "review" ; Get a stop review command, going to test the review function
			MsgBox($MB_OK, $mMB, "Testing the review function",2)
			If _testReview() Then
				_logWrite("PASSED on the test of review function")
			Else
				_logWrite("FAILED to review")
			EndIf

		Case "radar" ; Get a stop review command, going to test the review function
			MsgBox($MB_OK, $mMB, "Testing the radar function",2)
			If _testRadar() Then
				_logWrite("PASSED on the test of show radar function")
			Else
				_logWrite("FAILED to trigger radar")
			EndIf

		Case "upload"
			MsgBox($MB_OK, $mMB, "Testing file upload function",2)
			If $Recv[0] >= 2 Then
				$filesToBeSent =  $Recv[2] & "|" & $filesToBeSent
				_uploadFile()
			EndIf
			_logWrite("PASSED file upload start")

		Case "update"
			MsgBox($MB_OK, $mMB, "Testing file update function",2)
			If ($Recv[0] >=3) And updateFile($Recv[2], Int($Recv[3])) Then
				_logWrite("Continue")
			Else
				_logWrite("FAILED to update " & $Recv[2])
			EndIf

		Case "synctime"
			MsgBox($MB_OK, $mMB, "Synchronizing client time to server",2)
			If ($Recv[0] >= 2) And _syncTime($Recv[2]) Then
				_logWrite("PASSED date and time synchronization")
			Else
				_logWrite("FAILED to sync date and time.")
			EndIf

		Case "synctmz"
			MsgBox($MB_OK, $mMB, "Synchronizing client timezone to server's",2)
			If ($Recv[0] >= 2) And _syncTMZ(StringMid($raw, 9)) Then
				_logWrite("PASSED timezone synchronization")
			Else
				_logWrite("FAILED to sync timezone to server's.")
			EndIf

		Case "checkrecord"
			MsgBox($MB_OK, $mMB, "Checking the record files.",2)
			If _checkRecordedFiles() Then
				_logWrite("PASSED the check on recorded files")
			Else
				_logWrite("Continue Warning on the check of recorded files")
			EndIf

		Case "eof"
			$sendBlock = False
			_logWrite("continue End of file stransfer")

		Case "send"
			TCPSend($Socket,$fileContent)
			$sendBlock = True

		Case "quit"
			_logWrite("continue")
			$testEnd = True	;	Stop testing marker
			$restart = False

		Case "restart"
			_logWrite("continue")
			$testEnd = True	;	Stop testing marker
			$restart = True

		Case "status"
			_logCPUMemory()
			_uploadFile()

		Case "info"
			_logWrite("continue function not programmed")

	EndSwitch
 EndFunc

Func _encodeSystemTime($datetime)
	Local $yyyy = Number(StringMid($datetime,1,4))
	Local $mon = Number(StringMid($datetime,5,2))
	Local $dd = Number(StringMid($datetime,7,2))
	Local $hh = Number(StringMid($datetime,9,2))
	Local $min = Number(StringMid($datetime,11,2))
	Local $ss = Number(StringMid($datetime,13,2))
	Return _Date_Time_EncodeSystemTime( $mon, $dd, $yyyy, $hh, $min, $ss )
EndFunc

Func _syncTime($datetime)
	Local $t0 = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	Local $tSysTime  = _encodeSystemTime($datetime)
	Local $result = _Date_Time_SetLocalTime($tSysTime)
	Local $t1 = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC

	_logWrite("Original local time is " & $t0)
	_logWrite("Trying set the date/time to : " & _Date_Time_SystemTimeToDateTimeStr($tSysTime))
	_logWrite("New local time is " & $t1)
	Return $result
EndFunc

Func _syncTMZ($tmz)
	Local $s = _Date_Time_GetTimeZoneInformation()
	_logWrite("Original time zone is " & $s[2] & ". Changing it to " & $tmz)
	RunWait('tzutil /s "' & $tmz & '"')
	Local $s = _Date_Time_GetTimeZoneInformation()
	_logWrite("Now current time zone is " & $s[2])
	Return $s[2] = $tmz
EndFunc

Func _uploadFile()
	If $filesToBeSent = "" Then Return

	Local $fileName = StringSplit($filesToBeSent, "|")
	$filesToBeSent = StringTrimLeft($filesToBeSent, StringLen($fileName[1])+1)
	If $fileName[1] = "" Then Return

	Local $file = FileOpen($filename[1],16)
	If $file = -1 Then
		_logWrite($filename[1] & " does not exist.")
		Return
	EndIf

	$fileContent = FileRead($file)
	Local $fileLen = StringLen($fileContent)
	Sleep(1000)
	_logWrite("file " & $filename[1] & " " & $fileLen & " " & $filesToBeSent)
	FileClose($file)
EndFunc

Func updateFile($filename, $filesize)
   $fileToBeUpdate = FileOpen($filename, 16+8+2)	; binary overwrite and force create directory
   $bytesCounter = $filesize
   Return True
EndFunc

Func HotKeyPressed()
   Switch @HotKeyPressed ; The last hotkey pressed.
		Case "{Esc}" ; KeyStroke is the {ESC} hotkey. to stop testing and quit
		$testEnd = True	;	Stop testing marker
		$restart = False

		Case "+!c"; KeyStroke is the {ESC} hotkey. to stop testing and quit
		   _logWrite("Continue")	;	Stop testing marker

		Case "+!t" ; Keystroke is the Shift-Alt-t hotkey, to stop the CopTrax
			MsgBox($MB_OK, $mMB, "Terminating the CopTrax. Bye",2)
			_quitCopTrax()

		Case "+!s" ; Keystroke is the Shift-Alt-s hotkey, to start the CopTrax
			MsgBox($MB_OK, $mMB, "Starting the CopTrax",2)
			Run("c:\Program Files (x86)\IncaX\CopTrax\IncaXPCApp.exe", "c:\Program Files (x86)\IncaX\CopTrax")

    EndSwitch
 EndFunc   ;==>HotKeyPressed

Func _logCPUMemory()
   Local $aMem = MemGetStats()
   Local $logLine = "PASSED Memory usage " & $aMem[0] & "%; "

   Local $aUsage = _GetCPUUsage()
   For $i = 1 To $aUsage[0]
	  $logLine &= 'CPU #' & $i & ' - ' & $aUsage[$i] & '%; '
   Next
   _logWrite($logLine)	; normal CPU and Memory log
;   _uploadFile()
EndFunc

Func OnAutoItExit()
   _logWrite("quit")
    TCPShutdown() ; Close the TCP service.
 EndFunc   ;==>OnAutoItExit

Func _configRead()
   Local $file = FileOpen($configFile,0)	; for test case reading, readonly
   Local $aLine
   Do
		$aLine = StringSplit(FileReadLine($file), " ")

		Switch StringLower($aLine[1])
			Case "ip"
				$ip = TCPNameToIP($aLine[2])
			Case "port"
				$port = Int($aLine[2])
				If $port < 10000 Or $port > 65000 Then
				$port = 16869
				EndIf
			Case "name"
				$boxID = StringStripWS($aLine[2], 3)
		 EndSwitch
   Until $aLine[1] = ""

   FileClose($file)
EndFunc

Func _RenewConfig()
   Local $file = FileOpen($configFile,2)	; Open config file in over-write mode
   FileWriteLine($file, "ip " & $ip)
   FileWriteLine($file, "port " & $port)
   FileWriteLine($file, "name " & $boxID & " ")
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
