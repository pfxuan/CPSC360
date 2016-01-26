#!/bin/bash
echo "===| Testing Cases Summary |==="
echo "Test 0: Compilation"
echo "Test 1: Simple functionality test"
echo "Test 2: Timeout test"
echo "Test 3: CTRL-C test"
echo "Test 4: Multiple attempts test"
echo "Test 5: Multiple guessers test"
echo -e "Test 6: Documentation and coding style\n"


### Test 0: Compiling Test
echo "*** Test 0: Compiling ***"
tar xzf *-hw1.tar.gz  &> /dev/null;
make clean &> /dev/null; make depend &> /dev/null
warningcount=`make 2>&1 | grep -i "warning" | wc -l`
P0=0
if [ $warningcount -ge 1 ]; then
	echo -e "${warningcount} compiler warnings found!!!"
fi

if [ -e valueGuesser ] && [ -e valueServer ]; then
  echo -e "DEBUGGER: Test Result -> Passed.\n"
  echo -e "===> Test 0 score (10 points max): 10.0 <===\n\n\n"
  P0=10
else 
  echo -e "DEBUGGER: Test Result -> Failed!!!\n"
  echo -e "(Cannot find the execution file ./valueGuesser or ./valueServer)\n"
  echo -e "===> Test 0 score (10 points max): 0.0 <===\n\n\n"
  P0=0
fi
  
### "Killing previous zombie processors"
killall -q -9 valueGuesser &> /dev/null
killall -q -9 valueServer &> /dev/null
sleep 1

chkPort5000=`netstat -an | grep ':5000 ' | wc -l`
chkPort5001=`netstat -an | grep ':5001 ' | wc -l`
if [ $chkPort5000 -ge 1 ] || [ $chkPort5001 -ge 1 ]; then
  sleep 65
fi



### Test 1: Simple functionality test (50 points max) ###
#
# A simple test using password '123456'.
#
# 1) Start server
# 2) Start guesser 
# 3) Wait 5 secs 
# 4) Stop server
# 5) Check server log
##########################################
echo "*** Test 1: Simple functionality test ***"
exec 3< <(stdbuf -o0 ./valueServer -p 5001 -v 123456)
sleep 1
./valueGuesser -s 127.0.0.1 -p1 5001 -p2 9001 &> /dev/null & sleep 5; killall -q -9 valueGuesser &> /dev/null
sleep 5
killall -q -s SIGINT valueServer &> /dev/null; killall -q -9 valueServer &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+[1-9]' | wc -l)
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P1=0;P10=0;P11=0;P12=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 1 ]; then
	echo -e "DEBUGGER: get a correct result from server side (+50)."
  P10=50
else
	echo -e "DEBUGGER: can not correctly catch result from server side!"
  if [ $serverMsgRec -ge 1 ]; then
    echo "DEBUGGER: server only can receive messages (+30)."
    P11=30
  else 
    echo "DEBUGGER: server can not recieve messages!"
  fi
  if [ $serverClientIPs -ge 1 ]; then
    echo "DEBUGGER: server only can get IP addresses from clients (+20)."
    P12=20
  else 
    echo "DEBUGGER: server can not get IP addresses from clients!"
  fi
fi
P1=$[$P10+$P11+$P12]
echo -e "\n===> Test 1 score (50 points max): $P1 <===\n\n\n"


sleep 2


### Test 2: Timeout test (10 points max) ###
# 
# Test timeout for guesser by breaking server
# 
# 1) Start guesser
# 2) Wait 2 secs 
# 3) Start server
# 4) Wait 2 secs 
# 5) Stop server
# 6) Check server log
##########################################
echo "*** Test 2: Timeout test ***"
./valueGuesser -s 127.0.0.1 -p1 5002 -p2 9002 &> /dev/null &
sleep 2
exec 3< <(stdbuf -o0 ./valueServer -p 5002)
sleep 2
killall -q -s SIGINT valueServer &> /dev/null; killall -q -9 valueServer &> /dev/null
killall -q -9 valueGuesser &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P2=0;P20=0
if [ $serverClientIPs -ge 1 ]; then
	echo -e "DEBUGGER: get a correct result from server side (+10)."
  P20=10
else
	echo -e "DEBUGGER: can not correctly catch result from server side!"
fi
P2=$[$P20]
echo -e "\n===> Test 2 score (10 points max): $P2 <===\n\n\n"


sleep 2


### Test 3: CTRL-C test (10 points max) ###
# 
# Test state machine in server by issuing CTRL-C
# 
# 1) Start server
# 2) Start guesser 
# 3) Wait 5 secs 
# 4) Interrupt server
# 5) Stop guesser 
# 6) Check server log
##########################################
echo "*** Test 3: CTRL-C test ***"
exec 3< <(stdbuf -o0 ./valueServer 5003)
sleep 1
./valueGuesser -s 127.0.0.1 -p1 5003 -p2 9003 &> /dev/null &
sleep 5
killall -q -s SIGINT valueServer &> /dev/null; sleep 1; killall -q -9 valueServer &> /dev/null
sleep 1
killall -q -9 valueGuesser &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+1' | wc -l)
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P3=0;P30=0;P31=0;P32=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 1 ]; then
	echo -e "DEBUGGER: get a correct result from server side (+10)."
  P30=10
