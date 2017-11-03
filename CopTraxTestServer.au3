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
Local $port = 16869;

Global $logFile = "C:\CopTraxTest\remote_end_test" & @MON & @MDAY & ".log"
Local $testCaseFile = "C:\CopTraxTest\test_case.txt"

MsgBox($MB_OK, "CopTrax Remote Test Server", "The test cases shall be in " & $testCaseFile & @CRLF & "The server is " & $ipServer & ":" & $port, 5)

TCPStartup() ; Start the TCP service.
OnAutoItExitRegister("OnAutoItExit")	; Register OnAutoItExit to be called when the script is closed.
Global $TCPListen = TCPListen ($ipServer, $port, $max_connections)

readTestCase($testCaseFile);
If $testCommands = "" Then
   MsgBox($MB_OK, "CopTrax Remote Server", "Cannot read " & $testCaseFile & ".",5)
   TCPShutdown() ; Close the TCP service.
   Exit
Else
   ConsoleWrite("Test case is: " & $testCommands & @CRLF)
EndIf

Dim $Socket_Data[$max_connections + 1][5]
;Socket_data Syntax
;$Socket_Data[0][0] = AMOUNT OF CURRENT CLIENTS
;$Socket_Data[1] = [client 1 connection, client 1 log file, test commands, timer_1up, heartratedue]
;$Socket_Data[2] = [client 2 connection, client 2 log, test commands, timer_2up, heartratedue]
;$Socket_Data[n] = [client n connection, client n log, test commands, timer_nup, heartratedue]
Local $i
For $i = 0 To $max_connections
   $Socket_Data[$i][0] = 0
Next

Global $hTimer = TimerInit()	; global timer handle
While 1
   _Accept_Connection()	; accept new client's connection requist

   Local $i, $Recv
   Local $currentTime = TimerDiff($hTimer)	; get current timer elaspe
   For $i = 1 To $max_connections
	  If $Socket_Data[$i][0] <> 0 Then
		 $Recv = TCPRecv($Socket_Data[$i][0],1000000)
		 If $Recv <> "" Then
			ConsoleWrite($Recv & @crlf)
			processTestResult($i, $Recv)
			$Socket_Data[$i][4] += 2000*60 ; renew the hear_rate check timer
		 EndIf

		 If $currentTime > $Socket_Data[$i][3] Then	; test if it is time for next command
			nextTestCommand($i)	; get the new test command executed, the new timer is set in it
		 EndIf

		 If $currentTime > $Socket_Data[$i][4] + 100000 Then	; test if the client is alive
			logWrite($i, "Connection to server lost.")
			logWrite($i, $Socket_Data[$i][0] & " " & $Socket_Data[$i][1] & " " &$Socket_Data[$i][2] & " " & $Socket_Data[$i][3] & " " & $Socket_Data[$i][4])
			closeClientConnection($i)
		 EndIf
	  EndIf
   Next
   Sleep (100)
 WEnd

Exit

Func closeClientConnection($n)
   TCPCloseSocket($Socket_Data[$n][0])	; Close the TCP connection to the client
   $Socket_Data[$n][0] = 0	; clear the soket index
   $Socket_Data[0][0] -= 1 ; reduce the total number of connection
   FileClose($Socket_Data[$n][1])	; Close the log file
EndFunc


Func nextTestCommand($n)
   Local $newCommand = StringSplit($Socket_Data[$n][2], " ")
   Local $lengthCommand, $restCommand

   If $newCommand[0] = 0 Then 	; no command left to be precessed
	  logWrite($n, "All tests passed.")
	  closeClientConnection($n)
	  Return
   EndIf

   $Socket_Data[$n][3] = TimerDiff($hTimer) + 1000;
   $Socket_Data[$n][4] = TimerDiff($hTimer) + 1000;
   Switch $newCommand[1]	; process the new command
	  Case "record"
		 Local $min = int($newCommand[2])
		 Local $nn = int($newCommand[3])

		 $lengthCommand = StringLen($newCommand[1] & " " & $newCommand[2] & " " & $newCommand[3] & " ")
		 $restCommand = StringTrimLeft($Socket_Data[$n][2],$lengthCommand)
		 TCPSend($Socket_Data[$n][0], $newCommand[1])	; send new test command to client

		 if $nn > 1 Then
			$nn -= 1;
			$newCommand[3] = $nn
			$Socket_Data[$n][2] = "hold endrecord " & $newCommand[1] & " " & $newCommand[2] & " " & $newCommand[3] & " " & $restCommand
		 Else
			$Socket_Data[$n][2] = "hold " & $restCommand	; hold any new command from execting only after get a continue response from the client
		 EndIf
		 $Socket_Data[$n][3] += $min * 60*1000;	; set the next command timer xx minutes later
		 logWrite($n, "Test command (" & $newCommand[1] & ") sent from the server. And the record will be stopped in " & $min & " mins.")

	  Case "endrecord"
		 $lengthCommand = StringLen($newCommand[1] & " ")
		 $restCommand = StringTrimLeft($Socket_Data[$n][2],$lengthCommand)
		 TCPSend($Socket_Data[$n][0], $newCommand[1])	; send new test command to client
		 $Socket_Data[$n][2] = "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $Socket_Data[$n][3] +=  60 * 1000;	; set the next command timer 1 min later
		 logWrite($n, "Test command: (" & $newCommand[1] & ") sent from the server.")

	  Case "camera", "review", "photo"
		 $lengthCommand = StringLen($newCommand[1] & " ")
		 $restCommand = StringTrimLeft($Socket_Data[$n][2],$lengthCommand)
		 TCPSend($Socket_Data[$n][0], $newCommand[1])	; send new test command to client
		 logWrite($n, "Test command (" & $newCommand[1] & ") sent from the server.")
		 $Socket_Data[$n][2] = "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $Socket_Data[$n][3] += 10 * 1000;	; set the next command timer 10s later

	  Case "settings"
		 $lengthCommand = StringLen($newCommand[1] & " ")
		 $restCommand = StringTrimLeft($Socket_Data[$n][2],$lengthCommand)
		 TCPSend($Socket_Data[$n][0], $newCommand[1])	; send new test command to client
		 $Socket_Data[$n][2] = "hold " & $restCommand 	; hold any new command from execting only after get a continue response from the client
		 $Socket_Data[$n][3] += 30 * 1000;	; set the next command timer half min later
		 logWrite($n, "Test command (" & $newCommand[1] & ") sent from the server.")
   EndSwitch
   ConsoleWrite($Socket_Data[$n][2] & " " & $Socket_Data[$n][3] & @CRLF)
