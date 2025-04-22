#Requires AutoHotkey v2.0

CoordMode "Pixel", "Client"

;;-----------------------------------------------------------------------------------------------
;; This whole script is designed as a huge state machine
;; As you can probably see, I never expect it to grow this big so the code is super ugly and global variable everywhere
;; The macro is only meant to help reduce the brain dead grinding
;; This probably won't work for more compicated levels like dungeons
;; Iron door detection is annoying so it may not be a thing
;;-----------------------------------------------------------------------------------------------

stopPressed := 0
turboMode := 0
muted := 0
bossMode := 0
mode := 0
defeated := 0

mainGui := Gui()
mainGui.Title := "Patapon3 assist - by aalexx.S"
mainGui.OnEvent("Close", closeScript)
; choose window size
mainGui.Add("Text", "Section XM","Choose window size (1-10x):")
windowSize := mainGui.Add("Edit", "YS")
mainGui.Add("UpDown", "vMyUpDown2 Range1-10", 5)
wsh := mainGui.Add("Button", "Ys", "?")
wsh.OnEvent("Click", windowSizeHelp)
; beat delay
mainGui.Add("Text", "Section XS", "Choose beat delay (0-235)")
delay := mainGui.Add("Edit", "YS")
mainGui.Add("UpDown", "vMyUpDown Range0-235", 150)
bdh := mainGui.Add("Button", "Ys", "?")
bdh.OnEvent("Click", beatDelayHelp)
; mute
muteCheck := mainGui.Add("CheckBox", "Section XM", "Mute while playing? (map 'm' to mute)")
;; Tabs
mainGui.tab := mainGui.Add("Tab3", "Section XS", ["Auto Level", "Auto command"])
;; [ Auto Level ]
mainGui.tab.UseTab(1)
; field select
mainGui.Add("Text", "Section", "Choose field:")
field := mainGui.Add("DropDownList", "YS", ["Patapon Training Grounds", "Field of Angry Giants", "Arena of Valour", "Cave of Valour", "Snow Field of Sullied Tears", "Racing Alley of Purity", "Tower of Purity", "Plateau of Pompous Wings", "Range of Justice", "Castle of Justice", "Greedy Mask Jungle", "Arena of Earnestness", "Estate of Earnestness", "Bottomless Stomach Desert", "Racing Alley of Restraint", "Labyrinth of Restraint", "Volcano Zone of the Lazy Demon", "Range of Adamance", "Evilmass of Adamance", "Savabbah of Envious Eyes", "Arena of Tolerance", "Tomb of Tolerance", "Depths of Rage", "Heights of Lust", "Dungeon of Pride", "Basement of Greed", "Depths of Gluttony", "Heights of Indolence", "Depths of Jealousy"])
dlc := mainGui.Add("CheckBox", "YS", "Dark World?")
fs := mainGui.Add("Button", "YS", "?")
fs.OnEvent("Click", fieldHelp)
; choose level (top down order)
mainGui.Add("Text", "Section XS", "Choose Level:")
topdownLevel := mainGui.Add("Edit", "YS")
mainGui.Add("UpDown", "vMyUpDown4 Range1-100", 1)
tdl := mainGui.Add("Button", "Ys", "?")
tdl.OnEvent("Click", topdownLevelHelp)
; normal march (no boss)
mainGui.Add("Text", "Section XS", "Choose normal command (when no boss):")
levelNoBoss := mainGui.Add("DropDownList", "YS Choose1", ["March-charged-attack", "March-attack", "Jump-march-attack"])
lmh := mainGui.Add("Button", "YS", "?")
lmh.OnEvent("Click", levelMarchHelp)
; fight boss
mainGui.Add("Text", "Section XS", "Choose boss fight command:")
levelBoss := mainGui.Add("DropDownList", "YS Choose1", ["Charged-attack", "Attack"])
fbh := mainGui.Add("Button", "YS", "?")
fbh.OnEvent("Click", fightBossHelp)
; reset after defeated
resetCheck := mainGui.Add("CheckBox", "Section XS", "")
failBehavior := mainGui.Add("DropDownList", "YS Choose1", ["Reset stage level", "Stop"])
mainGui.Add("Text", "YS", "after failing quest")
resetCount := mainGui.Add("Edit", "YS")
mainGui.Add("UpDown", "vMyUpDown6 Range1-10", 5)
mainGui.Add("Text", "YS", "time(s).")
; escape after boss leave screen
escapeCheck := mainGui.Add("CheckBox", "Section XS", "Escape after boss dissapear from screen?")
; stop when spot something big
somethingBigSpotted := mainGui.Add("CheckBox", "Section XS", "Stop when something big spotted?")
; ok/stop
oklevelbtn := mainGui.Add("Button","Section XS", "Ok")
stoplevelbtn := mainGui.Add("Button", "YS", "Stop")
oklh := mainGui.Add("Button", "YS", "?")
oklh.OnEvent("Click", okyLevelHelp)
oklevelbtn.OnEvent("Click", doOkAL)
stoplevelbtn.OnEvent("Click", doCancel)
;; [ Auto Command ]
mainGui.tab.UseTab(2)
; choose action
mainGui.Add("Text", "Section", "Choose command:")
selection := mainGui.Add("DropDownList", "YS", ["Attack", "Defense", "Charged_Attack", "Charged_Defense", "March", "Dance", "Charge_Then_Keep_Attack", "Walk_Attack"])
cah := mainGui.Add("Button", "Ys", "?")
cah.OnEvent("Click", chooseActionHelp)
; turbo
turbo := mainGui.Add("CheckBox", "Section XS", "2x speed?")
th := mainGui.Add("Button", "Ys", "?")
th.OnEvent("Click", turbo_help)
; retry
retry := mainGui.Add("CheckBox", "Section XS", "Auto Retry?")
rh := mainGui.Add("Button", "Ys", "?")
rh.OnEvent("Click", retryHelp)
; ok/stop
okbtn := mainGui.Add("Button","Section XS", "Ok")
stopbtn := mainGui.Add("Button", "YS", "Stop")
okh := mainGui.Add("Button", "YS", "?")
okh.OnEvent("Click", playHelp)
okbtn.OnEvent("Click", doOkAC)
stopbtn.OnEvent("Click", doCancel)
;; misk msg
mainGui.tab.UseTab()
mainGui.Add("Text", "w370 XM vmsg", "Action: x")
mainGui.Add("Text", "w370 XM vexmsg", "")
mainGui.Add("Text", "w370 XM vexmsg2", "")
mainGui.Add("Text", "w370 XM vexmsg3", "")
mainGui.show()
return

