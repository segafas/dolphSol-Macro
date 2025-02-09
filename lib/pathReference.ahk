#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

; Reference script for paths

getINIData(path){
    FileRead, retrieved, %path%

    retrievedData := {}
    readingPoint := 0

    if (!ErrorLevel){
        ls := StrSplit(retrieved,"`r`n")
        for i,v in ls {
            isHeader := RegExMatch(v,"\[(.*)]")
            if (v && readingPoint && !isHeader){
                RegExMatch(v,"(.*)(?==)",index)
                RegExMatch(v,"(?<==)(.*)",value)
                if (index){
                    retrievedData[index] := value
                }
            } else if (isHeader){
                readingPoint := 1
            }
        }
    } else {
        MsgBox, An error occurred while reading %path% data, please review the file.
        return
    }
    return retrievedData
}
global options = getINIData("..\settings\config.ini")

global regWalkFactor := 1.25 ; since i made the paths all with vip, normalize

getWalkTime(d){
    return d*(1 + (regWalkFactor-1)*(1-options.VIP))
}

walkSleep(d){
    Sleep, % getWalkTime(d)
}

press(k, duration := 50) {
    Send, {%k% Down}
    walkSleep(duration)
    Send, {%k% Up}
}
press2(k, k2, duration := 50) {
    Send, {%k% Down}
    Send, {%k2% Down}
    walkSleep(duration)
    Send, {%k% Up}
    Send, {%k2% Up}
}

reset() {
    press("Esc",150)
    Sleep, 50
    press("r",150)
    Sleep, 50
    press("Enter",150)
    Sleep, 50
}
jump() {
    press("Space")
}

collect(num){
    if (!options["ItemSpot" . num]){
        return
    }
    Loop, 6 
    {
        Send {f}
        Sleep, 75
    }
    Send {e}
    Sleep, 50
}

isFullscreen() {
	WinGetPos,,, w, h, Roblox
	return (w = A_ScreenWidth && h = A_ScreenHeight)
}

GetRobloxHWND()
{
	if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe"))
		return hwnd
	else if (WinExist("Roblox ahk_exe ApplicationFrameHost.exe"))
	{
		ControlGet, hwnd, Hwnd, , ApplicationFrameInputSinkWindow1
		return hwnd
	}
	else
		return 0
}

getRobloxPos(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := ""){
    rHwnd := GetRobloxHWND()
    WinGetPos, x, y, width, height, ahk_id %rHwnd%

    if (!isFullscreen()){
        height -= 39
        width -= 16
        x += 8
        y += 31
    }
}

getColorComponents(color){
    return [color & 255, (color >> 8) & 255, (color >> 16) & 255]
}

compareColors(color1, color2) ; determines how far apart 2 colors are
{
    color1V := getColorComponents(color1)
    color2V := getColorComponents(color2)

    cV := [color1V[1] - color2V[1], color1V[2] - color2V[2], color1V[3] - color2V[3]]
    dist := Abs(cV[1]) + Abs(cV[2]) + Abs(cV[3])
    return dist
}

closeChat(){
    getRobloxPos(pX,pY,width,height)
    PixelGetColor, chatCheck, % pX + 75, % pY + 12, RGB
    if (compareColors(chatCheck,0xffffff) < 16){ ; is chat open??
        MouseMove, % pX + 75, % pY + 12
        Sleep, 300
        MouseClick
        Sleep, 100
    }
}

global menuBarOffset := 10 ;10 pixels from left edge

getMenuButtonPosition(num, ByRef posX := "", ByRef posY := ""){ ; num is 1-7, 1 being top, 7 only existing if you are the private server owner
    getRobloxPos(rX, rY, width, height)

    menuBarVSpacing := 10.5*(height/1080)
    menuBarButtonSize := 58*(width/1920)
    menuEdgeCenter := [rX + menuBarOffset, rY + (height/2)]
    startPos := [menuEdgeCenter[1]+(menuBarButtonSize/2),menuEdgeCenter[2]+(menuBarButtonSize/4)-(menuBarButtonSize+menuBarVSpacing-1)*3.5] ; 3 to 4 because easter
    
    posX := startPos[1]
    posY := startPos[2] + (menuBarButtonSize+menuBarVSpacing)*(num-1)

    MouseMove, % posX, % posY
}

clickMenuButton(num){
    getMenuButtonPosition(num, posX, posY)
    MouseMove, posX, posY
    Sleep, 200
    MouseClick
}

alignCamera(){
    closeChat()
    Sleep, 200

    clickMenuButton(2)
    Sleep, 500
    getRobloxPos(rX,rY,rW,rH)
    MouseMove, % rX + rW*0.15, % rY + 44 + rH*0.05 + options.BackOffset
    Sleep, 200
    MouseClick
    Sleep, 500
}

global azertyReplace := {"w": "z", "a": "q"} 

sendKey(key, type = ""){
 azertyKey := azertyReplace[key]
 key := options.AzertyLayout && azertyKey ? azertyKey : key
 
 Send {%key% %type%}
}

arcaneTeleport(){
    press("x",50)
}