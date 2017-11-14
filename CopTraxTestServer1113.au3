;
; Test Server for CopTrax
; Version: 1.0
; Language:       AutoIt
; Platform:       Win8 or Win10
; Script Function:
;	Read test case from file
;   Listen for the target CopTrax box, waiting its powerup and connection to the server;
;   Send test commands from the test case to individual target(client);
;	Receive test results from the target(client), verify it passed or failed, log the result;
;	Drop the connection to the client when the test completed.
; Author: George Sun
; Nov., 2017
;

#include <Constants.au3>
#include <Timers.au3>
#include <File.au3>
#include <Date.au3>

Global Const $max_connections = 10	; define the max client numbers
Local $ipServer = @IPAddress1
Local $port = 16869
Global $workDir = "C:\CopTraxTest\"

TCPStartup() ; Start the TCP service.
OnAutoItExitRegister("OnAutoItExit")	; Register OnAutoItExit to be called when the script is closed.
Global $TCPListen = TCPListen ($ipServer, $port, $max_connections)

Local $testCaseFile = $workDir & "test_case.txt"
Global $testCommands = "hold " & readTestCase($testCaseFile); globally store the commands in test case
Global $boxID, $boxTitle

MsgBox($MB_OK, "CopTrax Remote Test Server", "The test cases shall be in " & $testCaseFile & @CRLF & "The server is " & $ipServer & ":" & $port, 5)

Dim $Sockets[$max_connections + 1], $logFiles[$max_connections + 1], $commands[$max_connections + 1]
Dim $commandTimers[$max_connections + 1], $connectionTimers[$max_connections + 1], $transFiles[$max_connections + 1]
Dim $byteCounter[$max_connections + 1], $fileToBeSent[$max_connections + 1]

Local $i
For $i = 0 To $max_connections
   $Sockets[$i] = 0
Next

Global $hTimer = TimerInit()	; global timer handle
Global $leakMsg = ""
While 1
   _Accept_Connection()	; accept new client's connection requist

   Local $i, $Recv
   Local $currentTime = TimerDiff($hTimer)	; get current timer elaspe
   For $i = 1 To $max_connections
	  If $Sockets[$i] <> 0 Then
		 $Recv = TCPRecv($Sockets[$i],1000000)
		 If $Recv <> "" Then
			processReply($i, $leakMsg & $Recv)
			$connectionTimers[$i] = $currentTime + 2000*60 ; renew the hear_rate check timer
		 EndIf

		 If $currentTime > $commandTimers[$i] Then	; check if it is time for next command
			parseCommand($i)	; get the new test command executed, the new timer is set in it
		 EndIf

		 If $currentTime > $connectionTimers[$i] Then	; test if the client is alive
			logWrite($i, "(Server) Connection to client lost.")
			closeConnection($i)
		 EndIf
	  EndIf
   Next
   Sleep (100)
 WEnd

Exit

Func closeConnection($n)
   TCPCloseSocket($Sockets[$n])	; Close the TCP connection to the client
   $Sockets[$n] = 0	; clear the soket index
   $Sockets[0] -= 1 ; reduce the total number of connection
   Local $s = "==================================="
   $s &= $s & $s
   logWrite($n, $s)
   logWrite($n, " ")
   FileClose($logFiles[$n])	; Close the log file
EndFunc