; --- Bottons ---
closeScript(*) {
  ExitApp()
}

chooseActionHelp(*) {
  MsgBox " - Choose an action to play repeatedly.`n - You should map the keyboard control 'a', 'd', 's' and 'w' to 'pata', 'pon', 'don' and 'chika'.`n - The PPSSPP window has to be on the main monitor. I can't get pixel color detection to work on second or third monitors."
}

beatDelayHelp(*) {
  MsgBox " - The delay between the beat blinker become black and the next perfect beat timing in ms.`n - Make it larger if the nodes are playing too early and vise versa.`n - You can use the first node played to check if the setting is good.`n - This is not automatable since we can't detect perfect beat happening. Relying on the previous played beat will cause beat timing offset to accumulate and fail the combo eventually.`n - Assuming the random doesn't happen too often or happen at a regular bases, with a good beat delay, the program can hit almost all perfect beats even with 2x speed."
}

fieldHelp(*) {
  MsgBox " - Choose the field that contains the level to auto repeat.`n - Check the DLC box if it is a DLC level.`n - You should map the keyboard control 'a', 'd', 's' and 'w' to 'pata', 'pon', 'don' and 'chika'.`n - You should map the keyboard key 'i', 'k', 'j' and 'l' to 'up', 'down', 'left' and 'right'.`n - The 'don' button (which should be 's') will also be used as confirm.`n - You should map keyboard 'g' to 'start' button.`n - The PPSSPP window has to be on the main monitor. I can't get pixel color detection to work on second or third monitors."
}

topdownLevelHelp(*) {
  MsgBox " - From top to bottom, the number of  order of the level to play repeatedly.`n - For example, 'Hunt the Cyclops' in 'Field of Angry Giants' is number 3."
}

okyLevelHelp(*) {
  MsgBox " - Press 'OK' to start playing the selected level repeatedly until press 'stop'.`n - The program auto focus on your 'PPSSPP' window.`n - Clicking off the PPSSPP window, failing to detect beats or failing combo will cause the macro to stop.`n - Press 'OK' will cause the macro attempting to resume the process.`n - This does't support turbo mode for reliable hero attack.`n - No iron door detection."
}

