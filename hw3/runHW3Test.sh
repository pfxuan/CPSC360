#!/bin/bash
echo "===| Testing Cases Summary |==="
echo "Test 0: Compiling"
echo "Test 1: Simple web query"
echo "Test 2: 404"
echo "Test 3: 403"
echo "Test 4: 400"
echo "Test 5: 405"
echo "Test 6: Content-Type"
echo "Test 7: HTTP client"
echo -e "Test 8: Code style and readability\n"

TESTDOCROOT="./docs"
TMPDIR=`mktemp --tmpdir=/dev/shm -dt "hw3Test.XXXXXXXXXX"`
chmod 000 ${TESTDOCROOT}/403/mypage.html

echo -e "Below is the detail of the grading for your submission.\n\n"
### Test 0: Compiling Test
echo "*** Test 0: Compiling ***"
tar xzf *-hw3.tar.gz &> /dev/null
make clean &> /dev/null
warningcount=`make 2>&1 | grep -i "warning:" | wc -l`
if [ $warningcount -ge 1 ]; then
	echo -e "\nCompiler warnings found.\n"
fi

if [ -e simhttp ] && [ -e simget ]; then
  echo -e "GRADER: Test Result -> Passed.\n"
  echo -e "===> Compiling score (10 points max): 10.0 <===\n\n\n"
  P0=10
else 
  echo -e "GRADER: Test Result -> Failed!!!\n"
  echo -e "(Cannot find the execution file ./simhttp or ./simget)\n"
  echo -e "===> Test 0 score (10 points max): 0.0 <===\n\n\n"
  P0=0
fi
  
###echo "Killing zombies"
killall -q -9 simhttp &> /dev/null
killall -q -9 nc &> /dev/null
killall -q -9 printf &> /dev/null
sleep 1

chkPort8080=`netstat -an | grep :8080 | wc -l`
chkPort8089=`netstat -an | grep :8089 | wc -l`
if [ $chkPort8080 -ge 1 ] || [ $chkPort8089 -ge 1 ]; then
  sleep 65
fi

### Test 1: Simple Web query (single html page)
echo "*** Test 1: Simple web query ***"
#echo ${TESTDOCROOT}/200
sleep 2
stdbuf -o0 ./simhttp -p 8080 ${TESTDOCROOT}/200 | grep -i "GET.*mypage.*200" > ${TMPDIR}/serverLog1 &
sleep 2
simpleResults=`printf "GET /mypage.html HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8080  | grep "1.1 200 OK\|My\ Title\|Hello\ World" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
killall -q -9 simhttp &> /dev/null

sync
sleep 1
simpleServerOut=`cat ${TMPDIR}/serverLog1 | wc -l`
sleep 1

if [ $simpleResults -eq 0 ]; then
  ./simhttp -p 8079 ./ &> /dev/null &
  sleep 2
  testPortResult=`nc localhost 8079 -z 2>&1 |  grep "unable to connect to address localhost" | wc -l`
  #testPortResult=`nc localhost 8079 -z | wc -l`
  killall -q -9 simhttp &> /dev/null
  if [ $testPortResult -eq 0 ]; then
    echo "GRADER: Test result for client -> Failed, but is able to open a service port (+5)"
    P11=5
  else
    echo "GRADER: Test result for client -> Failed!!!"
    P11=0
  fi
elif [ $simpleResults -ge 3 ]; then
  echo  "GRADER: Test result for client -> Passed."
  P11=30
else
  echo  "GRADER: Test result for client -> Partially Passed (+$[$simpleResults*10])."
  P11=$[$simpleResults*10]
fi

if [ $simpleServerOut -eq 0 ]; then
  echo -e "GRADER: Test result for server -> Failed!!!\n"
  P12=0
else
  echo -e "GRADER: Test result for server -> Passed (+10).\n"
  P12=10
fi
P1=$[$P11+$P12]
echo -e "===> Test 1 score (40 points max): $P1 <===\n\n\n"



### Test 2: 404 
echo "*** Test 2: 404 ***"
sleep 2
stdbuf -o0 ./simhttp -p 8082 ${TESTDOCROOT}/404 | grep -i "GET.*mypage.*404" > ${TMPDIR}/serverLog2 &
sleep 2
test2Out=`printf "GET /mypage.html HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8082 | grep -i "404" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
killall -q -9 simhttp &> /dev/null
sync
sleep 2
serverOut=`cat ${TMPDIR}/serverLog2 | wc -l`

P2=0
if [ $serverOut -eq 0 ]; then
	echo -e "GRADER: Server output incorrect (0)."
else
	echo -e "GRADER: Server output correct (+5)."
	P2=5
fi

if [ $test2Out -eq 0  ]; then
  echo -e "GRADER: Client output incorrect (0).\n"
else
  P2=$[$P2+5]
  echo -e "GRADER: Client output correct (+5).\n"
fi

echo -e "===> Test 2 score (10 points max): $P2 <===\n\n\n"



