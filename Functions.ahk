;  MARK: Gui

CustomPrompt(BodyText := '', Title := '', OptionsTexts*) {

  MyGui := Gui()
  MyGui.Title := Title

  MyGui.SetFont("s10")
  MyGui.Add("Text", , BodyText)

  for index, optionText in OptionsTexts {
    MyGui.Add("Button", 'v' OptionText, OptionText).OnEvent("Click", HandleButtonClick)
  }

  Result := ''
  HandleButtonClick(Control, null) {
    Result := Control.Name
    MyGui.Destroy()
  }

  MyGui.Show()
  WinWaitClose(MyGui)
  return Result

}

;  MARK: Keyboard

AllPressed(Keys*) {
  for key in Keys {
    if !GetKeyState(key, "P")
      return false
  }
  return true
}

AllNotPressed(Keys*) {
  for key in Keys {
    if GetKeyState(key, "P")
      return false
  }
  return true
}

;  MARK: Explorer

GetVivaldiPath() {
  Path1 := GetAppDataPath() "\Local\Vivaldi\Application\vivaldi.exe"
  Path2 := A_ProgramFiles "\Vivaldi\Application\vivaldi.exe"
  if (FileExist(Path1))
    return Path1
  if (FileExist(Path2))
    return Path2
  return ''
}

GetExplorerPath() {
  try
    explorerHwnd := WinGetID("ahk_class CabinetWClass")
  catch
    return
  for window in ComObject("Shell.Application").Windows {
    if (window.HWND == explorerHwnd) {
      return window.Document.Folder.Self.Path
    }
  }
  return ""
}

GetAppDataPath() {
  return StrReplace(A_AppData, '\roaming', , 0)
}

GetCurrentMediaFileName() {
  A_Clipboard := ""
  try {
    WinActivate("ahk_class PotPlayer64")
  } catch Error as e {
    return
  }
  ;? Pause is a cutom hotkey set in potplayer. If newly installed set the key to
  ;? Playback -> Playlist -> Add & Edit -> Copy
  ControlSend("{Pause}", , "ahk_class PotPlayer64")
  ClipWaitResult := ClipWait(3)
  if (ClipWaitResult) {
    RegExMatch(A_Clipboard, "\*PotPlayerPlayListItem\*	(.+?)", &MatchedFileName)
    return MatchedFileName.1
  }
  else {
    Sleep 1000
    return GetCurrentMediaFileName()
  }
}

GetShowMovieInfo(MediaFullName, &ShowMovieName := '', &Season := '', &Episode := '') {

  SplitPath(MediaFullName, , , , &MediaNameNoExt)
  ShowFound := RegExMatch(MediaNameNoExt, "i)s(\d\d)e(\d\d)", &SeasonAndEpisode)

  if (ShowFound) {

    ShowMovieName := Trim(RegExReplace(MediaNameNoExt, "i)s\d\de\d\d.*"))
    ShowMovieName := Trim(StrReplace(ShowMovieName, " ", "+"))
    ShowMovieName := Trim(StrReplace(ShowMovieName, "'", "+"))
    ; getting rid of the show year 👇🏻(if present) ; Matches -> (2024) or .2024.
    ShowMovieName := Trim(RegExReplace(ShowMovieName, "[\(\.]\d\d\d\d[\)\.]"))

    Season := LTrim(SeasonAndEpisode.1, "0")
    Episode := LTrim(SeasonAndEpisode.2, "0")

    return 'Show'

  }
  else {
    MovieFound := RegExMatch(MediaNameNoExt, "(\w+[.\s])+\d\d\d\d\.", &MovieName)
    if (MovieFound) {
      ShowMovieName := MovieName.0
      ShowMovieName := Trim(StrReplace(ShowMovieName, ".", "+"))
      return 'Movie'
    }
  }
}

;  MARK: Web

RunInPrivateProfile(Url) {
  browserPath := GetVivaldiPath()
  if (!browserPath) {
    MsgBox 'Vivaldi not found'
    return
  }
  BrowserCommandLine := browserPath " --profile-directory=`"Default`" --disable-features=LockProfileCookieDatabase"
  Run browserPath ' ' Url
}

RunInMainProfile(Url) {
  browserPath := GetVivaldiPath()
  if (!browserPath) {
    MsgBox 'Vivaldi not found'
    return
  }
  BrowserCommandLine := browserPath " --profile-directory=`"Profile 1`" --disable-features=LockProfileCookieDatabase"
  Run browserPath ' ' Url
}

GoogleIflSiteSearch(site, Query) {
  ; BrowserPath := GetAppDataPath() "\Local\Vivaldi\Application\vivaldi.exe --profile-directory=`"Default`" "
  BrowserPath := A_ProgramFiles "\Vivaldi\Application\vivaldi.exe --profile-directory=Default --disable-features=LockProfileCookieDatabase "
  BrowserUrlBase := "https://www.google.com/search?btnI=1&q=site:"
  Query := StrReplace(Query, ' ', '%20')
  Run BrowserPath BrowserUrlBase site "+" Query
}

openInTrakt(GivenPath, Prompt := false) {

  BrowserPath := A_ProgramFiles "\Vivaldi\Application\vivaldi.exe --profile-directory=Default --disable-features=LockProfileCookieDatabase "
  ; BrowserPath := "C:\Users\xq151\AppData\Local\Vivaldi\Application\vivaldi.exe --profile-directory=`"Default`" "
  BrowserUrlBase := "https://www.google.com/search?btnI=1&q=inurl:trakt.tv/"

  Result := GetShowMovieInfo(GivenPath, &Name, &Season, &Episode)

  switch Result {
    case 'Show':
      Message := "Open " Name " S" Season "E" Episode " in Trakt?"
      RunWhat := BrowserPath BrowserUrlBase "shows/*/seasons/" Season "/episodes/" Episode "+inurl:(" Name ")"
    case 'Movie':
      Message := "Open " Name " in Trakt?"
      RunWhat := BrowserPath BrowserUrlBase "movies/+" Name
  }

  if (Prompt)
    Response := MsgBox(Message, , 36)
  if ( NOT Prompt OR Response = "Yes")
    Run RunWhat

}

