@echo off
rem vimgermantutor.cmd - start the VimGermanTutor in Neovim or Vim (Windows).
rem Like vimtutor, it runs the editor without your vimrc, so that every key
rem does what the lesson says. Arguments after -- go to the editor.
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "GERMANTUTOR_ROOT=%%~fI"
set "GT_EDITOR="
set "GT_LESSON="
set "GT_EXTRA="

:parse
if "%~1"=="" goto args_done
if "%~1"=="--" goto extra
if /i "%~1"=="--nvim" (set "GT_EDITOR=nvim" & shift & goto parse)
if /i "%~1"=="--vim" (set "GT_EDITOR=vim" & shift & goto parse)
if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage
if "%~1"=="/?" goto usage
set "GT_ARG=%~1"
if "%GT_ARG:~0,1%"=="-" (
  echo vimgermantutor: unbekannte Option: %~1 1>&2
  exit /b 2
)
set "GT_LESSON=%~1"
shift
goto parse

:extra
shift
:extra_loop
if "%~1"=="" goto args_done
set GT_EXTRA=%GT_EXTRA% %1
shift
goto extra_loop

:args_done
if /i "%GT_EDITOR%"=="vim" goto find_vim
where nvim >nul 2>nul && (set "GT_EXE=nvim" & goto run)
if /i "%GT_EDITOR%"=="nvim" goto not_found
:find_vim
where vim >nul 2>nul && (set "GT_EXE=vim" & goto run)
where gvim >nul 2>nul && (set "GT_EXE=gvim" & goto run)
:not_found
echo vimgermantutor: Weder nvim noch vim gefunden. Bitte installiere Neovim oder Vim. 1>&2
exit /b 1

:run
call "%GT_EXE%" -N -u NONE --cmd "set encoding=utf-8" --cmd "let g:germantutor_launcher = 1" --cmd "let &rtp = escape($GERMANTUTOR_ROOT, ',') . ',' . &rtp" -c "runtime plugin/germantutor.vim" -c "GermanTutor %GT_LESSON%"%GT_EXTRA%
exit /b %ERRORLEVEL%

:usage
echo Benutzung: vimgermantutor [--nvim ^| --vim] [Lektion] [-- Editor-Optionen]
echo.
echo   vimgermantutor          weitermachen, wo du aufgehoert hast
echo   vimgermantutor 1.2      Lektion 1.2 starten
echo   vimgermantutor --vim    Vim nehmen, auch wenn Neovim installiert ist
echo   vimgermantutor --nvim   Neovim nehmen
exit /b 0
