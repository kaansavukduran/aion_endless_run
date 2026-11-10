Unicode true
!include "MUI2.nsh"
Name "Aion Endless Run"
OutFile "..\build\AionEndlessRun-0.5.0-windows-x64-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\Aion Endless Run"
RequestExecutionLevel user
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "English"
Section "Game"
  SetOutPath "$INSTDIR"
  File "..\build\windows\AionEndlessRun.exe"
  File "..\LICENSE"
  File "..\THIRD_PARTY_NOTICES.md"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\Aion Endless Run"
  CreateShortcut "$SMPROGRAMS\Aion Endless Run\Aion Endless Run.lnk" "$INSTDIR\AionEndlessRun.exe"
  CreateShortcut "$SMPROGRAMS\Aion Endless Run\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortcut "$DESKTOP\Aion Endless Run.lnk" "$INSTDIR\AionEndlessRun.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AionEndlessRun" "DisplayName" "Aion Endless Run"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AionEndlessRun" "DisplayVersion" "0.5.0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AionEndlessRun" "UninstallString" '"$INSTDIR\Uninstall.exe"'
SectionEnd
Section "Uninstall"
  Delete "$INSTDIR\AionEndlessRun.exe"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\THIRD_PARTY_NOTICES.md"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\Aion Endless Run.lnk"
  Delete "$SMPROGRAMS\Aion Endless Run\Aion Endless Run.lnk"
  Delete "$SMPROGRAMS\Aion Endless Run\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Aion Endless Run"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AionEndlessRun"
  ; Scores and preferences are deliberately preserved in the user's data folder.
SectionEnd