;  MARK: Other

PowerShell(commands, options := "", return_ := false) {

  commands := ". ( 'D:\Mega\IDEs\powershell\#lib\functions.ps1' );`n" commands

  if (InStr(options, "beep"))
    commands := commands ";`n [console]::beep(1500,50); [console]::beep(2000,50); [console]::beep(2500,50)"
  if (InStr(options, "activate"))
    commands := commands ";`n (New-Object -ComObject WScript.Shell).AppActivate((get-process -id $pid).MainWindowTitle)"
  if (InStr(options, "pause"))
    commands := commands ";`n pause"
  if (InStr(options, "anykey"))
    commands := commands ";`n Write-Host -NoNewLine 'Press any key to continue...'; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"
  if (InStr(options, "exit"))
    commands := commands ";`n exit"

  if return_
    return ComObject("WScript.Shell").Exec("pwsh -noExit -command " commands).StdOut.ReadAll()

  if (InStr(options, "runwait")) {
    RunWait "pwsh -noExit -command " commands, , , &PID
    return PID
  }
  Run "pwsh -noExit -command " commands, , , &PID
  return PID

}

;  MARK: Window functions

IsWindowFullScreen(winTitle := "A") {
  ; Get the window handle
  if winTitle = "A"
    winHandle := WinExist("A")
  else
    winHandle := WinExist(winTitle)

  if !winHandle
    return false

  ; Get window style
  style := WinGetStyle(winHandle)

  ; Get window information
  try {
    X := Y := Width := Height := 0  ; Initialize variables
    WinGetPos(&X, &Y, &Width, &Height, winHandle)
  } catch {
    return false
  }

  ; Get monitor information
  monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHandle, "UInt", 0x2)
  if (monitorHandle) {
    ; Create MONITOR_INFO structure
    NumPut("UInt", 40, MONITOR_INFO := Buffer(40))

    ; Get monitor info
    if DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", MONITOR_INFO) {
      ; Extract monitor working area
      monitorLeft := NumGet(MONITOR_INFO, 20, "Int")
      monitorTop := NumGet(MONITOR_INFO, 24, "Int")
      monitorRight := NumGet(MONITOR_INFO, 28, "Int")
      monitorBottom := NumGet(MONITOR_INFO, 32, "Int")

      ; Check if window covers the entire monitor and has no border
      return (X <= monitorLeft && Y <= monitorTop
        && Width >= monitorRight - monitorLeft
        && Height >= monitorBottom - monitorTop
        && !(style & 0xC00000))  ; WS_CAPTION = 0xC00000
    }
  }
  return false
}

MinimizeAllButActive() {
  ActiveWindowId := WinGetID("A")
  WindowIds := WinGetList()
  ExcludeList := ["ahk_class Internet Explorer_Hidden", 'ahk_class PseudoConsoleWindow', 'ahk_class Progman'
    'ahk_class RainmeterMeterWindow']
  for Id in WindowIds {
    if (Id != ActiveWindowId) {
      WinMinimize('ahk_id ' Id)
    }
  }
}

WinActiveAny(WinTitles*) {
  for title in WinTitles {
    if WinActive(title)
      return true
  }
  return false
}

WinUnderCursor(WindowTitle := '') {
  MouseGetPos(, , &WindowUnderCursor)
  return WindowUnderCursor = WinGetID(WindowTitle)
}

;  MARK: String functions

ClipSend(Text, PS := "") {
  ClipSave := A_Clipboard
  A_Clipboard := ''
  A_Clipboard := Text
  if !ClipWait(2) {
    MsgBox
    return
  }
  ; Sleep 4000
  Send("^v")
  if PS
    Send(PS)
  Sleep 1000
  A_Clipboard := ClipSave
}

SplitIntoLines(text, lineLength := 40) {
  result := ""
  words := StrSplit(text, " ")
  currentLine := ""

  for index, word in words {
    if (StrLen(currentLine) + StrLen(word) > lineLength) {
      result .= RTrim(currentLine) . "`n"
      currentLine := ""
    }
    currentLine .= word . " "
  }

  if (currentLine != "") {
    result .= RTrim(currentLine)
  }

  return RTrim(result)
}

Join(arr, delimiter := " ") {
  result := ""
  for index, element in arr {
    if (index > 1)
      result .= delimiter
    result .= element
  }
  return result
}

AnimateWindowMove(winTitle, targetX, targetY, duration := 1000, fps := 60) {
  if not WinExist(winTitle)
    return false

  WinGetPos(&startX, &startY)

  steps := duration * fps // 1000

  loop steps {
    t := A_Index / steps
    easedT := EaseInOutCubic(t)

    newX := startX + (targetX - startX) * easedT
    newY := startY + (targetY - startY) * easedT

    WinMove(Round(newX), Round(newY))
    Sleep(1000 // fps)
  }

  WinMove(targetX, targetY) ; Ensure final position is exact
  return true
}

EaseInOutCubic(t) {
  return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2
}