levelMarchHelp(*) {
  MsgBox " - The commands to loop when there is no boss on screen.`n - This should deal with small enemies and rocks/buildings."
}

fightBossHelp(*) {
  MsgBox " - The commands to loop when there is boss on screen.`n - This will keep looping and won't attempt to defend or escape."
}

turbo_help(*) {
  MsgBox " - You need to set control key 't' to toggle turbo speed.`n - You need to set graphic - alternative speed 1 to 200% and disable the second one.`n - 2x is somewhat reliable. Any faster the random delay happens too much that even checking pixel color change can't accommodate.`n - Auto turbo control may screw up sometimes if you click off the window while the macro is trying to toggle speed. In this case you have to manually turn OFF the turbo mode before starting the next action."
}

retryHelp(*) {
  MsgBox " - Auto retry on failure.`n - Failures can happen when missing combo, which is usually caused by bad beat delay or missing window focus on pppsspp.`n - Will try to focus on PPSSPP again."
}

windowSizeHelp(*) {
  MsgBox " - Choose the window size. Only support 1x-10x.`n - The pixel needs to be on the main monitor. The macro inspect the bottom left corner of the PPSSPP window."
}

playHelp(*) {
  MsgBox " - Press 'OK' to start playing the selected action repeatedly until press 'stop'.`n - The program auto focus on your 'PPSSPP' window.`n - Clicking off the PPSSPP window, failing to detect beats or failing combo will cause the macro to stop (unless enable retry)."
}

doCancel(*) {
  retry.Value := 0
  global stopPressed := 1
  init()
}

; --- Main Logic ---

doOKAL(*) {
  init()
  ; preprocess
  global stopPressed := 0
  global mode := 1
  global beatDelayValue := delay.Text
  global btnDownDelay := 200
  global btnUpDelay := 290
  scaleGlobal()
  WinActivate "PPSSPP"
  muteGame()
  loop {
    gameStage := resolveGameState()
    switch gameStage {
      case 0: ; loading screen or whatever
        mainGui["exmsg3"].Value := "Loading screen - keep pressing confirm"
        loop {
          naivePlayCommand(["s"], 500)
        } until (resolveGameState() != 0 || mode != 1)
      case 1: ; in level
        mainGui["exmsg3"].Value := "In level - play level"
        autoLevel()
      case 2: ; loot box
        mainGui["exmsg3"].Value := "Loot box - open box"
        global defeated := 0 ; reset since we won
        loop {
          naivePlayCommand(["s", "j"], 500)
        } until (resolveGameState() != 2 || mode != 1)
      case 3: ; camp/map
        global defeated
        tmp := ""
        if (defeated > 0) {
          tmp := "(defeated " defeated " times)"
        }
        mainGui["exmsg3"].Value := "Camp/map - enter level " tmp
        selectLevel()
      case 4: ; proceed to next level
        mainGui["exmsg3"].Value := "proceed to next level"
        naivePlayCommand(["i", "s", "i", "s"], 200)
    }
  } until (mode != 1)
  doCancel()
  mainGui["exmsg3"].Value := "Stopped"
}

