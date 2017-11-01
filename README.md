# GUI Testing of CopTrax project
Here is the automating test GUI tools for CopTrax project. It may help the developer to locates the hidden bugs. It may also help the manufacturer to automatic test the new machines before delivery. There are three files in the tool set. All of them are self-executable files that do not need any installation. The first  named AutoTestCopTrax,v1031.exe. It shall sit in  the CopTrax gear box. The second file CopTraxRemoteTester.exe and the third test_case.txt shall sit in the remote PCs. All the executable files are coded in AutoIt language. The test_Case.txt contains a series of test instructions that will guide the GUI testing. The instructions are human readable and intuitive. They can be modified manually by any text editor. 

1.	Copy the AutoTestCopTrax,v1031.exe into the CopTrax machine to c:\CopTraxTest folder.
2.	Copy the CopTraxRemoteTester.exe and test_case.txt into the remote monitor machine to the folder c:\CopTraxTest;
3.	Run incaXPCApp.exe in the CopTrax machine and then start AutoTestCopTrax,v1031.exe. It will listen to the remote controller and execute the received test instructions.
4.	Run CopTrax-RD in the remote PC to connect to the CopTrax gear. Then start CopTraxRemoteTester.exe. The CopTraxRemoteTester.exe reads test_case.txt for test instructions, converts them into machine commands and sends them to the CopTrax gear.  
5.	The Log files will log the time stamp, the results either succeeds or failed, and the memory and CPU resources consumption.

Sample test_Case.txt like this:
camera    
review
camera
photo
settings
record 1 10
record 20 50

Each line contains a single command. The supported test commands are record, camera, review, photo, settings. The record command may have upto two numbers followed. The first indicates how many minutes the test need to record. The second indicates how many times this test may repeat. For example, “record 20 50” command means run the record for 50 times and each time record for 20 minutes.