Func parseCommand($n)
   Local $newCommand = popCommand($n)

   If $newCommand = "" Then 	; no command left to be precessed
	  logWrite($n, "All tests passed.")
	  closeConnection($n)
	  Return
   EndIf

   Local $currentTime = TimerDiff($hTimer)
   $commandTimers[$n] =  $currentTime + 5*1000;

   Local $nn, $mm
   Switch $newCommand	; process the new command
	  Case "record"
		 TCPSend($Sockets[$n], $newCommand)	; send new test command to client

		 $mm = int(popCommand($n))
		 $nn = int(popCommand($n))
		 if $nn > 1 Then
			$nn -= 1;
			pushCommand($n, "hold endrecord " & $newCommand & " " & $mm & " " & $nn)
		 Else
			pushCommand($n, "hold endrecord")	; hold any new command from executing only after get a continue response from the client
		 EndIf
		 $commandTimers[$n] += $mm * 60*1000	; set the next command timer xx minutes later
		 logWrite($n, "(Server) Sent " & $newCommand & " command to client. The stop record command will be sent in " & $mm & " mins.")

	  Case "endrecord"
		 TCPSend($Sockets[$n], $newCommand)	; send new test command to client
		 pushCommand($n, "hold")	; hold any new command from executing only after get a continue response from the client
		 $commandTimers[$n] +=  10 * 60 * 1000	; set the next command timer 10 mins later
		 logWrite($n, "(Server) Sent " & $newCommand & " command to client.")

	  Case "settings", "login"
		 $mm = popCommand($n)
		 $nn = popCommand($n)
		 TCPSend($Sockets[$n], $newCommand & " " & $mm & " " & $nn)	; send new test command to client
		 pushCommand($n, "hold")	; hold any new command from executing only after get a continue response from the client
		 logWrite($n, "(Server) Sent " & $newCommand & " " & $mm & " " & $nn & " command to client.")

	  Case "camera"
		 $nn = popCommand($n)
		 TCPSend($Sockets[$n], $newCommand & " " & $nn)	; send new test command to client
		 pushCommand($n, "hold")	; hold any new command from executing only after get a continue response from the client
		 logWrite($n, "(Server) Sent " & $newCommand & " " & $nn & " command to client.")

	  Case "pause"
		 $nn = popCommand($n)
		 $commandTimers[$n] +=  Int($nn) * 60 * 1000	; set the next command timer 10 mins later
		 logWrite($n, "(Server) Pause for " & $nn & " minutes.")

	  Case "review", "photo", "info", "status", "eof", "checkrecord", "restart"
		 TCPSend($Sockets[$n], $newCommand)	; send new test command to client
		 pushCommand($n, "hold")	; hold any new command from executing only after get a continue response from the client
		 logWrite($n, "(Server) Sent " & $newCommand & " command to client.")

	  Case "upload"
		 Local $fileName = popCommand($n)
		 $newCommand &= " " & $fileName
		 TCPSend($Sockets[$n], $newCommand)	; send new test command to client
		 logWrite($n, "(Server) Sent " & $newCommand & " command to client.")
		 pushCommand($n, "hold")	; hold any new command from executing only after get a continue response from the client

	  Case "update"
		 Local $fileName = popCommand($n)
		 Local $netFileName = StringSplit($fileName, "\")
		 Local $sourceFileName = $workDir & "latest\" & $netFileName[$netFileName[0]]
		 Local $file = FileOpen($sourceFileName,16)	; open file for read only in binary mode
		 $fileToBeSent[$n] = FileRead($file)
		 FileClose($file)
		 $newCommand &= " " & $fileName & " " & StringLen($fileToBeSent[$n])
   		 TCPSend($Sockets[$n], $newCommand)	; send new test command to client
		 logWrite($n, "(Server) Sent " & $newCommand & " command to client.")
		 logWrite($n, "(Server) Sending " & $sourceFileName & " in server to update " & $fileName & " in client.")
		 pushCommand($n, "hold send hold")	; hold any new command from executing only after get a continue response from the client

	  Case "send"
		 TCPSend($Sockets[$n], $fileToBeSent[$n])	; send file to client
		 logWrite($n,"(Server) File sent to client.")

	  Case "hold"
		 pushCommand($n, "hold")	; the hold command can only be released by receive a contiue reply from the client

   EndSwitch
;   logWrite($n, "Remains test commands: " & $commands[$n])
EndFunc

Func logWrite($n,$s)
   _FileWriteLog($logFiles[$n],$s)
EndFunc

Func readTestCase($fileName)
   Local $testFile = FileOpen($fileName,0)	; for test case reading, readonly
   Local $fileEnds = False
   Local $aLine, $commands
   Do
	  $aLine = StringSplit(StringLower(FileReadLine($testFile)), " ")

	  Switch $aLine[1]
		 Case "record", "settings", "login"
	  		Local $m, $n
			If $aLine[0] < 2 Then
			   $m = "1"
			Else
			   $m = StringLeft($aLine[2],5)
			EndIf

			If $aLine[0] < 3 Then
			   $n = "1"
			Else
			   $n = StringLeft($aLine[3],8)
			EndIf

			$commands &= $aLine[1] & " " & $m & " " & $n & " "

		 Case "camera", "upload", "update"
	  		Local $m
			If $aLine[0] < 2 Then
			   $m = "1"
			Else
			   $m = $aLine[2]
			EndIf
			$commands &= $aLine[1] & " " & $m & " "

		 Case "review", "photo", "settings", "info", "status", "checkrecord", "restart"
			$commands &= $aLine[1] & " "
		 EndSwitch
   Until $aLine[1] = ""

   FileClose($testFile)
   Return $commands
EndFunc

Func processReply($n, $reply)
   Local $msg = StringSplit(StringLower($reply), " ")
   Local $len
   If $transFiles[$n] <> "" Then	; This indicates the coming message shall be saved in file
	  FileWrite($transFiles[$n], $reply)
	  $len = StringLen($reply)
	  logWrite($n, "(Server) Received " & $len & " bytes, write them to file.")
	  $byteCounter[$n] -= $len

	  If $byteCounter[$n] <= 0 Then
		 FileClose($transFiles[$n])	; get and save the file
		 $transFiles[$n] = ""	;clear the flag when file transfer ends
		 popCommand($n)
		 TCPSend($Sockets[$n], "eof")	; send "eof" command to client
		 logWrite($n,"(Server) Sent eof command to client. The remained test commands are " & $commands[$n])
	  EndIf
	  Return
   EndIf

   If StringLen($reply) < 10 Then
	  logWrite($n, "(Client) Sent " & $reply & " message to server. ")	; write the returned results into the log file
   Else
	  logWrite($n, "(Client) " & $reply)	; write the returned results into the log file
   EndIf

   Switch $msg[1]
   Case "failed"
		 popCommand($n)	; unhold the test command by delete the first 5 letters from commands
;		 closeConnection($n)

	  Case "continue"
		 popCommand($n)	; unhold the test command by delete the first 5 letters from commands
		 ConsoleWrite($commands[$n] & @crlf)

	  Case "file"
		 Local $fileName = $msg[2]
		 Local $len =  Int($msg[3])
		 Local $netFileName = StringSplit($fileName, "\")
		 Local $destFileName = $workDir & "log\" & $netFileName[$netFileName[0]]
		 logWrite($n, "(Client) " & $fileName & " from client is going to be saved as " & $destFileName & " in server.")
		 logWrite($n, "(Client) Total " & $len & " bytes need to be stransfered.")
		 $transFiles[$n] = FileOpen($destFileName,16+2)	; open file for append write in binary mode
		 $byteCounter[$n] = $len
		 pushCommand($n,"hold")
		 TCPSend($Sockets[$n], "send")	; send "send" command to client
		 logWrite($n, "(Server) sent send command to client.")

	  Case "name"
		 Local $filename = $workDir & "log\" & $msg[2] & ".log"
		 $logFiles[$n] = FileOpen($filename, 1+8) ; open log file for append write in text mode
		 $boxID = $msg[2]	; for the boxID
		 $boxTitle = $msg[3]	; for the CopTrax App Title
		 Local $clientDate = $msg[4] & " " & $msg[5]
		 Local $latestDate = getLastTime($workDir & "latest\CopTraxTestClient.exe",0)

		 $filename = $workdir & $boxID & ".txt"
		 Local $iCommands = readTestCase($filename)

		 If $iCommands <> "" Then
			$commands[$n] = $iCommands	; Stores the whole test case that will let the target machine run. When empty indicates that the target has completed all the test
		 Else
			popCommand($n)
		 EndIf
;		 If _DateDiff("s", $clientDate, $latestDate) <> 0 Then
;			$commands[$n] = "update c:\coptraxtest\tmp\coptraxtestclient.exe checkrecord restart info"
;		 EndIf

		 Local $s = "==================================="
		 $s &= $s & $s
		 logWrite($n, " ")
		 logWrite($n, $s)
		 logWrite($n, " Automation test for CopTrax DVR box " & $boxID)
		 logWrite($n, " Current user and App version " & $boxTitle)
		 logWrite($n, " The test case is : ")
		 logWrite($n, $commands[$n])
		 logWrite($n, $s)
		 logWrite($n, "(Client) " & $reply)	; write the returned results into the log file
;		 logWrite($n, "(Client) The current automation tester is of date " & $clientDate)
;		 logWrite($n, "(Server) The latest automation tester is of date " & $latestDate & ". The time difference is " & _DateDiff("s", $clientDate, $latestDate))

   EndSwitch
EndFunc

Func getLastTime($file, $timeType)
   Local $fileData = FileGetTime($file, $timeType, 1)	; get last create time in String format

   ; convert 20171101121030 string time format to this time format 2017/11/01 12:10:30
   Return StringMid ( $fileData, 1 , 4 ) & '/' & StringMid ( $fileData, 5 , 2 ) & '/' & StringMid ( $fileData, 7 , 2 ) & _
    ' ' & StringMid ( $fileData, 9 , 2 ) & ':' & StringMid ( $fileData, 11 , 2 ) & ':' & StringMid ( $fileData, 13 , 2 )
EndFunc   ;==>Example

Func OnAutoItExit()
    TCPShutdown() ; Close the TCP service.
   Local $i
   For $i = 0 To $max_connections
	  If $logFiles[$i] <> 0 Then
		 FileClose($logFiles[$i])
		 $logFiles[$i] = 0
	  EndIf
   Next

EndFunc   ;==>OnAutoItExit

Func _Accept_Connection ()
   If $Sockets[0] = $max_connections Then Return
   ;Makes sure no more Connections can be made.
   Local $Accept = TCPAccept ($TCPListen)     ;Accepts incomming connections.
   If $Accept = -1 Then Return

   Local $currentTime = TimerDiff($hTimer)
   For $i = 1 To $max_connections
	  If $Sockets[$i] = 0 Then	;Find the first open socket.
		 $Sockets[$i] = $Accept	;assigns that socket the incomming connection.
		 $logFiles[$i] = ""	; Clear the client name for future updating from the client
		 $commands[$i] = $testCommands	; Stores the whole test case that will let the target machine run. When empty indicates that the target has completed all the test
		 $commandTimers[$i] = $currentTime + 1000	; Set command timer to be 1s later
		 $connectionTimers[$i] = $currentTime + 2000*60	; Set connection lost timer to be 2mins later
		 $Sockets[0] += 1   ;adds one to the Socket list.
		 Return
	  EndIf
   Next
 EndFunc

Func popCommand($n)
   Local $newCommand = StringSplit(StringLower($commands[$n]), " ")
   If $newCommand[0] > 1 Then
	  Local $lengthCommand = StringLen($newCommand[1] & " ")
	  $commands[$n] = StringTrimLeft($commands[$n],$lengthCommand)
	  return $newCommand[1]
   Else
	  return ""
   EndIf
EndFunc

Func pushCommand($n, $newCommand)
   $commands[$n] = $newCommand & " " & $commands[$n]
EndFunc
