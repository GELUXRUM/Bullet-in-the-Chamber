scriptName BitCh_LowerWeaponScript extends quest

group actors
	actor property playerRef auto
endGroup

group perks
	perk property fixSpeedWalkPerk auto
endGroup

Group animations
	action property actionSheath auto
	action property actionGunDown auto
	idle property gunRelaxedRootPlayer auto
endGroup

group bools
	bool property MCMFixSpeedWalk = true auto
	bool property enableHolster = true auto

endGroup

group globals
	globalVariable property longPressTimer auto
endGroup

; used to prevent twp short presses from activating a long press
bool inCooldown = false
; used to track short/long keypresses
bool hotKeyIsDown = false
; timer ID for the long-press hotkey
int lolsterTimerID = 666

event onInit()
	registerCustomEvents()
	if MCMFixSpeedWalk
		playerRef.addPerk(fixSpeedWalkPerk)
	endIf
endEvent

event actor.onPlayerLoadGame(actor akSender)
	registerCustomEvents()
	if MCMFixSpeedWalk
		; resetting the perk periodically is required, lest you fall victim to the ability condition bug
		playerRef.removePerk(fixSpeedWalkPerk)
		playerRef.addPerk(fixSpeedWalkPerk)
	endIf
endEvent

event onControlDown(string sControl)
    if sControl == "Lolster"
        startTimer(longPressTimer.getValue(), lolsterTimerID)
        hotkeyIsDown = true
    endIf
endEvent

event onControlUp(string control, float time)
    ;/ if the bool is true, timer hasn't ended yet
    meaning the player released before long-press
    has been detected /;
    if hotkeyIsDown == true
        ; player released the button, cancel the timer
        cancelTimer(lolsterTimerID)
        ; this isn't a long-press, so we lower
        playerRef.playIdleAction(actionGunDown)
		playerRef.playIdle(gunRelaxedRootPlayer)
        hotkeyIsDown = false
    endIf
endEvent

event onTimer(int aiTimerID)
    ; timer ended, so we check ammo
    if aiTimerID == lolsterTimerID
        hotkeyIsDown = false
        playerRef.playIdleAction(actionSheath)
    endIf
endEvent

; registrations for events
Function registerCustomEvents()
	registerForRemoteEvent(playerRef, "onPlayerLoadGame")
endFunction

; add or remove the fix speed walk perk
function toggleFixSpeedWalk(bool bToggle)
	if bToggle
		playerRef.addPerk(fixSpeedWalkPerk)
	else
		playerRef.removePerk(fixSpeedWalkPerk)
	endIf
endFunction

function checkWeaponControls()
	input.getMappedControl(1)
endFunction