doOkAC(*) {
  init()
  ; preprocess
  global stopPressed := 0
  global mode := 1
  global turboMode := 0
  global beatDelayValue := delay.Text
  global btnDownDelay := 200
  global btnUpDelay := 290
  scaleGlobal()
  if (turbo.Value == 1) {
    beatDelayValue := Floor(beatDelayValue/2)
	btnDownDelay := Floor(btnDownDelay/2)
	btnUpDelay := Floor(btnUpDelay/2)
  }
  action := selection.Text
  Loop {
    WinActivate "PPSSPP"
    muteGame()
    if (turbo.Value == 1 && turboMode == 0) {
	  turboMode := 1
      send "{t down}"
      sleep 100
      send "{t up}"
      sleep 200
    }
    ; sync the first beat using the player input hint
    blockUntilBeat(beatSyncX1, beatSyncY1)
    mainGui["exmsg"].Value := "beat"
    blockUntilBlack(beatSyncX1, beatSyncY1)
    mainGui["exmsg"].Value := ""
    sleep beatDelayValue
    ; do action
    switch action {
      case "Attack":
	    while (mode == 1) {
	      playCommand(["d", "d", "a", "d"])
        }
      case "Defense":
        while (mode == 1) {
	      playCommand(["w", "w", "a", "d"])
        }
      case "Charged_Attack":
        while (mode == 1) {
	      playCommand(["d", "d", "w", "w", "d", "d", "a", "d"])
        }
      case "Charged_Defense":
        while (mode == 1) {
	      playCommand(["d", "d", "w", "w", "w", "w", "a", "d"])
        }
      case "March":
        while (mode == 1) {
	      playCommand(["a", "a", "a", "d"])
        }
      case "Dance":
        while (mode == 1) {
	      playCommand(["a", "d", "s", "w"])
        }
      case "Charge_Then_Keep_Attack":
        playCommand(["d", "d", "w", "w"])
        while (mode == 1) {
	      playCommand(["d", "d", "a", "d"])
        }
      case "Walk_Attack":
        while (mode == 1) {
	      playCommand(["a", "a", "a", "d", "d", "d", "a", "d"])
        }
    }
    if (retry.Value == 1) {
      mode := 1
    }
  } Until retry.Value == 0
  mainGui["exmsg"].Value := Format("Stop {1} {2}", mode, action)
  doCancel()
  mainGui["exmsg3"].Value := "Stopped"
}

; --- Functions ---

scaleGlobal() {
  global ratio := windowSize.Value
  global beatSyncX1 := 7 * ratio
  global beatSyncY1 := 266 * ratio
  global beatSyncX2 := 5 * ratio
  global beatSyncY2 := 267 * ratio
  global bossDetectX1 := 24 * ratio
  global bossDetectY1 := 236 * ratio
  global bossDetectX2 := 456 * ratio
  global bossDetectY2 := 236 * ratio
}

init() {
  mainGui["msg"].Value := "Action: x"
  mainGui["exmsg"].Value := ""
  mainGui["exmsg2"].Value := ""
  mainGui["exmsg3"].Value := ""
  ; reset modes
  global defeated := 0
  global mode := 0
  global bossMode := 0
  global turboMode
  global muted
  if (turboMode == 1) {
	WinActivate "PPSSPP"
    sleep 100
    send "{t down}"
    sleep 50
    send "{t up}"
    turboMode := 0
  }
  if (muted == 1) {
	WinActivate "PPSSPP"
    sleep 100
    send "{m down}"
    sleep 50
    send "{m up}"
  }
  muted := 0
}

muteGame() {
  global muted
  if (muteCheck.Value == 1 && muted == 0) {
	WinActivate "PPSSPP"
    send "{m down}"
    sleep 50
    send "{m up}"
    muted := 1
  }
}

;; Check the pixel on the beat visual effect. The coor is window client coordinate
blockUntilBeat(x, y) {
  global mode
  if (mode == 0) {
    return
  }
  startTime := A_TickCount
  color := PixelGetColor(x, y)
  while(color == "0x000000") {
    color := PixelGetColor(x, y)
	delta := A_TickCount - startTime
	if (delta > 600) {
	  mode := 0
	  break
	}
  }
}

blockUntilBlack(x, y) {
  global mode
  if (mode == 0) {
    return
  }
  startTime := A_TickCount
  color := PixelGetColor(x, y)
  while(color != "0x000000") {
    color := PixelGetColor(x, y)
	delta := A_TickCount - startTime
	if (delta > 600) {
	  mode := 0
	  break
	}
  }
}

;; play beats using pixel color. This is the core of the script.
;; the input command length has to be divisible by 4. I didn't explicitly check it
;; counts beats to sync timing so that the random ppsspp/patapon3 delay won't cumulate over time
;; Lag spike with in the same command will still affect the timing tho
playCommand(command) {
  global mode
  global beatDelayValue
  global btnDownDelay
  global btnUpDelay
  global beatSyncX2
  global beatSyncY2
  Loop command.Length/4 {
	offset := (A_Index - 1) * 4
    Loop 4 {
	  if (mode == 0) {
		break
	  }
	  mainGui["msg"].Value := Format("Action: {1} {2}", selection.Text, command[offset + A_Index])
	  send "{" command[offset + A_Index] " down}"
	  sleep btnDownDelay
	  send "{" command[offset + A_Index] " up}"
	  sleep btnUpDelay
	}
    detectBoss()
    Loop 4 {
	  blockUntilBeat(beatSyncX2, beatSyncY2)
	  mainGui["exmsg"].Value := "beat"
	  blockUntilBlack(beatSyncX2, beatSyncY2)
	  mainGui["exmsg"].Value := ""
	}
	sleep beatDelayValue
  }
}