### Test 3: 403 
echo "*** Test 3: 403 ***"
sleep 2
stdbuf -o0 ./simhttp -p 8083 ${TESTDOCROOT}/403 > ${TMPDIR}/serverLog3 &
sleep 2

#try file permissions
test3Out=`printf "GET /mypage.html HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8083 2>&1 & sleep 5; killall -q -9 nc &> /dev/null`
killall -q -9 simhttp &> /dev/null

#try sandboxing
sleep 2
stdbuf -o0 ./simhttp -p 8093 ${TESTDOCROOT}/403 >> ${TMPDIR}/serverLog3 &
sleep 2
test3bOut=`printf "GET /../200/mypage.html HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8093 > ${TMPDIR}/clientLog3 & sleep 2; killall -q -9 nc &> /dev/null`
sleep 2
killall -q -9 simhttp &> /dev/null
sync

sleep 2
clientOut1=`echo ${test3Out} | grep -i "403 Forbidden" | wc -l`
clientOut1a=`echo ${test3Out} | grep -i "400 Bad" | wc -l`
clientOut2=`cat ${TMPDIR}/clientLog3 | grep -i "403 Forbidden" | wc -l`
clientOut2a=`cat ${TMPDIR}/clientLog3 | grep -i "400 Bad" | wc -l`
serverOut1=`cat ${TMPDIR}/serverLog3 | grep -i "GET.*mypage.*403" | wc -l`
serverOut2=`cat ${TMPDIR}/serverLog3 | grep -i "GET.*mypage.*400" | wc -l` 
sleep 1

P3=0
if [ $clientOut1 -eq 0 ] && [ $clientOut1a -eq 0 ]; then
  echo -e "GRADER: File permissions test (client-side) -> Failed"
elif [ $clientOut1 -eq 0 ] && [ $clientOut1a -ne 0 ]; then
  echo -e "GRADER: File permissions test (client-side) -> Partially Passed (400, not 403) (+2)"
  P3=2
elif [ $clientOut1 -ne 0 ] && [ $clientOut1a -eq 0 ]; then 
  echo -e "GRADER: File permissions test (client-side) -> Passed (+3)."
  P3=3
else 
  echo -e "GRADER: File permissions test (client-side) -> Partially Passed (unexpected errors) (+2)."
  P3=2
fi

if [ $serverOut1 -eq 0  ]; then
  if [ $serverOut2 -eq 0  ]; then
    echo -e "GRADER: File permissions test (server-side) -> Failed."
  else
    echo -e "GRADER: File sandbox test (server-side) -> Partially Passed (400, not 403)  (+2).\n"
    P3=$[$P3+2]
  fi
else
  echo -e "GRADER: File permissions test (server-side) -> Passed (+3)."
  P3=$[$P3+5]
fi

if [ $clientOut2 -eq 0  ] && [ $clientOut2a -eq 0 ]; then
  echo -e "GRADER: File sandbox test (client-side) -> Failed."
elif [ $clientOut2 -eq 0 ] && [ $clientOut2a -eq 1 ]; then
  echo -e "GRADER: File sandbox test (client-side) -> Partially Passed (400, not 403) (+1)"
  P3=$[$P3+1]
elif [ $clientOut2 -eq 1 ] && [ $clientOut2a -eq 0 ]; then
  echo -e "GRADER: File sandbox test (client-side) -> Passed (+2)."
  P3=$[$P3+2]
else
  echo -e "GRADER: File sandbox test (client-side) -> Partially Passed (unexpected errors) (+1)"
  P3=$[$P3+1]
fi

echo -e "===> Test 3 score (10 points max): $P3 <===\n\n\n"



### Test 4: 400
echo "*** Test 4: 400 ***"
sleep 2
stdbuf -o0 ./simhttp -p 8084 ${TESTDOCROOT}/200 > ${TMPDIR}/serverLog4 &
sleep 2
test4Out=`printf "GET Web server should suppose gotten 400 error\r\n\r\n" | nc localhost 8084 | grep -i "400 Bad Request" | wc -l & sleep 2; killall -q -9 nc &> /dev/null` 
sleep 2
killall -q -9 simhttp &> /dev/null

sync
sleep 1
serverOutTest4=`cat ${TMPDIR}/serverLog4 | grep -i "400" | wc -l`
sleep 1

P4=0
if [ $test4Out -eq 0  ]; then
  echo -e "GRADER: Test result (client-side) -> Failed!!!"
  if [ $serverOutTest4 -ge 1 ]; then
    echo "GRADER: Test result (server-side) -> passed (+5)"
    P4=5
  else
    echo "GRADER: Test result (server-side) -> Failed!!!"
    P4=0
  fi
else
  echo -e "GRADER: Test result -> Passed."
  P4=10
fi

echo -e "\n===> Test 4 score (10 points max): $P4 <===\n\n\n"



