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

;--------------------------------------------------------------------
; EVENTS
;--------------------------------------------------------------------

event onInit()
    ; some events
    registerForAnimationEvent(playerRef, "reloadStateEnter")
    registerForRemoteEvent(playerRef, "OnPlayerLoadGame")
    ; L-Shift key
    RegisterForKey(160)
    ; check if Tactical Reload is installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
        debug.messageBox("TR KW yes")
    else
        AnimsReloadReserve = none
        debug.messageBox("TR KW no")
    endIf
endEvent

event actor.onPlayerLoadGame(actor akSender)
    ; some events
    registerForAnimationEvent(playerRef, "reloadStateEnter")
    registerForRemoteEvent(playerRef, "OnPlayerLoadGame")
    ; L-Shift key
    RegisterForKey(160)
    ; check if Tactical Reload has been (un)installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
        debug.messageBox("TR KW yes")
    else
        AnimsReloadReserve = none
        debug.messageBox("TR KW no")
    endIf
endEvent


event onKeyDown(int control)
    if control == 160
        debug.trace("true")
        ammoDropKeyHeld = true
    endIf
endEvent

event onKeyUp(int control, float time)
    if control == 160
        debug.trace("false")
        ammoDropKeyHeld = false
    endIf
endEvent

event onAnimationEvent(objectReference akSender, string sEvent)

    ;--------------------------------------------------------------------
    ; AMMO DROP
    ;--------------------------------------------------------------------
    
    ; player starts reloading an enabled weapon
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

        if ammoDropAllow == true && (instanceData.getKeywords(thisInstance)).find(reloadScript.cantDropAmmo) == -1
            debug.trace("ammo drop init")
            utility.wait(0.420)

            if reloadScript.BitChAllow == true
                ; check if TR mode is available
                if reloadScript.modeTR == true && AnimsReloadReserve
                    debug.trace("ammo drop: TR mode")
                    ; check if weapon is TR-enabled either via real or fake TR keyword
                    if (instanceData.getKeywords(thisInstance)).find(AnimsReloadReserve) != -1 || (instanceData.getKeywords(thisInstance)).find(reloadScript.forceBitChReload) != -1
                        ; check ammo and if weapon can chamber ammo
                        if currentAmmo != 0 && (instanceData.getKeywords(thisInstance)).find(reloadScript.disableChamberedReload) == -1
                            playerRef.removeItem(chamberedAmmo, currentAmmo - 1, true, none)
                            if ammoDropDelete == false
                                ; drop ammo at ~knee height to prevent clipping
                                (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo - 1, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                                debug.trace("dropped " + (currentAmmo - 1))
                            endIf
                        ; if weapon can't chamber ammo - drop everything
                        elseIf currentAmmo != 0
                            playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                            if ammoDropDelete == false
                                (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                                debug.trace("dropped " + currentAmmo)
                            endIf
                        endIf
                    ; weapon isn't TR-enabled, so we drop everything
                    ; TODO safety check for 0 ammo?
                    else
                        playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                        if ammoDropDelete == false
                            (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                            debug.trace("dropped " + currentAmmo)
                        endIf
                    endIf
                ; TR mode unavailable
                else
                    debug.trace("ammo drop: normal mode")
                    ; check ammo amount and if weapon can chamber ammo
                    if currentAmmo != 0 && (instanceData.getKeywords(thisInstance)).find(reloadScript.disableChamberedReload) == -1
                        ; this weapon can chamber a round, so we drop 1 less
                        playerRef.removeItem(chamberedAmmo, currentAmmo - 1, true, none)
                        if ammoDropDelete == false
                            (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo - 1, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                            debug.trace("dropped chambered " + (currentAmmo - 1))
                        endIf
                    ; if weapon can't chamber ammo - drop everything
                    elseIf currentAmmo != 0
                        playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                        if ammoDropDelete == false
                            (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                            debug.trace("dropped " + currentAmmo)
                        endIf
                    endIf
                endIf
            ; if BitCh is disabled, drop all ammo
            else
                debug.trace("BitCh disabled, drop everything")
                playerRef.removeItem(chamberedAmmo, currentAmmo, true, none)
                if ammoDropDelete == false
                    (playerRef.placeAtMe(chamberedAmmo as form, currentAmmo, false, false, true)).moveTo(playerRef, afZOffset = 33.0)
                    debug.trace("dropped " + currentAmmo)
                endIf
            endIf
        endIf
    endIf
endEvent