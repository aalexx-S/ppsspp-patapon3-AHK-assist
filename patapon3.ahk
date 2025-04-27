#Requires AutoHotkey v2.0

; https://github.com/buliasz/AHKv2-Gdip/blob/master/Gdip_All.ahk
#include Gdip_All.ahk

CoordMode "Pixel", "Client"

;;-----------------------------------------------------------------------------------------------
;; This whole script is designed as a huge state machine
;; As you can probably see, I never expect it to grow this big so the code is super ugly and global variable everywhere
;; The macro is only meant to help reduce the brain dead grinding
;; This probably won't work for more compicated levels like dungeons
;; Iron door detection is annoying so it may not be a thing
;;-----------------------------------------------------------------------------------------------


pToken := Gdip_Startup()

stopPressed := 0
turboMode := 0
muted := 0
bossMode := 0
mode := 0
defeated := 0
seenBossDied := 0

mainGui := Gui()
mainGui.Title := "Patapon3 assist - by aalexx.S"
mainGui.OnEvent("Close", closeScript)
; create a hidden edit box to be default highlighted in case input spill over to the gui when switch focus mid executing
mainGui.Add("Edit", "w0 h0")
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
mainGui.tab := mainGui.Add("Tab3", "Section XS", ["Auto Level", "Auto command", "Sell Items"])
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
; dance-escape after closest boss died
escapeCheck := mainGui.Add("CheckBox", "Section XS", "Dance-escape after the closest boss died? (assumes going right)")
; stop when spot something big
somethingBigSpotted := mainGui.Add("CheckBox", "Section XS", "Stop when something big spotted?")
; ok/stop
oklevelbtn := mainGui.Add("Button","Section XS", "Ok")
stoplevelbtn := mainGui.Add("Button", "YS", "Stop")
oklh := mainGui.Add("Button", "YS", "?")
oklh.OnEvent("Click", okyLevelHelp)
oklevelbtn.OnEvent("Click", doOkAL)
stoplevelbtn.OnEvent("Click", doCancel)
debugBtn := mainGui.Add("Button", "YS", "Debug")
debugBtn.OnEvent("Click", doDebug)
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
;; [ Sell Items ]
mainGui.tab.UseTab(3)
; buttons
sih := mainGui.Add("Button", "Section", "?")
sih.OnEvent("Click", sellItemHelp)
lBtn := mainGui.Add("Button","Section XS w145 h30", "L")
lBtn.OnEvent("Click", sendL)
rBtn := mainGui.Add("Button","YS w145 h30", "R")
rBtn.OnEvent("Click", sendR)
nextCatBtn := mainGui.Add("Button", "YS w105 h30", "Next Catagory")
nextCatBtn.OnEvent("Click", nextCat)
mainGui.Add("Text", "Section XS","")
sellBtn := mainGui.Add("Button", "Section XS w300 h90", "Sell")
sellBtn.OnEvent("Click", sellItem)
sell4Btn := mainGui.Add("Button", "YS w50 h90", "Sell 4")
sell4Btn.OnEvent("Click", sell4Item)
sell8Btn := mainGui.Add("Button", "YS w50 h90", "Sell 8")
sell8Btn.OnEvent("Click", sell8Item)
nextBtn := mainGui.Add("Button", "Section XS w300 h90", "Next")
nextBtn.OnEvent("Click", nextItem)
scroll := mainGui.Add("Button", "YS w50 h90", "Scroll")
scroll.OnEvent("Click", scrollDown)
prevBtn := mainGui.Add("Button", "YS w50 h90", "Prev")
PrevBtn.OnEvent("Click", prevItem)
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
  MsgBox " - Choose an action to play repeatedly.`n - You should map the keyboard control 'a', 'd', 's' and 'w' to 'pata', 'pon', 'don' and 'chika'."
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

sellItemHelp(*) {
  MsgBox " - Just a easier way to sell all the junks.`n - You need to map keyboard 'q' and 'e' to controller 'L' and 'R'.`n - You need to open the storage yourself.n - Don't spam the sell button..."
}

