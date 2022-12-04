scriptname BitCh_ReloadExpanded extends quest

;--------------------------------------------------------------------
; PROPERTY GROUPS
;--------------------------------------------------------------------

group actors
    actor property playerRef auto
    {the player}
endGroup

group keywords
	keyword property forceBitChReload auto
    {for weapons that can make use of BitCh but do not have TR}
	keyword property chamberedReload auto
    {for weapons that can hold extra ammo in the chamber}
	keyword property disableChamberedReload auto
    {for weapons that can't hold extra ammo in the chamber}
	keyword property cantDropAmmo auto
    {for weapons that can't drop ammo on reload}
endGroup

group MCM
    bool property BitChAllow = true auto
    {control whether BitCh is on/off}
    bool property modeTR = false auto
    {control whether Tactical Reload mode is on/off}
    bool property modeBCR = false auto
    {control whether Bullet Counted Reload mode is on/off}
endGroup

;--------------------------------------------------------------------
; VARIABLES
;--------------------------------------------------------------------

; Tactical Reload keyword
keyword AnimsReloadReserve
; Input Layer
inputEnableLayer inputLayer
; timer ID
int jumpTimerID = 69
; how long to block the jump for until the failsafe kicks in
float jumpBlockTimer = 5.0
; used to store some messages for debugging
string onInitDebug = "Event registration:\n"

;--------------------------------------------------------------------
; EVENTS
;--------------------------------------------------------------------

event onInit()
    ; register for events
    registerEvents()
    ; check if Tactical Reload is installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = game.getFormFromFile(0x00001734, "TacticalReload.esm") as keyword
    else
        AnimsReloadReserve = none
    endIf
endEvent

event actor.onPlayerLoadGame(actor akSender)
    ; register for events
    registerEvents()
    debugRegistration()
    ; check if Tactical Reload has been (un)installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = game.getFormFromFile(0x00001734, "TacticalReload.esm") as keyword
    else
        AnimsReloadReserve = none
    endIf
endEvent

event actor.onItemEquipped(actor akSender, form akBaseObject, objectReference akReference)
    ; works only if player equips a weapon and BCR mode is on
    if akBaseObject as weapon && modeBCR == true
        ; set up the weapon instance
        int slotIndex = PlayerRef.GetEquippedItemType(0) + 32
        instanceData:Owner thisInstance = PlayerRef.GetInstanceOwner(slotIndex)

        ; max ammo capacity
        int ammoCapacity = instanceData.getAmmoCapacity(thisInstance) as int

        ;/ if the player equipped a weapon that has the tracker keyword, we
        need to increase ammo by 1 on it/;
        if (instanceData.getKeywords(thisInstance)).find(chamberedReload) != -1
            ; increase ammo by 1
            instanceData.setAmmoCapacity(thisInstance, ammoCapacity + 1)
        endIf
    endIf
endEvent

event onAnimationEvent(objectReference akSender, string sEvent)
    ; set up the weapon instance
    int slotIndex = playerRef.getEquippedItemType(0) + 32
    instanceData:owner thisInstance = playerRef.getInstanceOwner(slotIndex)
    ; max ammo capacity
    int ammoCapacity = instanceData.getAmmoCapacity(thisInstance) as int
    ; amount of ammo currently in the weapon
    int currentAmmo = ui.get("HUDMenu", "root.RightMeters_mc.AmmoCount_mc.ClipCount_tf.text") as int

    ;--------------------------------------------------------------------
    ; CHAMBERING AN EXTRA ROUND
    ;--------------------------------------------------------------------
    
    ; player starts reloading
    if sEvent == "reloadStateEnter"
        ; call a function that blocks jump
        inputLayer = inputEnableLayer.create()
        inputLayer.enableJumping(false)
        ; start failsafe timer
        startTimer(jumpBlockTimer, jumpTimerID)
        ; check if weapon isn't excluded
        if (instanceData.getKeywords(thisInstance)).find(disableChamberedReload) == -1
            if BitChAllow == true
                ; check if TR mode is available
                if modeTR == true && AnimsReloadReserve
                    ; check if weapon is TR-enabled either via real or fake TR keyword
                    if (instanceData.getKeywords(thisInstance)).find(AnimsReloadReserve) != -1 || (instanceData.getKeywords(thisInstance)).find(forceBitChReload) != -1
                        ; check ammo and look for keywords
                        if currentAmmo != 0  && (instanceData.getKeywords(thisInstance)).find(chamberedReload) == -1
                            ; add 1 ammo and mark the weapon
                            instanceData.setAmmoCapacity(thisInstance, ammoCapacity + 1)
                            instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), chamberedReload, "add"))
                        elseif currentAmmo == 0  && (instanceData.getKeywords(thisInstance)).find(chamberedReload) != -1
                            ; remove 1 ammo and mark the weapon
                            instanceData.setAmmoCapacity(thisInstance, ammoCapacity - 1)
                            instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), chamberedReload, "remove"))
                            ; weapon should now be at default capacity
                        endIf
                    endIf
                ; TR mode isn't both on & installed
                else
                    ; check ammo and look for keywords
                    if currentAmmo != 0  && (instanceData.getKeywords(thisInstance)).find(chamberedReload) == -1
                        ; add 1 ammo and mark the weapon
                        instanceData.setAmmoCapacity(thisInstance, ammoCapacity + 1)
                        instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), chamberedReload, "add"))
                        ; weapons should now be at +1 capacity
                    elseif currentAmmo == 0  && (instanceData.getKeywords(thisInstance)).find(chamberedReload) != -1
                        ; remove 1 ammo and mark the weapon
                        instanceData.setAmmoCapacity(thisInstance, ammoCapacity - 1)
                        instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), chamberedReload, "remove"))
                        ; weapon should now be at default capacity
                    endIf
                endIf
            endIf
        endIf
    endIf

    ;--------------------------------------------------------------------
    ; RELOAD AT MAX
    ;--------------------------------------------------------------------

    ; player finishes reloading
    if sEvent == "reloadStateExit"
        ; enable jumping
        inputLayer.enableJumping(true)
        ; delete the layer
        inputLayer.delete()
        ; cancel failsafe timer
        cancelTimer(jumpTimerID)
        ; check if weapon has a chambered round
        if (instanceData.getKeywords(thisInstance)).find(chamberedReload) == -1
            ; check if enabled and weapon isn't excluded
            if BitChAllow == true && (instanceData.getKeywords(thisInstance)).find(disableChamberedReload) == -1
                if modeTR == true && AnimsReloadReserve
                    ; check if weapon is TR-enabled either via real or fake TR keyword
                    if (instanceData.getKeywords(thisInstance)).find(AnimsReloadReserve) != -1 || (instanceData.getKeywords(thisInstance)).find(forceBitChReload) != -1
                        ; add 1 ammo and mark the weapon
                        instanceData.setAmmoCapacity(thisInstance, ammoCapacity + 1)
                        instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), chamberedReload, "add"))
                    endIf
                ; TR mode isn't both on & installed
                else
                    ; add 1 ammo and mark the weapon
                    instanceData.setAmmoCapacity(thisInstance, ammoCapacity + 1)
                    instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), chamberedReload, "add"))
                endIf
            endIf
        endIf
    endIf

    ;--------------------------------------------------------------------
    ; BULLET COUNTED RELOAD FIX
    ;--------------------------------------------------------------------

    ; lmao BCR hack stolen from Bingle
    if sEvent == "reloadEnd" && modeBCR == true && (instanceData.GetKeywords(thisInstance)).Find(chamberedReload) != -1
        instanceData.SetAmmoCapacity(thisInstance, AmmoCapacity + 1)
    endIf