EndFunc

Func logWrite($n,$s)
   _FileWriteLog($Socket_Data[$n][1],$s)
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
		 Case "camera", "review", "review ", "photo", "settings", "info"
			$testCommands &= $aLine[1] & " "
		 EndSwitch
   Until $aLine[1] = ""

   FileClose($testFile)
EndFunc

Func processTestResult($n, $result)
   logWrite($n, "Got message from the client box (" & $result & ").")	; write the returned results into the log file

   Switch $result
	  Case "Failed"
		 closeClientConnection($n)
	  Case "Continue"
		 unholdTestCommand($n)	; when current test instruction get executed, we unhold the next test command
	  Case "Screen"
		 saveScreenCapture($n)	; get and save the screen capture file
   EndSwitch
EndFunc

Func unholdTestCommand($n)
   $Socket_Data[$n][2] = StringTrimLeft($Socket_Data[$n][2],5)	; unhold the test command by delete the first 5 letters from commands
EndFunc

Func saveScreenCapture($n)
   Local $timeout = TimerDiff($hTimer) + 1000	; wait at most 1s for the client to send the screen capture filename
   Local $Recv
   Do
	  $Recv = TCPRecv($Socket_Data[$i][0],1000000)
	  Sleep(100)
   Until ($Recv <> "") Or (TimerDiff($hTimer) > $timeout)
   Local $fileJPG = $Recv ; use the client sent file name
   logWrite($n, " Save the captured screen image to " & $fileJPG)
   $fileJPG = FileOpen($fileJPG)

   $timeout += 1000	; wait at most another 1s for the client to send the screen capture file
   Do
	  $Recv = TCPRecv($Socket_Data[$i][0],1000000)
	  Sleep(100)
   Until ($Recv <> "") Or (TimerDiff($hTimer) > $timeout)
   FileWrite($fileJPG, $Recv)
   FileClose($fileJPG)
EndFunc

Func OnAutoItExit()
    TCPShutdown() ; Close the TCP service.
EndFunc   ;==>OnAutoItExit

Func _Accept_Connection ()
   If $Socket_Data[0][0] = $max_connections Then Return
   ;Makes sure no more Connections can be made.
   Local $Accept = TCPAccept ($TCPListen)     ;Accepts incomming connections.
   If $Accept = -1 Then Return

   Local $i = 0;
   Local $Recv;
   Local $timeout = TimerDiff($hTimer) + 1000	; wait at most 1s for the client to send its name
   Do
	  $Recv = TCPRecv ($Accept, 1000000)
   Until ($Recv <> '') Or (TimerDiff($hTimer) > $timeout)
   If $Recv = "" Then Return
   ConsoleWrite($Recv & @crlf)

   For $i = 1 To $max_connections
	  If $Socket_Data[$i][0] = 0 Then	;Find the first open socket.
		 $Socket_Data[$i][0] = $Accept	;assigns that socket the incomming connection.
		 $Socket_Data[$i][1] = $Recv	; The client name and then test log file handle
		 $Socket_Data[$i][2] = $testCommands	; Stores the test case that will let the target machine run. empty indicates the target has completed all the test
		 $Socket_Data[$i][3] = $timeout+500	; Stores the test case that will let the target machine run. empty indicates the target has completed all the test
		 $Socket_Data[$i][4] = $timeout+1000	; Stores the test case that will let the target machine run. empty indicates the target has completed all the test

		 $Socket_Data[0][0] += 1   ;adds one to the Socket list.

		 $Socket_Data[$i][1] = FileOpen($Recv & "test.log",1)	; for log saving, appended write
		 Return
	  EndIf
    Next
    Return
 EndFunc
