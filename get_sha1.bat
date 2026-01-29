@echo off
REM Helper script to get SHA-1 fingerprint for Firebase configuration

echo ========================================
echo Getting SHA-1 Fingerprint for Firebase
echo ========================================
echo.

REM Try to find keytool in common Java locations
set KEYTOOL_PATH=

REM Check if keytool is in PATH
where keytool >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set KEYTOOL_PATH=keytool
    goto :run_keytool
)

REM Check common Java installation paths
if exist "C:\Program Files\Java\jdk*\bin\keytool.exe" (
    for /d %%i in ("C:\Program Files\Java\jdk*") do (
        if exist "%%i\bin\keytool.exe" (
            set KEYTOOL_PATH=%%i\bin\keytool.exe
            goto :run_keytool
        )
    )
)

if exist "C:\Program Files (x86)\Java\jdk*\bin\keytool.exe" (
    for /d %%i in ("C:\Program Files (x86)\Java\jdk*") do (
        if exist "%%i\bin\keytool.exe" (
            set KEYTOOL_PATH=%%i\bin\keytool.exe
            goto :run_keytool
        )
    )
)

REM Check Android Studio embedded JDK
if exist "%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe" (
    set KEYTOOL_PATH=%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe
    goto :run_keytool
)

echo ERROR: Could not find keytool.exe
echo.
echo Please run this command manually:
echo.
echo keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
echo.
echo Look for the SHA1 line in the output.
echo.
pause
exit /b 1

:run_keytool
echo Using keytool from: %KEYTOOL_PATH%
echo.
echo Running keytool command...
echo.

"%KEYTOOL_PATH%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo ========================================
echo INSTRUCTIONS:
echo ========================================
echo 1. Look for the "SHA1:" line in the output above
echo 2. Copy the SHA1 fingerprint (format: XX:XX:XX:XX:...)
echo 3. Go to Firebase Console: https://console.firebase.google.com/
echo 4. Select project: micro-skill-decay-detector
echo 5. Go to Project Settings (gear icon)
echo 6. Click on your Android app
echo 7. Scroll to "SHA certificate fingerprints"
echo 8. Click "Add fingerprint" and paste the SHA1
echo 9. Download the updated google-services.json
echo 10. Replace android\app\google-services.json with the new file
echo ========================================
echo.
pause
