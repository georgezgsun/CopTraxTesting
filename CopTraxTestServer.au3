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

Global Const $max_connections = 10	; define the max client numbers
Global $testCommands = ""	; globally store the commands in test case
Local $ipServer = @IPAddress1
Local $port = 16869
Global $workDir = "C:\CopTraxTest\"

TCPStartup() ; Start the TCP service.
OnAutoItExitRegister("OnAutoItExit")	; Register OnAutoItExit to be called when the script is closed.
Global $TCPListen = TCPListen ($ipServer, $port, $max_connections)

Local $testCaseFile = $workDir & "test_case.txt"
readTestCase($testCaseFile);

MsgBox($MB_OK, "CopTrax Remote Test Server", "The test cases shall be in " & $testCaseFile & @CRLF & "The server is " & $ipServer & ":" & $port, 5)

If $testCommands = "" Then
   MsgBox($MB_OK, "CopTrax Remote Server", "Cannot read " & $testCaseFile & ".",5)
   TCPShutdown() ; Close the TCP service.
   Exit
Else
   ConsoleWrite("Test case is: " & $testCommands & @CRLF)
EndIf


Dim $Sockets[$max_connections + 1], $logFiles[$max_connections + 1], $commands[$max_connections + 1]
Dim $commandTimers[$max_connections + 1], $connectionTimers[$max_connections + 1], $transFiles[$max_connections + 1]

Local $i
For $i = 0 To $max_connections
   $Sockets[$i] = 0
Next

Global $hTimer = TimerInit()	; global timer handle
While 1
   _Accept_Connection()	; accept new client's connection requist

   Local $i, $Recv
   Local $currentTime = TimerDiff($hTimer)	; get current timer elaspe
   For $i = 1 To $max_connections
	  If $Sockets[$i] <> 0 Then
		 $Recv = TCPRecv($Sockets[$i],1000000)
		 If $Recv <> "" Then
			processMsg($i, $Recv)
			$connectionTimers[$i] = $currentTime + 2000*60 ; renew the hear_rate check timer
		 EndIf

		 If $currentTime > $commandTimers[$i] Then	; check if it is time for next command
			nextTestCommand($i)	; get the new test command executed, the new timer is set in it
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
   FileClose($logFiles[$n])	; Close the log file
EndFunc

Func nextTestCommand($n)
   Local $newCommand = StringSplit(StringLower($commands[$n]), " ")
   Local $lengthCommand, $restCommand

   If $newCommand[0] = 0 Then 	; no command left to be precessed
	  logWrite($n, "All tests passed.")
	  closeConnection($n)
	  Return
   EndIf

   Local $currentTime = TimerDiff($hTimer)
   $commandTimers[$n] =  $currentTime + 1000;
   ;$connectionTimers[$n] = $currentTime + 2000*60	; reset the time out to be in next 2mins
   Switch $newCommand[1]	; process the new command
	  Case "record"
		 Local $min = int($newCommand[2])
		 Local $nn = int($newCommand[3])

		 $lengthCommand = StringLen($newCommand[1] & " " & $newCommand[2] & " " & $newCommand[3] & " ")
		 $restCommand = StringTrimLeft($commands[$n],$lengthCommand)
		 TCPSend($Sockets[$n], $newCommand[1])	; send new test command to client

		 if $nn > 1 Then
			$nn -= 1;
			$newCommand[3] = $nn
			$commands[$n] = "hold endrecord " & $newCommand[1] & " " & $newCommand[2] & " " & $newCommand[3] & " " & $restCommand
		 Else
			$commands[$n] = "hold " & $restCommand	; hold any new command from execting only after get a continue response from the client
		 EndIf
		 $commandTimers[$n] += $min * 60*1000;	; set the next command timer xx minutes later
		 logWrite($n, "(Server) Sent " & $newCommand[1] & " command to client. The stop record command will be sent in " & $min & " mins.")

	  Case "endrecord"
		 $lengthCommand = StringLen($newCommand[1] & " ")
		 $restCommand = StringTrimLeft($commands[$n],$lengthCommand)
		 TCPSend($Sockets[$n], $newCommand[1])	; send new test command to client
		 $commands[$n]= "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $commandTimers[$n] +=  60 * 1000;	; set the next command timer 1 min later
		 logWrite($n, "(Server) Sent " & $newCommand[1] & " command to client.")
		 ConsoleWrite($commands[$n] & @CRLF)

	  Case "camera", "review", "photo", "info", "status"
		 $lengthCommand = StringLen($newCommand[1] & " ")
		 $restCommand = StringTrimLeft($commands[$n],$lengthCommand)
		 TCPSend($Sockets[$n], $newCommand[1])	; send new test command to client
		 logWrite($n, "(Server) Sent " & $newCommand[1] & " command to client.")
		 $commands[$n] = "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $commandTimers[$n] += 5 * 1000;	; set the next command timer 10s later

	  Case "settings"
		 $lengthCommand = StringLen($newCommand[1] & " ")
		 $restCommand = StringTrimLeft($commands[$n],$lengthCommand)
		 TCPSend($Sockets[$n], $newCommand[1])	; send new test command to client
		 $commands[$n] = "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $commandTimers[$n] += 30 * 1000;	; set the next command timer half min later
		 logWrite($n, "(Server) Sent " & $newCommand[1] & " command to client.")

	  Case "upload", "update"
		 $lengthCommand = StringLen($newCommand[1] & " " & $newCommand[2] & " ")
		 $restCommand = StringTrimLeft($commands[$n],$lengthCommand)
		 TCPSend($Sockets[$n], $newCommand[1] & " " & $newCommand[2])	; send upload command to client
		 $commands[$n] = "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $commandTimers[$n] += 30 * 1000;	set the next command timer half min later
		 logWrite($n, "(Server) Sent " & $newCommand[1] & " " & $newCommand[2] & " command to client.")

		 If $newCommand[1] = "upload" Then
			transFiles[$n] = $workDir & "log\" & $newCommand[2]	; save the received files in log sub-folders
			FileOpen($transFiles[$n],16+1)	; open file for append write and in binary mode
		 ElseIf
			update($n, $newCommand[2])
		 EndIf

   EndSwitch
   ;ConsoleWrite($commands[$n] & @CRLF)
