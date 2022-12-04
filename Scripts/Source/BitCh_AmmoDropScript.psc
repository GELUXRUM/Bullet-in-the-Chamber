scriptname BitCh_AmmoDropScript extends quest

;--------------------------------------------------------------------
; PROPERTY GROUPS
;--------------------------------------------------------------------

group actors
    actor property playerRef auto
    {the player}
endGroup

group MCM
    bool property ammoDropAllow = false auto
    {control whether Ammo Drop is on/off}
	bool property ammoDropDelete = false auto
    {control if dropped ammo gets deleted}
endGroup

group scripts
    BitCh_ReloadExpanded property reloadScript auto
    {script we pull booleans from for 'if' checks}
endGroup

;--------------------------------------------------------------------
; VARIABLES
;--------------------------------------------------------------------

; Tactical Reload keyword
keyword AnimsReloadReserve
; track if we can drop ammo
bool ammoDropKeyHeld = false
;/ prevents ammo drop from occuring again by
preventing the ability to spam the hotkey during
the ammo drop event /;
bool ammoDropCooldown = false
; timer IDs
int ammoDropCooldownTimerID = 420
int boltActionTimerID = 84
; timer duration until failsafe kicks in
float ammoDropCooldownTimer = 4.20
;/ hopefully enough time for any post-fire
animation to stop playing /;
float boltActionTimer = 1.0

;--------------------------------------------------------------------
; EVENTS
;--------------------------------------------------------------------

event onInit()
    ; register events
    registerEvents()
    ; check if Tactical Reload is installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
    else
        AnimsReloadReserve = none
    endIf
endEvent

event actor.onPlayerLoadGame(actor akSender)
    ; register events
    registerEvents()
    ; check if Tactical Reload has been (un/re)installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
    else
        AnimsReloadReserve = none
    endIf
endEvent

event onControlDown(string sControl)
    ; custom event sent by hotkey from MCM
    if sControl == "ammoDropEvent"
        ; while held, allow ammo drop
        ammoDropKeyHeld = true
    endIf
endEvent

event onControlUp(string sControl, float time)
    ; custom event sent by hotkey from MCM
    if sControl == "ammoDropEvent"
        ; when released, block ammo drop
        ammoDropKeyHeld = false
    endIf
endEvent

