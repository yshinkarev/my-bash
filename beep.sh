#!/bin/bash

beep() {
( speaker-test -t sine -f $1 ) & PID=$! 
sleep $2s
kill -9 $PID	
}

beep 1000 0.1 > /dev/null 2>&1
beep 2000 0.1 > /dev/null 2>&1