;; resolveGameState
;; 0 = Can't determine or a loading screen. Just keep pressing confirm.
;; 1 = in level
;; 2 = loot box
;; 3 = in camp/world map
;; 4 = proceed to next level
resolveGameState() {
  global ratio := windowSize.Value
  ; this is a unique color during loot box screen
  if (PixelGetColor(12 * ratio, 262 * ratio) == "0x35200A") {
    return 2
  } else if (PixelGetColor(30 * ratio, 254 * ratio) == "0xEF4748" && PixelGetColor(36 * ratio, 254 * ratio) == "0xEF4748") { ; the dpad input hint at camp or world map
    return 3
  } else if (PixelGetColor(9 * ratio, 251 * ratio) == "0xEF4748") { ; the up/down dpad input hint
    if (PixelGetColor(26 * ratio, 249 * ratio) != "0x000000" && PixelGetColor(26 * ratio, 252 * ratio) != "0x000000" && PixelGetColor(26 * ratio, 258 * ratio) != "0x000000") { ; the scroll icon
      return 0 ; this is the end result exp page
    }
    return 3 ; could be the barrack or level selection, no need to distinguish them
  } else if (PixelGetColor(165 * ratio, 263 * ratio) != "0x000000" && PixelGetColor(108 * ratio, 263 * ratio) == "0x000000" && PixelGetColor(243 * ratio, 263 * ratio) == "0x000000") { ; command input hint
    return 1
  } else if (PixelGetColor(170 * ratio, 89 * ratio) == "0xFFEDD2" && PixelGetColor(304 * ratio, 126 * ratio) == "0xFFEDD2") {
    return 4
  } else if (PixelGetColor(9 * ratio, 251 * ratio) == "0x000000") { ; highly possible that this is a loading screen or whatever
    return 0
  }
  return 0
}

getNoBossCommand() {
  switch levelNoBoss.Text {
    case "March-charged-attack":
      return [["a", "a", "a", "d"], ["d", "d", "w", "w"], ["d", "d", "a", "d"]]
    case "March-attack":
      return [["a", "a", "a", "d"], ["d", "d", "a", "d"]]
    case "Jump-march-attack":
      return [["s", "s", "w", "w"], ["a", "a", "a", "d"], ["d", "d", "a", "d"]]
  }
  return [["a", "a", "a", "d"], ["d", "d", "a", "d"]]
}

getBossCommand() {
  switch levelBoss.Text {
    case "Charged-attack":
      return [["d", "d", "w", "w"], ["d", "d", "a", "d"]]
    case "Attack":
      return [["d", "d", "a", "d"]]
  }
  return [["d", "d", "a", "d"]]
}

;; auto plays a level
autoLevel() {
  ; boss state update needs to happen within a beat to detect salamender dying
  global bossMode
  global mode
  command0 := getNoBossCommand()
  command1 := getBossCommand()
  seenBoss := 0
  ; sync the first beat using the player input hint
  blockUntilBeat(beatSyncX1, beatSyncY1)
  mainGui["exmsg"].Value := "beat"
  blockUntilBlack(beatSyncX1, beatSyncY1)
  mainGui["exmsg"].Value := ""
  sleep beatDelayValue
  Loop {
    switch bossMode {
      case 0: ; no boss
        if (escapeCheck.Value == 1 && seenBoss == 1) {
          playCommand(["d", "a", "d", "a"])
        }
        seenBoss := 0
        Loop command0.Length {
          playCommand(command0[A_Index])
        } until (bossMode != 0 || mode != 1)
      case 1, 2: ; boss on screen, 2 is reserved for salamander detection
        seenBoss := 1
        Loop command1.Length {
          playCommand(command1[A_Index])
        } until (bossMode == 0 || mode != 1)
    }
  } until (mode != 1)
  if (stopPressed == 0 && WinActive("PPSSPP")) { ; in case the level ended
    mode := 1
  }
}