else
	echo -e "DEBUGGER: can not correctly catch result from server side!"
fi
P3=$[$P30]
echo -e "\n===> Test 3 score (10 points max): $P3 <===\n\n\n"


sleep 2


### Test 4: Multiple attempts test (10 points max) ###
# 
# Test multiple requests from the same machine
# 
# 1) Start server
# 2) Guesser attempt 1
# 3) Guesser attempt 1
# 4) Guesser attempt 1
# 5) Stop server
# 6) Check server log
##########################################
echo "*** Test 4: Multiple attempts test ***"
exec 3< <(stdbuf -o0 ./valueServer -p 5004)
sleep 1
./valueGuesser -s 127.0.0.1 -p1 5004 -p2 9004 &> /dev/null & sleep 10; killall -q -9 valueGuesser &> /dev/null
./valueGuesser -s 127.0.0.1 -p1 5004 -p2 9004 &> /dev/null & sleep 10; killall -q -9 valueGuesser &> /dev/null
./valueGuesser -s 127.0.0.1 -p1 5004 -p2 9004 &> /dev/null & sleep 10; killall -q -9 valueGuesser &> /dev/null
sleep 1
killall -q -s SIGINT valueServer &> /dev/null; killall -q -9 valueServer &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+3' | wc -l)
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1.*,.*127.0.0.1.*,.*127.0.0.1' | wc -l)

P40=0
if [ $serverMsgRec -ge 1 ] || [ $serverClientIPs -ge 1 ]; then
	echo -e "DEBUGGER: get a correct result from server side (+10)."
  P40=10
else
	echo -e "DEBUGGER: get an incorrect result from server side!"
fi
P4=$[$P40]
echo -e "\n===> Test 4 score (10 points max): $P4 <===\n\n\n"

sleep 2


### Test 5: Multiple Guessers test (10 points max) ###
# 
# Test multiple clients support requested from different machines
# 
# 1) Start server
# 2) Start guesser 1
# 3) Start guesser 2
# 4) Stop server
# 6) Check server log
##########################################
echo "*** Test 5: Multiple guessers test ***"
hostIP=$(hostname -i)
exec 3< <(stdbuf -o0 ./valueServer -p 5005)
sleep 1
./valueGuesser -s 127.0.0.1 -p1 5005 -p2 9005 &> /dev/null & sleep 2; killall -q -9 valueGuesser &> /dev/null
./valueGuesser -s $hostIP -p1 5005 -p2 9005 &> /dev/null & sleep 2; killall -q -9 valueGuesser &> /dev/null
ssh imp22 "${PWD}/valueGuesser -s $hostIP -p1 5005 -p2 9005 &> /dev/null & sleep 2; killall -q -9 valueGuesser &> /dev/null"
sleep 1
killall -q -s SIGINT valueServer &> /dev/null; killall -q -9 valueServer &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+[3-9]+' | wc -l)
serverClientIPs=$(echo $serverLog | grep -oE "127.0.0.1.*,.*\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | uniq | wc -l )

P5=0;P50=0;P51=0;P52=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 1 ]; then
	echo -e "DEBUGGER: get a correct result from server side (+10)."
  P50=10
else
	echo -e "DEBUGGER: can not catch full results from server side!"
  if [ $serverMsgRec -ge 1 ]; then
    echo "DEBUGGER: server only can receive messages (+5)."
    P51=5
  else 
    echo "DEBUGGER: server can not recieve messages!"
  fi
  if [ $serverClientIPs -ge 3 ]; then
    echo "DEBUGGER: server only can get IP addresses from clients (+5)."
    P52=5
  else 
    echo "DEBUGGER: server can not get IP addresses from all clients!"
  fi
fi
P5=$[$P50+$P51+$P52]
echo -e "\n===> Test 5 score (10 points max): $P5 <===\n\n\n"


sleep 1


### Test 6: Documentation and coding style (10 points max) ###
#
# You should clearly document all your works
# 
# 1) Readme file
# 2) Source code comments
# 3) Coding Style
##########################################
P6=10
echo "*** Test 6: Documentation and coding style ***"
echo -e "\n===> Test 6 score (10 points max): $P6 <===\n"



### Calculate total score ###
echo -e "\n\n\n----------------------------------"
echo -e "Total Score (110 Points max): $[$P0+$P1+$P2+$P3+$P4+$P5+$P6]"
echo -e "----------------------------------"
echo -e "Note: the scores displayed in this testing script is only used to measure the basic compatibility and functionality of your implementation, and does not have a direct connection with your final HW#1 grade received from TA. A fully passed test does not guarantee your HW#1 will get a full score from our grading system accordingly. In our final test, we'll use different testing values and extra testing cases to further inspect your implementation."
