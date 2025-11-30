#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT/backend"
pkill -f "node src/index.js"
sleep 1
node src/index.js &
sleep 2
echo "Backend restarted on PID: $!"
