@echo off
echo ========================================
echo Installing Dependencies for EcoCheck
echo ========================================

echo.
echo [1/2] Installing Backend Dependencies...
cd backend
call npm install
cd ..

echo.
echo [2/2] Installing Frontend Dependencies...
cd frontend-web-manager
call npm install
cd ..

echo.
echo ========================================
echo Installation Complete!
echo ========================================
pause

