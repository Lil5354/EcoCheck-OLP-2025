#!/bin/bash

echo "🛑 Stopping all existing servers..."
pkill -9 -f "vite" 2>/dev/null
pkill -9 -f "node.*index.js" 2>/dev/null
sleep 2

echo ""
echo "🚀 Starting Backend Server..."
cd "/Users/ducdeptrai/Desktop/Workspace/Dynamic Waste Collection/EcoCheck-OLP-2025/backend"
npm start > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
echo "   Backend PID: $BACKEND_PID"
sleep 3

echo ""
echo "🌐 Starting Frontend Server..."
cd "/Users/ducdeptrai/Desktop/Workspace/Dynamic Waste Collection/EcoCheck-OLP-2025/frontend-web-manager"
npm run dev > /tmp/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "   Frontend PID: $FRONTEND_PID"
sleep 3

echo ""
echo "=========================================="
echo "📊 Server Status Check"
echo "=========================================="

if lsof -ti:3000 > /dev/null 2>&1; then
    echo "✅ Backend running on http://localhost:3000"
else
    echo "❌ Backend NOT running - Check logs: tail -f /tmp/backend.log"
fi

if lsof -ti:5173 > /dev/null 2>&1; then
    echo "✅ Frontend running on http://localhost:5173"
else
    echo "❌ Frontend NOT running - Check logs: tail -f /tmp/frontend.log"
fi

echo ""
echo "=========================================="
echo "📝 Logs Location:"
echo "   Backend:  /tmp/backend.log"
echo "   Frontend: /tmp/frontend.log"
echo "=========================================="
echo ""
echo "To view logs:"
echo "   tail -f /tmp/backend.log"
echo "   tail -f /tmp/frontend.log"
