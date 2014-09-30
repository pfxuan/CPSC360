#!/bin/bash
echo "===| Testing Cases Summary |==="
echo "Test 0: Compilation"
echo "Test 1: Simple functionality test"
echo "Test 2: Timeout test"
echo "Test 3: CTRL-C test"
echo "Test 4: Multiple attempts test"
echo "Test 5: Multiple breakers test"
echo -e "Test 6: Documentation and coding style\n"

echo -e "Below is the detailed grading results for your submission.\n\n\n"



### Test 0: Compiling Test
echo "*** Test 0: Compiling ***"
tar xzf *.tgz &> /dev/null; tar xzf *.tar.gz &> /dev/null; tar xf *.tar &> /dev/null
cd * &> /dev/null
make clean &> /dev/null; make depend &> /dev/null
warningcount=`make 2>&1 | grep -i "warning" | wc -l`
P0=0
if [ $warningcount -ge 1 ]; then
	echo -e "${warningcount} compiler warnings found!!!"
fi

if [ -e passwordBreaker ] && [ -e passwordServer ]; then
  echo -e "GRADER: Test Result -> Passed.\n"
  echo -e "===> Test 0 score (10 points max): 10.0 <===\n\n\n"
  P0=10
else 
  echo -e "GRADER: Test Result -> Failed!!!\n"
  echo -e "(Cannot find the execution file ./passwordBreaker or ./passwordServer)\n"
  echo -e "===> Test 0 score (10 points max): 0.0 <===\n\n\n"
  P0=0
fi
  
### "Killing previous zombie processors"
killall -q -9 passwordBreaker &> /dev/null
killall -q -9 passwordServer &> /dev/null
sleep 1

chkPort5000=`netstat -an | grep :5000 | wc -l`
chkPort5001=`netstat -an | grep :5001 | wc -l`
if [ $chkPort5000 -ge 1 ] || [ $chkPort5001 -ge 1 ]; then
  sleep 65
fi



### Test 1: Simple functionality test (50 points max) ###
#
# A simple test using password 'a1'.
#
# 1) Start server
# 2) Start breaker 
# 3) Wait 5 secs 
# 4) Stop server
# 5) Check server log
##########################################
echo "*** Test 1: Simple functionality test ***"
exec 3< <(./passwordServer 5001 2 a1 2>&1)
sleep 1
./passwordBreaker 127.0.0.1 5001 2 &> /dev/null & sleep 5; killall -q -9 passwordBreaker &> /dev/null
sleep 1
killall -q -s SIGINT passwordServer &> /dev/null; killall -q -9 passwordServer &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+[1-9]' | wc -l)
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P1=0;P10=0;P11=0;P12=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 1 ]; then
	echo -e "GRADER: get a correct result from server side (+50)."
  P10=50
else
	echo -e "GRADER: can not correctly catch result from server side!"
  if [ $serverMsgRec -ge 1 ]; then
    echo "GRADER: server only can receive messages (+30)."
    P11=20
  else 
    echo "GRADER: server can not recieve messages!"
  fi
  if [ $serverClientIPs -ge 1 ]; then
    echo "GRADER: server only can get IP addresses from clients (+20)."
    P12=20
  else 
    echo "GRADER: server can not get IP addresses from clients!"
  fi
fi
P1=$[$P10+$P11+$P12]
echo -e "\n===> Test 1 score (50 points max): $P1 <===\n\n\n"


sleep 2


### Test 2: Timeout test (10 points max) ###
# 
# Test timeout for breaker by breaking server
# 
# 1) Start breaker
# 2) Wait 2 secs 
# 3) Start server
# 4) Wait 2 secs 
# 5) Stop server
# 6) Check server log
##########################################
echo "*** Test 2: Timeout test ***"
./passwordBreaker 127.0.0.1 5002 2 &> /dev/null &
sleep 2
exec 3< <(./passwordServer 5002 2 a1 2>&1)
sleep 2
killall -q -s SIGINT passwordServer &> /dev/null; killall -q -9 passwordServer &> /dev/null
killall -q -9 passwordBreaker &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P2=0;P20=0
if [ $serverClientIPs -ge 1 ]; then
	echo -e "GRADER: get a correct result from server side (+10)."
  P20=10
else
	echo -e "GRADER: can not correctly catch result from server side!"
fi
P2=$[$P20]
echo -e "\n===> Test 2 score (10 points max): $P2 <===\n\n\n"


sleep 2