doCancel(*) {
  retry.Value := 0
  global stopPressed := 1
  init()
}

doDebug(*) {
  init()
  scaleGlobal()
  WinActivate "PPSSPP"
  sleep 100
  detectBoss()
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
          naivePlayCommand(["s"], 1000)
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
          playCommand(["ddad"])
        }
      case "Defense":
        while (mode == 1) {
          playCommand(["wwad"])
        }
      case "Charged_Attack":
        while (mode == 1) {
          playCommand(["ddww", "ddad"])
        }
      case "Charged_Defense":
        while (mode == 1) {
          playCommand(["ddww", "wwad"])
        }
      case "March":
        while (mode == 1) {
          playCommand(["aaad"])
        }
      case "Dance":
        while (mode == 1) {
          playCommand(["adsw"])
        }
      case "Charge_Then_Keep_Attack":
        playCommand(["ddww"])
        while (mode == 1) {
          playCommand(["ddad"])
        }
      case "Walk_Attack":
        while (mode == 1) {
          playCommand(["aaad", "ddad"])
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

sendL(*) {
  global mode := 1
  WinActivate "PPSSPP"
  sleep 50
  naivePlayCommand(["q"], 80)
  mode := 0
}

sendR(*) {
  global mode := 1
  WinActivate "PPSSPP"
  sleep 50
  naivePlayCommand(["e"], 80)
  mode := 0
}

sellItem(*) {
  sellItemX(1)
}

sell4Item(*) {
  sellItemX(4)
}

sell8Item(*) {
  sellItemX(8)
}

nextItem(*) {
  global mode := 1
  WinActivate "PPSSPP"
  sleep 50
  naivePlayCommand(["l"], 80)
  mode := 0
}

scrollDown(*) {
  global mode := 1
  WinActivate "PPSSPP"
  sleep 50
  naivePlayCommand(["k", "k", "i", "i"], 80)
  mode := 0
}

prevItem(*) {
  global mode := 1
  WinActivate "PPSSPP"
  sleep 50
  naivePlayCommand(["j"], 80)
  mode := 0
}

nextCat(*) {
  global mode := 1
  WinActivate "PPSSPP"
  sleep 50
  naivePlayCommand(["w"], 80)
  mode := 0
}

; --- Functions ---

sellItemX(x) {
  global mode := 1
  sellBtn.Enabled := false
  sell4Btn.Enabled := false
  sell8Btn.Enabled := false
  scaleGlobal()
  WinActivate "PPSSPP"
  sleep 50
  Loop x {
    ; if the sell confirm is already up, close it. This can happen when the action is interrupted
    if (gdipGetPixelColor(228 * ratio, 102 * ratio) == "0xD73E3D") {
      naivePlayCommand(["d"], 80)
    }
    naivePlayCommand(["s"], 100)
    ; needs to verify the sell confirm is up
    if (gdipGetPixelColor(228 * ratio, 102 * ratio) == "0xD73E3D") {
      naivePlayCommand(["i", "s"], 80)
      sleep 100 ; there is a delay for the confirm window to close
    } else { ; unsellable basic item
      naivePlayCommand(["l"], 80)
    }
  }
  sellBtn.Enabled := true
  sell4Btn.Enabled := true
  sell8Btn.Enabled := true
  mode := 0
}

scaleGlobal() {
  global ratio := windowSize.Value * (A_ScreenDPI / 144.0)
  global beatSyncX1 := 7 * ratio
  global beatSyncY1 := 266 * ratio
  global beatSyncX2 := 5 * ratio
  global beatSyncY2 := 267 * ratio
  global bossDetectX1 := 24 * ratio
  global bossDetectY1 := 236 * ratio
  global bossDetectX2 := 456 * ratio
  global bossDetectY2 := 236 * ratio
  global checkDied := 1 * ratio + 1
}

init() {
  ; init gui
  mainGui["msg"].Value := "Action: x"
  mainGui["exmsg"].Value := ""
  mainGui["exmsg2"].Value := ""
  mainGui["exmsg3"].Value := ""
  ; reset modes
  global defeated := 0
  global mode := 0
  global bossMode := 0
  global seenBossDied := 0
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
  color := gdipGetPixelColor(x, y)
  while(color == "0x000000") {
    color := gdipGetPixelColor(x, y)
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
  color := gdipGetPixelColor(x, y)
  while(color != "0x000000") {
    color := gdipGetPixelColor(x, y)
    delta := A_TickCount - startTime
    if (delta > 600) {
      mode := 0
      break
    }
  }
}

;; play beats using pixel color. This is the core of the script.
;; the input command needs to follow the format [ "ddad", "aaad", ... ]
;; counts beats to sync timing so that the random ppsspp/patapon3 delay won't cumulate over time
;; Lag spike with in the same command will still affect the timing tho
playCommand(command) {
  global mode
  global beatDelayValue
  global btnDownDelay
  global btnUpDelay
  global beatSyncX2
  global beatSyncY2
  Loop command.Length {
    Loop Parse command[A_Index] {
      if (mode == 0) {
        break
      }
      mainGui["msg"].Value := Format("Action: {1} {2}", selection.Text, A_LoopField)
      send "{" A_LoopField " down}"
      sleep btnDownDelay
      send "{" A_LoopField " up}"
      sleep btnUpDelay
    }
    Loop 4 {
      detectBoss()
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
  global ratio
  ; this is a unique color during loot box screen
  if (gdipGetPixelColor(12 * ratio, 262 * ratio) == "0x35200A") {
    return 2
  } else if (gdipGetPixelColor(30 * ratio, 254 * ratio) == "0xEF4748" && gdipGetPixelColor(36 * ratio, 254 * ratio) == "0xEF4748") { ; the dpad input hint at camp or world map
    return 3
  } else if (gdipGetPixelColor(9 * ratio, 251 * ratio) == "0xEF4748") { ; the up/down dpad input hint
    if (gdipGetPixelColor(26 * ratio, 249 * ratio) != "0x000000" && gdipGetPixelColor(26 * ratio, 252 * ratio) != "0x000000" && gdipGetPixelColor(26 * ratio, 258 * ratio) != "0x000000") { ; the scroll icon
      return 0 ; this is the end result exp page
    }
    return 3 ; could be the barrack or level selection, no need to distinguish them
  } else if (gdipGetPixelColor(165 * ratio, 263 * ratio) != "0x000000" && gdipGetPixelColor(108 * ratio, 263 * ratio) == "0x000000" && gdipGetPixelColor(243 * ratio, 263 * ratio) == "0x000000") { ; command input hint
    return 1
  } else if (gdipGetPixelColor(170 * ratio, 89 * ratio) == "0xFFEDD2" && gdipGetPixelColor(304 * ratio, 126 * ratio) == "0xFFEDD2") {
    return 4
  } else if (gdipGetPixelColor(9 * ratio, 251 * ratio) == "0x000000") { ; highly possible that this is a loading screen or whatever
    return 0
  }
  return 0
}

getNoBossCommand() {
  switch levelNoBoss.Text {
    case "March-charged-attack":
      return ["aaad", "ddww", "ddad"]
    case "March-attack":
      return ["aaad", "ddad"]
    case "Jump-march-attack":
      return ["ssww", "aaad", "ddad"]
  }
  return ["aaad", "ddad"]
}

getBossCommand() {
  switch levelBoss.Text {
    case "Charged-attack":
      return ["ddww", "ddad"]
    case "Attack":
      return ["ddad"]
  }
  return ["dddad"]
}

;; auto plays a level
autoLevel() {
  ; boss state update needs to happen within a beat to detect salamender dying
  global bossMode, mode, seenBossDied
  global mode
  command0 := getNoBossCommand()
  command1 := getBossCommand()
  shouldEscape := 0
  charged := 0
  ; sync the first beat using the player input hint
  blockUntilBeat(beatSyncX1, beatSyncY1)
  mainGui["exmsg"].Value := "beat"
  blockUntilBlack(beatSyncX1, beatSyncY1)
  mainGui["exmsg"].Value := ""
  sleep beatDelayValue
  Loop {
    switch bossMode {
      case 0: ; no boss
        Loop command0.Length {
          charged := 0
          if (command0[A_Index] == "ddww") {
            charged := 1
          }
          playCommand([command0[A_Index]])
        } until (bossMode != 0 || mode != 1)
      case 1, 2: ; boss on screen, boss died
        Loop command1.Length {
          if (command1[A_Index] == "ddww" && charged == 1) {
            charged := 0
            A_Index := A_Index + 1 ; there msut be another command after a charge
          }
          playCommand([command1[A_Index]])
        } until ((bossMode != 1 && escapeCheck.Value == 1) || (bossMode == 0 && escapeCheck.Value != 1) || mode != 1)
        while ((seenBossDied == 1 || bossMode == 2) && escapeCheck.Value == 1) {
          seenBossDied := 0
          shouldEscape := 1
          playCommand(["adsw"])
        }
        if ((seenBossDied == 1 || shouldEscape == 1 ) && escapeCheck.Value == 1) {
          shouldEscape := 0
          seenBossDied := 0
          playCommand(["dada"])
        }
    }
  } until (mode != 1)
  ; in case the level ended, we want to continue the macro unless we clicking off the window
  if (stopPressed == 0 && WinActive("PPSSPP")) {
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
  if (gdipGetPixelColor(188 * ratio, 84 * ratio) == "0xD59095" && gdipGetPixelColor(288 * ratio, 82 * ratio) == "0xD59095") {
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
; optimized with gdip library.
detectBoss() {
  global bossMode
  global bossDetectX1, bossDetectY1, bossDetectX2, bossDetectY2, checkDied
  WinGetClientPos &X, &Y, &W, &H, "PPSSPP"
  width := bossDetectX2 - bossDetectX1
  pBitmap := Gdip_BitmapFromScreen(X + bossDetectX1 "|" Y + bossDetectY1 "|" width "|" 1)
  ; Gdip_SaveBitmapToFile(pBitmap, "test.png")
  bossMode := 0
  mainGui["exmsg2"].Value := ""
  Loop width {
    c := Gdip_GetPixel(pBitmap, A_Index - 1, 0) ; this f'ing thing starts indexing from 0
    B := c & 0xFF
    G := (c & 0xFF00) >> 8
    R := (c & 0xFF0000) >> 16
    if (0xFF - R < 0x64 && 0xFF - G < 0x64 && 0xFF - B < 0x64) {
      mainGui["exmsg2"].Value := "Boss on screen"
      bossMode := 1
      pos := A_Index - 1
      Loop checkDied {
        if (pos + A_Index >= width) {
          break
        }
        c2 := Gdip_GetPixel(pBitmap, pos + A_Index, 0)
        B := c2 & 0xFF
        G := (c2 & 0xFF00) >> 8
        R := (c2 & 0xFF0000) >> 16
        if (R < 0xF && G < 0xF && B < 0xF) { ; black won't be total black due to alpha
          mainGui["exmsg2"].Value := "Boss died"
          bossMode := 2
          global seenBossDied := 1
          break
        }
      }
      break
    }
  }
  Gdip_DisposeImage(pBitmap)
}

gdipGetPixelColor(tx, ty) {
  tx := Round(tx)
  ty := Round(ty)
  WinGetClientPos &X, &Y, &W, &H, "PPSSPP"
  pBitmap := Gdip_BitmapFromScreen(X + tx "|" Y + ty "|" 1 "|" 1)
  c := Gdip_GetPixel(pBitmap, 0, 0)
  Gdip_DisposeImage(pBitmap)
  return Format("0x{:06X}", c & 0xFFFFFF)
}
