#!/bin/bash
cd backend
pkill -f "node src/index.js"
sleep 1
node src/index.js &
sleep 2
echo "Backend restarted on PID: $!"