### Test 3: CTRL-C test (10 points max) ###
# 
# Test state machine in server by issuing CTRL-C
# 
# 1) Start server
# 2) Start breaker 
# 3) Wait 5 secs 
# 4) Interrupt server
# 5) Stop breaker 
# 6) Check server log
##########################################
echo "*** Test 3: CTRL-C test ***"
exec 3< <(./passwordServer 5003 7 GoTiger 2>&1)
sleep 1
./passwordBreaker 127.0.0.1 5003 7 &> /dev/null &
sleep 5
killall -q -s SIGINT passwordServer &> /dev/null; killall -q -9 passwordServer &> /dev/null
sleep 1
killall -q -9 passwordBreaker &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+0' | wc -l)
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P3=0;P30=0;P31=0;P32=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 1 ]; then
	echo -e "GRADER: get a correct result from server side (+10)."
  P30=10
else
	echo -e "GRADER: can not correctly catch result from server side!"
fi
P3=$[$P30]
echo -e "\n===> Test 3 score (10 points max): $P3 <===\n\n\n"


sleep 2


### Test 4: Multiple attempts test (10 points max) ###
# 
# Test multiple requests from the same machine
# 
# 1) Start server
# 2) Breaker attempt 1
# 3) Breaker attempt 1
# 4) Breaker attempt 1
# 5) Stop server
# 6) Check server log
##########################################
echo "*** Test 4: Multiple attempts test ***"
exec 3< <(./passwordServer 5004 1 a 2>&1)
sleep 1
./passwordBreaker 127.0.0.1 5004 1 &> /dev/null & sleep 2; killall -q -9 passwordBreaker &> /dev/null
./passwordBreaker 127.0.0.1 5004 1 &> /dev/null & sleep 2; killall -q -9 passwordBreaker &> /dev/null
./passwordBreaker 127.0.0.1 5004 1 &> /dev/null & sleep 2; killall -q -9 passwordBreaker &> /dev/null
sleep 1
killall -q -s SIGINT passwordServer &> /dev/null; killall -q -9 passwordServer &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+3' | wc -l)
serverClientIPs=$(echo $serverLog | grep -E '127.0.0.1' | wc -l)

P40=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 1 ]; then
	echo -e "GRADER: get a correct result from server side (+10)."
  P40=10
else
	echo -e "GRADER: get an incorrect result from server side!"
fi
P4=$[$P40]
echo -e "\n===> Test 4 score (10 points max): $P4 <===\n\n\n"

sleep 2


### Test 5: Multiple Breakers test (10 points max) ###
# 
# Test multiple clients support requested from different machines
# 
# 1) Start server
# 2) Start breaker 1
# 3) Start breaker 2
# 4) Stop server
# 6) Check server log
##########################################
echo "*** Test 5: Multiple breakers test ***"
hostIP=$(hostname -i)
exec 3< <(./passwordServer 5005 1 a 2>&1)
sleep 1
./passwordBreaker 127.0.0.1 5005 1 &> /dev/null & sleep 2; killall -q -9 passwordBreaker &> /dev/null
./passwordBreaker $hostIP 5005 1 &> /dev/null & sleep 2; killall -q -9 passwordBreaker &> /dev/null
ssh imp22 "${PWD}/passwordBreaker $hostIP 5005 1 &> /dev/null & sleep 2; killall -q -9 passwordBreaker &> /dev/null"
sleep 1
killall -q -s SIGINT passwordServer &> /dev/null; killall -q -9 passwordServer &> /dev/null
sleep 1
serverLog=$(cat <&3)
echo -e "ServerLog: $serverLog"
serverMsgRec=$(echo $serverLog | grep -E '[0-9]+\s+[3-9]+' | wc -l)
serverClientIPs=$(echo $serverLog | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | uniq | wc -l )

P5=0;P50=0;P51=0;P52=0
if [ $serverMsgRec -ge 1 ] && [ $serverClientIPs -ge 2 ]; then
	echo -e "GRADER: get a correct result from server side (+10)."
  P50=10
else
	echo -e "GRADER: can not catch full results from server side!"
  if [ $serverMsgRec -ge 1 ]; then
    echo "GRADER: server only can receive messages (+5)."
    P51=5
  else 
    echo "GRADER: server can not recieve messages!"
  fi
  if [ $serverClientIPs -ge 3 ]; then
    echo "GRADER: server only can get IP addresses from clients (+5)."
    P52=5
  else 
    echo "GRADER: server can not get IP addresses from all clients!"
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