### Test 5: 405
echo "*** Test 5: 405 ***"
sleep 2
stdbuf -o0 ./simhttp -p 8085 ${TESTDOCROOT}/200 &> ${TMPDIR}/serverLog5 &
sleep 2
test5Out=`printf "POST /mypage.html HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8085 | grep "405" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
killall -q -9 simhttp &> /dev/null

sync
sleep 1
serverOutTest5=`cat ${TMPDIR}/serverLog5 | grep -i "405" | wc -l`
sleep 1

P5=0
if [ $test5Out -eq 0 ]; then
  echo -e "GRADER: Test result (client-side) -> Failed!!!"
  if [ $serverOutTest5 -ge 1 ]; then
    echo "GRADER: Test result (server-side) -> passed (+5)"
    P5=5
  else
    echo "GRADER: Test result (server-side) -> Failed!!!"
    P5=0
  fi
else
  echo -e "GRADER: Test result -> Passed."
  P5=10
fi

echo -e "\n===> Test 5 score (10 points max): $P5 <===\n\n\n"


### Test 6: Content-Type 
echo "*** Test 6: Content-Type html, htm, css, js, txt, jpg, pdf and octet-stream ***"
./simhttp -p 8086 ${TESTDOCROOT}/mime &>/dev/null &
sleep 2
test6css=`printf "GET /css/bootstrap.css HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8086 | grep "text/css" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
sleep 1
killall -q -9 simhttp &> /dev/null
sleep 1

./simhttp -p 8087 ${TESTDOCROOT}/mime &>/dev/null &
sleep 2
test6jpeg=`printf "GET /img/intro-bg.jpg HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8087 | grep "image/jpeg" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
sleep 1
killall -q -9 simhttp &> /dev/null
sleep 1

./simhttp -p 8088 ${TESTDOCROOT}/mime &>/dev/null &
sleep 2
test6javascript=`printf "GET /js/bootstrap.js HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8088 | grep "application/javascript" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
sleep 1
killall -q -9 simhttp &> /dev/null

sleep 2
./simhttp -p 8089 ${TESTDOCROOT}/mime &>/dev/null &
sleep 2
test6other=`printf "GET /fonts/glyphicons-halflings-regular.eot HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8089 | grep "application/octet-stream" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
killall -q -9 simhttp &> /dev/null

sleep 2
./simhttp -p 8090 ${TESTDOCROOT}/mime &>/dev/null &
sleep 2
test6txt=`printf "GET /readme.txt HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8090 | grep "plain" | wc -l & sleep 1; killall -q -9 nc &> /dev/null` 
sleep 1
killall -q -9 simhttp &> /dev/null
sleep 1

P6=0
if [ $test6txt -ge 1 ]; then
  echo "GRADER: content type test (text/plain) -> passed (+2)"
  P6=$[$P6+2]
else
  echo "GRADER: content type test (text/plain) -> failed!!!"
fi
if [ $test6css -ge 1 ]; then
  echo "GRADER: content type test (text/css) -> passed (+2)"
  P6=$[$P6+2]
else
  echo "GRADER: content type test (text/css) -> failed!!!"
fi
if [ $test6jpeg -ge 1 ]; then
  echo "GRADER: content type test (image/jpeg) -> passed (+2)"
  P6=$[$P6+2]
else
  echo "GRADER: content type test (image/jpeg) -> failed!!!"
fi
if [ $test6javascript -ge 1 ]; then
  echo "GRADER: content type test (application/javascript) -> passed (+2)"
  P6=$[$P6+2]
else
  echo "GRADER: content type test (application/javascript) -> failed!!!"
fi
if [ $test6other -ge 1 ]; then
  P6=$[$P6+2]
  echo "GRADER: content type test (application/octet-stream) -> passed (+2)"
else
  echo "GRADER: content type test (application/octet-stream) -> failed!!!"
fi

echo -e "\n===> Test 6 score (10 points max): $P6 <===\n\n\n"



### Test 7: HTTP Client
echo "*** Test 7: HTTP Client ***"
sleep 2
test7Out=$(stdbuf -o0 ./simget http://www.cs.clemson.edu/help/index.html -p 80 | grep "McAdams" | wc -l & sleep 7; killall -q -9 simget &> /dev/null)

P7=0
if [ $test7Out -ge 1 ]; then
	echo -e "GRADER: HTTP client output correct (+40)."
	P7=40
else
	echo -e "GRADER: HTTP client output incorrect (0)!!!"
	P7=0
fi

echo -e "===> Test 7 score (40 points max): $P7 <===\n\n\n"


### Test 8: Code style and readability
echo "*** Test 8: Code style and readability ***"
echo -e "\n===> Test 8 score (10 points max): 10.0 <==="
P8=10


### Calculate total score 
echo -e "\n\n\n---------------------------------"
echo -e "Total Score (150 points max): $[$P0+$P1+$P2+$P3+$P4+$P5+$P6+$P7+$P8]"
echo -e "---------------------------------"