;; returns the control required to select the field
resolveFieldSelectSequence() {
  re := []
  if (field.Value == 1) {
    re.Push("j")
    return re
  }
  if (dlc.Value == 0) {
    if (field.Value > 1 && field.Value <= 22) { ; Tomb of Tolerance
      loop field.Value - 1 {
        re.Push('l')
      }
      return re
    } else if (field.Value > 22 && field.Value <= 29) {
      loop (field.Value - 22) * 3 {
        re.Push("l")
      }
      re.Push("k")
      return re
    }
  } else {
    if (field.Value == 2 || field.Value == 5 || field.Value == 8 || field.Value == 11 || field.Value == 14 || field.Value == 17 || field.Value == 20) { ; the fields
      loop (field.Value + 1) / 3 {
        re.Push("l")
      }
      return re
    } else if (field.Value == 22) { ; Tomb of Tolerance
      loop 8 {
        re.Push("l")
      }
      return re
    } else if (field.Value == 29) { ; Depths of Jealousy
      loop 8 {
        re.Push("l")
      }
      re.Push("k")
      return re
    }
  }
  return []
}

;; something big?
somethingBig() {
  global ratio
  if (PixelGetColor(188 * ratio, 84 * ratio) == "0xD59095" && PixelGetColor(288 * ratio, 82 * ratio) == "0xD59095") {
    return 1
  }
  return 0
}

;; naively press the buttons in sequence
naivePlayCommand(sequence, delay) {
  global mode
  Loop sequence.Length {
    if (mode == 0 || !WinActive("PPSSPP")) {
      return
    }
    send "{" sequence[A_Index] " down}"
    sleep 50
    send "{" sequence[A_Index] " up}"
    sleep delay
  }
}

;; select level
selectLevel() {
  global mode
  global defeated
  fs := resolveFieldSelectSequence()
  if (fs.length == 0) {
    mode := 0 ; invalid field
    return
  }
  if (resetCheck.Value == 1 && defeated >= resetCount.Value && failBehavior.Value == 2) { ; stop
    mode := 0
    return
  }
  ; resets the cursor position
  naivePlayCommand(["d", "d", "d"], 600) ; back out from whatever menu
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{j down}"
  sleep 2000
  send "{j up}"
  sleep 150
  naivePlayCommand(["l", "l", "l", "l", "l"], 150)
  sleep 200 ; wait for the dialog to fully pop up
  if (somethingBig() == 1 && somethingBigSpotted.Value == 1) {
    mode := 0
    return
  }
  naivePlayCommand(["l", "s"], 150) ; enter the world map
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{j down}"
  sleep 3000
  send "{j up}"
  sleep 150
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{l down}"
  sleep 50
  send "{l up}"
  sleep 150
  ; should be highlighting the obelisk now
  if (dlc.Value == 1) {
    naivePlayCommand(["s"], 10)
    sleep 3000 ; wait for dlc data to load
  }
  naivePlayCommand(fs, 150)
  naivePlayCommand(["s"], 150)
  loop topdownLevel.Value - 1 {
    naivePlayCommand(["k"], 150)
  }
  if (mode == 0) {
    return
  }
  send "{g down}" ; hold start to bring up the reset level option
  send "{s down}"
  sleep 50
  send "{s up}"
  sleep 3000 ; wait for barracks menu to pop up, dlc levels can be really slow sometimes
  send "{g up}" ; the "ok to deploy" menu should be up at this point
  sleep 50
  if (resetCheck.Value == 1 && defeated >= resetCount.Value && failBehavior.Value == 1) { ; reset
    naivePlayCommand(["d", "k", "k", "k", "k", "k", "k", "k", "s", "i", "s"], 150) ; This will pop us back to the camp
    defeated := 0
    return
  }
  naivePlayCommand(["i", "s"], 150) ; enter the level
  defeated := defeated + 1 ; will be reset to 0 if we won and entered a loot box screen
  return
}

;; reset world map slection
resetWorldMapSelection() {
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{j down}"
  sleep 3000
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{j up}"
  sleep 50
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{l down}"
  sleep 50
  if (mode == 0 || !WinActive("PPSSPP")) {
    return
  }
  send "{l up}"
  sleep 150
}

;; search boss bar
; This should be optimized more
detectBoss() {
  global ratio
  global bossMode
  global mode
  if (PixelSearch(&x, &y, bossDetectX1, bossDetectY1, bossDetectX2, bossDetectY2, "0xCFCFCF", 32)) {
    mainGui["exmsg2"].Value := "Boss on screen"
    bossMode := 1
  } else {
    mainGui["exmsg2"].Value := ""
    bossMode := 0
  }
}