endEvent

event onTimer(int aiTimerID)
    ; failsafe timer has ended
    if aiTimerID == jumpTimerID
        ; enable jumping
        inputLayer.enableJumping(true)
        ; delete the layer
        inputLayer.delete()
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

; this will add a keyword to the current instance of a weapon
keyword[] function chamberTheKeyword(keyword[] mainArray, keyword keywordToDoButtStuffWith, string sWhatDo)
	; generate an empty array
	keyword[] tempArray = new keyword[0]
	; populate the empty array
	tempArray = mainArray
	; options on how to modify the array
	if sWhatDo == "add"
		; add the keyword into the array
		tempArray.add(keywordToDoButtStuffWith)
        ; end
		return tempArray
	elseIf sWhatdo == "remove"
		; find the position of the keyword 
		int removeFrom = tempArray.find(keywordToDoButtStuffWith)
		; remove the keyword
		tempArray.remove(removeFrom)
        ; end
		return tempArray
    endIf
endFunction

function debugRegistration()
    if registerForAnimationEvent(playerRef, "reloadStateEnter")
        onInitDebug = "reloadStateEnter: success\n"
    else
        onInitDebug += "reloadStateEnter: fail\n"
    endIf
    if registerForAnimationEvent(playerRef, "reloadStateExit")
        onInitDebug += "reloadStateExit: success\n"
    else
        onInitDebug += "reloadStateExit: fail\n"
    endIf
    if registerForAnimationEvent(playerRef, "reloadEnd")
        onInitDebug += "reloadEnd: success\n"
    else
        onInitDebug += "reloadEnd: fail\n"
    endIf
    if registerForRemoteEvent(playerRef, "onSit")
        onInitDebug += "onSit: success\n"
    else
        onInitDebug += "onSit: fail\n"
    endIf
    if registerForRemoteEvent(playerRef, "onPlayerLoadGame")
        onInitDebug += "onPlayerLoadGame: success\n"
    else
        onInitDebug += "onPlayerLoadGame: fail\n"
    endIf
    if registerForRemoteEvent(playerRef, "onItemEquipped")
        onInitDebug += "onItemEquipped: success\n"
    else
        onInitDebug += "onItemEquipped: fail\n"
    endIf
    debug.messagebox("h")
    debug.messageBox(onInitDebug)
endFunction

function registerEvents()
    registerForAnimationEvent(playerRef, "reloadStateEnter")
    registerForAnimationEvent(playerRef, "reloadStateExit")
    registerForAnimationEvent(playerRef, "reloadEnd")
    registerForRemoteEvent(playerRef, "onSit")
    registerForRemoteEvent(playerRef, "onPlayerLoadGame")
    registerForRemoteEvent(playerRef, "onItemEquipped")
endFunction

function unregisterEvents()
    unregisterForAnimationEvent(playerRef, "reloadStateEnter")
    unregisterForAnimationEvent(playerRef, "reloadStateExit")
    unregisterForAnimationEvent(playerRef, "reloadEnd")
    unregisterForRemoteEvent(playerRef, "onSit")
    unregisterForRemoteEvent(playerRef, "onPlayerLoadGame")
    unregisterForRemoteEvent(playerRef, "onItemEquipped")
endFunction
