;  MARK: Array

ArrayIncludes(arr, value, isRegex := false) {
  for element in arr {
    if isRegex {
      if RegExMatch(element, value, &MatchObj)
        return MatchObj
    } else {
      if (element = value)
        return true
    }
  }
  return false
}

ArrayJoin(arr, delimiter := " ") {
  result := ""
  for index, element in arr {
    if (index > 1)
      result .= delimiter
    result .= element
  }
  return result
}

;  MARK: File system

IsVideoFile(ext) {
  static videoExts := Map(
    "mp4", true, "mkv", true, "mov", true, "avi", true, "webm", true,
    "m4v", true, "wmv", true, "flv", true, "mpg", true, "mpeg", true,
    "mts", true, "m2ts", true, "ts", true, "3gp", true, "f4v", true
  )
  if !IsSet(ext)
    return false
  extLower := StrLower(ext)
  return videoExts.Has(extLower)
}

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

AllPressedPhysical(Keys*) {
  for key in Keys {
    if !GetKeyState(key, "P")
      return false
  }
  return true
}

AllNotPressedPhysical(Keys*) {
  for key in Keys {
    if GetKeyState(key, "P")
      return false
  }
  return true
}

AllNotPressed(Keys*) {
  for key in Keys {
    if GetKeyState(key)
      return false
  }
  return true
}

;  MARK: Explorer

RevealInExplorer(Path) {
  Run "explorer.exe /select, " Path
}

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

