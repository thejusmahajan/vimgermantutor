@echo off
rem test\launcher.cmd vim^|nvim - starts bin\vimgermantutor.cmd and checks
rem that it opened a copy of lesson 1.2 and left the original untouched.
setlocal
set "GERMANTUTOR_TEST_OUT=%~dp0launcher.out"
set "GERMANTUTOR_DATA_DIR=%TEMP%\germantutor-launcher-test"
if exist "%GERMANTUTOR_TEST_OUT%" del "%GERMANTUTOR_TEST_OUT%"
if /i "%~1"=="nvim" (
  call "%~dp0..\bin\vimgermantutor.cmd" --nvim 1.2 -- --headless -S "%~dp0launcher_check.vim"
) else (
  call "%~dp0..\bin\vimgermantutor.cmd" --vim 1.2 -- -es -S "%~dp0launcher_check.vim" < NUL
)
if not exist "%GERMANTUTOR_TEST_OUT%" (
  echo launcher wrote no result
  exit /b 1
)
type "%GERMANTUTOR_TEST_OUT%"
findstr /c:"result=ok" "%GERMANTUTOR_TEST_OUT%" >nul
exit /b %ERRORLEVEL%