event onAnimationEvent(objectReference akSender, string sEvent)

    ;--------------------------------------------------------------------
    ; AMMO DROP
    ;--------------------------------------------------------------------
    
    ; player starts reloading and ammo drop button is held
    if sEvent == "reloadStateEnter" && ammoDropKeyHeld == true
        ; set up the weapon instance
        int slotIndex = playerRef.getEquippedItemType(0) + 32
        instanceData:Owner thisInstance = playerRef.getInstanceOwner(slotIndex)
        ; ammo type currently in the weapon
        ammo chamberedAmmo = instanceData.getAmmo(thisInstance)
        ; max ammo capacity
        int ammoCapacity = instanceData.getAmmoCapacity(thisInstance) as int
        ; amount of ammo currently in the weapon
        int currentAmmo = ui.get("HUDMenu", "root.RightMeters_mc.AmmoCount_mc.ClipCount_tf.text") as int

        ;--------------------------------------------------------------------

        if ammoDropAllow == true && (instanceData.getKeywords(thisInstance)).find(reloadScript.cantDropAmmo) == -1 && ammoDropCooldown == false
            ; we want to prevent ammo drop spam from occuring, so we use a timer
            startTimer(ammoDropCooldownTimer, ammoDropCooldownTimerID)
            ;/ when set to true, ammo drop is blocked. This prevents
            the player from spamming the ammo drop key and dumping all
            of their ammo in seconds /;
            ammoDropCooldown = true
            ;/ wait a bit to simulate the time take to pull out the mag
            I could have used a timer, but it'd most likely require me to
            set up the instance and variables again, which is just extra
            script overhead :/ /;
            utility.wait(0.420)
            if reloadScript.BitChAllow == true
                ; check if TR mode is available
                if reloadScript.modeTR == true && AnimsReloadReserve
                    ; check if weapon is TR-enabled either via real or fake TR keyword
                    if (instanceData.getKeywords(thisInstance)).find(AnimsReloadReserve) != -1 || (instanceData.getKeywords(thisInstance)).find(reloadScript.forceBitChReload) != -1
                        ; check ammo and if weapon can chamber ammo
                        if currentAmmo != 0 && (instanceData.getKeywords(thisInstance)).find(reloadScript.disableChamberedReload) == -1
                            playerRef.removeItem(chamberedAmmo, currentAmmo - 1, true, none)
                            if ammoDropDelete == false
                                ; drop ammo at ~knee height to prevent clipping
                                (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo - 1, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                            endIf
                        ; if weapon can't chamber ammo - drop everything
                        elseIf currentAmmo != 0
                            playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                            if ammoDropDelete == false
                                (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                            endIf
                        endIf
                    ; weapon isn't TR-enabled, so we drop everything
                    else
                        playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                        if ammoDropDelete == false
                            (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                        endIf
                    endIf
                ; TR mode unavailable
                else
                    ; check ammo amount and if weapon can chamber ammo
                    if currentAmmo != 0 && (instanceData.getKeywords(thisInstance)).find(reloadScript.disableChamberedReload) == -1
                        ; this weapon can chamber a round, so we drop 1 less
                        playerRef.removeItem(chamberedAmmo, currentAmmo - 1, true, none)
                        if ammoDropDelete == false
                            (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo - 1, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                        endIf
                    ; if weapon can't chamber ammo - drop everything
                    elseIf currentAmmo != 0
                        playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                        if ammoDropDelete == false
                            (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                        endIf
                    endIf
                endIf
            ; if BitCh is disabled, drop all ammo
            else
                playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                if ammoDropDelete == false
                    (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                endIf
            endIf
        endIf
    endIf
    
    ; player finishes reloading
    if sEvent == "reloadStateExit"
        ; allow ammo drop again
        ammoDropCooldown = false
        ; cancel the timer
        cancelTimer(ammoDropCooldownTimerID)
    endIf
    ;/ revolvers and bolt actions fire reload events
    during the post-fire animations /;
    if sEvent == "weaponFire"
        ; check if weapon is a bolt-action
        instanceData:Owner thisInstance = playerRef.getEquippedWeapon().getInstanceOwner()
        bool isBoltAction = instanceData.getFlag(thisInstance, 0x0400000)
        if isBoltAction == true
            ;/ if weapon is bolt-action, unregister until the post-fire
            animation has presumable finished /;
            unregisterForAnimationEvent(playerRef, "reloadStateEnter")
            ; start a timer for re-registration
            startTimer(boltActionTimer, boltActionTimerID)
        endif
    endIf
endEvent

event onTimer(int aiTimerID)
    ; our ammo drop cooldown timer ended
    if aiTimerID == ammoDropCooldownTimerID
        ;/ sets it back to false after it was set to true before
        this was a proper cooldown before to avoid spam, but now
        it has been repurposed to a failsafe/;
        ammoDropCooldown = false
    endIf
    ; our bolt-action timer has ended
    if aiTimerID == boltActionTimerID
        ; register the event again so that ammo drop continues working
        registerForAnimationEvent(playerRef, "reloadStateEnter")
    endIf
endEvent

; entering Power Armor will break registered events
event actor.onSit(actor akSender, objectReference akFurniture)
	if akSender == playerRef
        ; register events again
		registerEvents()
    endIf
endEvent

;--------------------------------------------------------------------
; FUNCTIONS
;--------------------------------------------------------------------

function registerEvents()
    registerForAnimationEvent(playerRef, "reloadStateEnter")
    registerForAnimationEvent(playerRef, "reloadStateExit")
    registerForAnimationEvent(playerRef, "weaponFire")
    registerForRemoteEvent(playerRef, "onSit")
    registerForRemoteEvent(playerRef, "onPlayerLoadGame")
endFunction

function unregisterEvents()
    unregisterForAnimationEvent(playerRef, "reloadStateEnter")
    unregisterForAnimationEvent(playerRef, "reloadStateExit")
    unregisterForAnimationEvent(playerRef, "weaponFire")
    unregisterForRemoteEvent(playerRef, "onSit")
    unregisterForRemoteEvent(playerRef, "onPlayerLoadGame")
endFunction