GetDefaultBrowser() {
  ; Step 1: Get the ProgId of the default HTTP handler
  try {
    progId := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice",
      "ProgId")
  } catch {
    return ""
  }

  ; Step 2: Resolve the ProgId to its shell open command
  try {
    command := RegRead("HKEY_CLASSES_ROOT\" progId "\shell\open\command")
  } catch {
    ; Some browsers register per-user instead of machine-wide
    try {
      command := RegRead("HKEY_CURRENT_USER\Software\Classes\" progId "\shell\open\command")
    } catch {
      return ""
    }
  }

  ; Step 3: Extract the executable path from the command string
  ; command looks like: "C:\Program Files\...\browser.exe" -- "%1"
  if RegExMatch(command, '^"([^"]+)"', &m)
    exePath := m[1]
  else
    exePath := Trim(StrSplit(command, " ")[1])

  return exePath
}

OpenUrlInBrowser(Url, BrowserName := "Default", ProfileName := "LastUsed") {
  if (BrowserName = "Default" AND ProfileName = "LastUsed") {
    Run Url
    return
  }
  switch (BrowserName) {
    case "Vivaldi":
      BrowserPath := GetAppDataPath() "\Local\Vivaldi\Application\vivaldi.exe"
    case "Chrome":
      BrowserPath := EnvGet('ProgramW6432') "\Google\Chrome\Application\chrome.exe"
    case "Edge":
      BrowserPath := EnvGet('ProgramW6432') "\Microsoft\Edge\Application\msedge.exe"
    case "Firefox":
      BrowserPath := EnvGet('ProgramW6432') "\Mozilla Firefox\firefox.exe"
    case "Default":
      BrowserPath := GetDefaultBrowser()
    default:
      MsgBox "Unsupported browser: " BrowserName
      return
  }
  if InStr(BrowserPath, "firefox.exe") {
    BrowserName := "Firefox"
  }
  if (BrowserName = "Firefox") {
    BrowserCommandLine := "-P " ProfileName
  } else {
    BrowserCommandLine := "--profile-directory=" ProfileName
  }
  Run BrowserPath " " BrowserCommandLine " " Url
}

RunInPrivateProfile(Url) {
  browserPath := GetVivaldiPath()
  if (!browserPath) {
    MsgBox 'Vivaldi not found'
    return
  }
  BrowserCommandLine := browserPath " --profile-directory=`"Profile 1`" --disable-features=LockProfileCookieDatabase"
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
  UrlBase := "https://www.google.com/search?btnI=1&q=site:"
  Query := StrReplace(Query, ' ', '%20')
  FinalUrl := UrlBase site "+" Query
  Run FinalUrl
}

openInTrakt(GivenPath, Prompt := false) {

  Result := GetShowMovieInfo(GivenPath, &Name, &Season, &Episode)

  switch Result {
    case 'Show':
      Message := "Open " Name " S" Season "E" Episode " in Trakt?"
      Query := "shows/*/seasons/" Season "/episodes/" Episode "+inurl:(" Name ")"
    case 'Movie':
      Message := "Open " Name " in Trakt?"
      Query := "movies/+" Name
  }

  if (Prompt)
    Response := MsgBox(Message, , 36)
  if ( NOT Prompt OR Response = "Yes")
    GoogleIflSiteSearch("trakt.tv", Query)
  else
    return

}

;  MARK: Other

RunDirElectron(DirPath, Args := []) {
  ElectronExePath := A_AppData "\Electron Fiddle\electron-bin\current\electron.exe"
  if !FileExist(ElectronExePath) {
    MsgBox "Electron Fiddle not found. Please install it first."
    return
  }
  ArgsString := Join(" ", , Args)
  MsgBox ArgsString
  Run ElectronExePath " " DirPath " " ArgsString
}

KandoBlackList := [
  'Thief',
  'Little Nightmares ',
  'Little Nightmares II Enhanced  ',
  'Little Nightmares III  ',
  'REANIMAL  '
]
TriggerKando() {
  if (ArrayIncludes(KandoBlackList, WinGetTitle("A"))) {
    Send '{LButton}'
    return
  }
  Send "^+!{Space}"
}

/**
 * Executes a string of AutoHotkey v2 code dynamically by saving it to a temporary
 * file and running it as a separate process.
 * 
 * @param CodeString {String} The string containing the AutoHotkey v2 code to execute.
 * @param WaitForCompletion {Boolean} [Optional] If true (default), the function waits
 *   for the dynamic script to finish before returning. If false, the function
 *   returns immediately after launching the script.
 * @param DeleteTempFile {Boolean} [Optional] If true (default), the temporary .ahk
 *   file created will be deleted after execution (or attempted launch if not waiting).
 *   Set to false for debugging purposes (to inspect the generated script).
 * @param ShowErrors {Boolean} [Optional] If true (default), MsgBox errors encountered
 *   during file creation or the Run command's *initial launch attempt* will be shown.
 *   Runtime errors *within* the dynamic code will appear in their own error dialogs
 *   from the separate process, regardless of this setting.
 * 
 * @returns {Integer | Boolean}
 *   - If WaitForCompletion is true: Returns true if Run successfully launched the process
 *     (didn't throw an error) and the script subsequently waited for it to complete.
 *     Returns false if Run threw an error on launch or if another error occurred beforehand.
 *   - If WaitForCompletion is false: Returns the Process ID (PID) of the launched
 *     script if the initial launch was successful (PID > 0), or 0 if the Run command
 *     failed to launch (e.g., returned PID 0, though typically it throws).
 *     Returns false if there was an error *before* the Run command (e.g., file write error).
 *     Note: A returned PID only confirms successful *launch*, not successful *execution*
 *     of the dynamic code.
 */
RunDynamicAHK(CodeString, WaitForCompletion := true, DeleteTempFile := true, ShowErrors := true) {
  local tempScriptPath, file, runOptions, pid := 0 ; Initialize pid

  ; Basic validation
  if Trim(CodeString) == "" {
    if ShowErrors
      MsgBox "RunDynamicAHK Error: CodeString parameter cannot be empty.", "RunDynamicAHK Error", 48 ; Exclamation icon
    return false
  }

  ; Generate temporary file path
  tempScriptPath := A_Temp . "\DynamicAHK_" . A_TickCount . "_" . Random(1000, 9999) . ".ahk"

  try {
    ; --- Write code to temporary file ---
    file := FileOpen(tempScriptPath, "w", "UTF-8-RAW")
    if !IsObject(file) {
      throw Error("Failed to open temporary file for writing: " . tempScriptPath)
    }
    file.Write("#Requires AutoHotkey v2.0`n")
    file.Write(CodeString)
    file.Close()

    ; --- Prepare and execute the Run command ---
    if WaitForCompletion {
      runOptions := "Wait"
      ; Execute and wait. If Run fails to launch, it throws an Error.
      ; If successful, execution pauses here until the process ends.
      RunWait(A_AhkPath . " " "" . tempScriptPath . "" "", , runOptions)
      ; If we reach here, Run launched successfully and the wait completed.
      return true
    } else {
      runOptions := ""
      ; Execute without waiting. Returns PID on successful launch, throws Error on failure.
      pid := Run(A_AhkPath . " " "" . tempScriptPath . "" "", , runOptions)
      ; Although Run typically throws on failure, defensively check PID just in case.
      if (pid > 0) {
        return pid ; Return the PID of the successfully launched process
      } else {
        ; This case might be rare as Run usually throws, but handle defensively.
        throw Error("Run command failed to launch the process (PID=" . pid . ").")
      }
    }

  } catch Error as e {
    if ShowErrors {
      ; MsgBox(
      ;   "RunDynamicAHK Error:`n`n"
      ;   . "File: " (e.File ?? "N/A") "`n"
      ;   . "Line: " (e.Line ?? "N/A") "`n"
      ;   . "Message: " e.Message "`n"
      ;   . "Extra: " (e.Extra ?? "N/A"),
      ;   "RunDynamicAHK Error", 16
      ; ) ; Stop icon
    }
    return false ; Indicate failure occurred
  } finally {
    ; --- Clean up the temporary file ---
    if DeleteTempFile {
      try FileDelete tempScriptPath
      catch {
        ; Ignore cleanup errors
      }
    }
  }
}