EndFunc

Func logWrite($n,$s)
   _FileWriteLog($logFiles[$n],$s)
EndFunc

Func readTestCase($fileName)
   Local $testFile = FileOpen($fileName,0)	; for test case reading, readonly
   Local $fileEnds = False
   Local $aLine
   Do
	  $aLine = StringSplit(StringLower(FileReadLine($testFile)), " ")

	  Switch $aLine[1]
		 Case "record"
			Local $min, $n
			if $aLine[0] < 2 Then
			   $min = 5
			   $n = 1
			ElseIf $aLine[0] < 3 Then
			   $n = 1
			   $min = int($aLine[2])
			Else
			   $min = int($aLine[2])
			   $n = int($aLine[3])
			EndIf

			If $min < 1 Then
			   $min = 1
			EndIf

			If $min > 120 Then
			   $min = 120
			EndIf

			If $n < 0 Then
			   $n = 1
			EndIf

			If $n > 10000 Then
			   $n = 10000
			EndIf

			$testCommands &= "record " & $min & " " & $n & " "
		 Case "camera", "review", "review ", "photo", "settings", "info", "upload", "status", "update"
			$testCommands &= $aLine[1] & " "
		 EndSwitch
   Until $aLine[1] = ""

   FileClose($testFile)
EndFunc

Func processMsg($n, $result)
   Local $msg = StringSplit(StringLower($result), " ")
   If $logFiles[$n] = "" Then
	  Local $filename = $workDir & "log\" & $msg[1] & ".log"
	  $logFiles[$n] = FileOpen($filename, 1)
	  $commandTimer = TimerDiff($hTimer) + 1000;
	  Return
   EndIf

   Switch $msg[1]
	  Case "failed"
		 closeClientConnection($n)
	  Case "continue"
		 $commands[$n] = StringTrimLeft($commands[$n],5)	; unhold the test command by delete the first 5 letters from commands
	  Case "file"
		 $transFiles[$n] = $workDir & $msg[2]	; clear the file name
		 FileOpen(transFiles[$n], 16+1)	; get file name to be uploaded, and open for wtite append and binary mode
	  Case "done"
		 FileClose($transFiles[$n])	; get and save the screen capture file
		 $transFiles[$n] = ""	; clear the file name
   EndSwitch

   If $transFiles[$n] <> "" Then
	  FileWrite($transFiles[$n], $result)
   Else
	  If StringLen($result) < 10 Then
		 logWrite($n, "(Client) Got " & $result & " message from client.")	; write the returned results into the log file
	  Else
		 logWrite($n, "(Client) " & $result)	; write the returned results into the log file
	  EndIf
   EndIf
EndFunc

Func update($n, $fileName)
   Sleep(2000)	; wait 2s to start the file transfer
   $localFileName = "C:\CopTraxTest\Latest\" & $fileName

   TCPSend($Sockets[$n], FileRead(FileOpen($localFileName, 16)))
   FileClose($localFileName)
   logWrite($n, "(Server) Update " & $fileName & "on client.")
EndFunc

Func OnAutoItExit()
    TCPShutdown() ; Close the TCP service.
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
    Return
 EndFunc