/**
 * Converts a data URL from clipboard to an image file
 * @param outputPath The path where the image will be saved. If empty, uses desktop with timestamp
 * @param clipboardText Optional clipboard text. If empty, gets from clipboard
 * @return True if successful, False otherwise
 */
DataUrlToImage(outputPath := "", clipboardText := "") {
  ; Get data URL from clipboard if not provided
  if (clipboardText = "") {
    clipboardText := A_Clipboard
  }

  ; Check if the clipboard contains a data URL
  if (!RegExMatch(clipboardText, "^data:image\/[^;]+;base64,")) {
    MsgBox("Clipboard does not contain a valid image data URL")
    return false
  }

  ; Extract the base64 data (everything after the comma)
  base64Data := RegExReplace(clipboardText, "^data:image\/[^;]+;base64,", "")

  ; Generate output path if not provided
  if (outputPath = "") {
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    outputPath := A_Desktop "\clipboard_image_" timestamp ".png"
  }

  try {
    ; Convert base64 to binary
    binary := Base64ToBinary(base64Data)

    ; Write binary data to file
    file := FileOpen(outputPath, "w")
    if !IsObject(file) {
      MsgBox("Error: Unable to open file for writing.`n" outputPath)
      return false
    }

    file.RawWrite(binary, binary.Size)
    file.Close()

    MsgBox("Image saved to:`n" outputPath)
    return true
  } catch Error as e {
    MsgBox("Error converting data URL to image:`n" e.Message)
    return false
  }
}

/**
 * Converts base64 string to binary data
 * @param base64 The base64 string to convert
 * @return Binary buffer
 */
Base64ToBinary(base64) {
  ; Create DllCall to CryptStringToBinary
  static CRYPT_STRING_BASE64 := 0x00000001

  ; Calculate length
  if (DllCall("crypt32\CryptStringToBinary", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", &
    size := 0, "Ptr", 0, "Ptr", 0)) {
    ; Allocate buffer
    buffer := Buffer(size, 0)

    ; Convert string
    if (DllCall("crypt32\CryptStringToBinary", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", buffer.Ptr,
      "UInt*", &size, "Ptr", 0, "Ptr", 0)) {
      return buffer
    }
  }

  throw Error("Failed to decode base64 string")
}

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

HiddenCommandLine(cmd) {
  static CREATE_NO_WINDOW := 0x08000000
  pipeRead := 0, pipeWrite := 0

  sa := Buffer(24, 0)
  NumPut("UInt", 24, sa, 0)      ; nLength
  NumPut("Ptr", 0, sa, 8)        ; lpSecurityDescriptor = NULL
  NumPut("Int", 1, sa, 16)       ; bInheritHandle = TRUE

  DllCall("CreatePipe", "Ptr*", &pipeRead, "Ptr*", &pipeWrite, "Ptr", sa, "UInt", 0)
  DllCall("SetHandleInformation", "Ptr", pipeRead, "UInt", 1, "UInt", 0)

  si := Buffer(104, 0)
  NumPut("UInt", 104, si, 0)
  NumPut("UInt", 0x100, si, 60)      ; STARTF_USESTDHANDLES
  NumPut("Ptr", pipeWrite, si, 88)   ; hStdOutput
  NumPut("Ptr", pipeWrite, si, 96)   ; hStdError

  pi := Buffer(24, 0)
  fullCmd := 'cmd.exe /c ' cmd

  ok := DllCall("CreateProcess", "Ptr", 0, "Str", fullCmd, "Ptr", 0, "Ptr", 0,
    "Int", 1, "UInt", CREATE_NO_WINDOW, "Ptr", 0, "Ptr", 0,
    "Ptr", si, "Ptr", pi)

  DllCall("CloseHandle", "Ptr", pipeWrite)

  output := ""
  buf := Buffer(4096)
  loop {
    bytesRead := 0
    success := DllCall("ReadFile", "Ptr", pipeRead, "Ptr", buf, "UInt", 4096, "UInt*", &bytesRead, "Ptr", 0)
    if (!success || bytesRead = 0)
      break
    output .= StrGet(buf, bytesRead, "CP0")
  }

  DllCall("WaitForSingleObject", "Ptr", NumGet(pi, 0, "Ptr"), "UInt", 0xFFFFFFFF)
  DllCall("CloseHandle", "Ptr", pipeRead)
  DllCall("CloseHandle", "Ptr", NumGet(pi, 0, "Ptr"))
  DllCall("CloseHandle", "Ptr", NumGet(pi, 8, "Ptr"))
  return output
}

;  MARK: Window functions

GroupAddWrapper(GroupName, WindowsTitles*) {
  for title in WindowsTitles {
    GroupAdd(GroupName, title)
  }
}

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

;  MARK: String functions

GetLine(text, lineNumber) {
  lines := StrSplit(text, "`n", "`r")
  return lines[lineNumber]
}

Join(Delimiter := " ", Wrapper := "", ValuesArray := []) {
  Result := ""
  for index, value in ValuesArray {
    Result .= value
    if (index < ValuesArray.Length)
      Result .= Delimiter
  }
  Result := Wrapper Result Wrapper
  return Result
}

HexToAscii(hexString) {
  ; Remove any spaces and commas from the input
  hexString := RegExReplace(hexString, "[,\s]", "")

  ; Initialize empty result string
  result := ""

  ; Process hex string two characters at a time
  loop StrLen(hexString) // 2 {
    ; Extract each pair of hex characters
    hexPair := SubStr(hexString, A_Index * 2 - 1, 2)
    ; Convert hex pair to decimal
    decimal := Integer("0x" . hexPair)
    ; Convert decimal to character if it's in printable ASCII range (32-126)
    if (decimal >= 32 && decimal <= 126)
      result .= Chr(decimal)
    else
      result .= "." ; Replace non-printable characters with a dot
  }

  return result
}

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
