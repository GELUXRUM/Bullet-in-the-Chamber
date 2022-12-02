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
string onInitDebug

;--------------------------------------------------------------------
; EVENTS
;--------------------------------------------------------------------

event onInit()
    ; register for events
    registerForAnimationEvent(playerRef, "reloadStateEnter")
    registerForAnimationEvent(playerRef, "reloadEnd")
    registerForAnimationEvent(playerRef, "reloadStateExit")
    registerForRemoteEvent(playerRef, "OnPlayerLoadGame")
    ; debug only - output which ones registered
    debugRegistration()

    registerForRemoteEvent(playerRef, "OnItemEquipped")

    ; check if Tactical Reload is installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
    else
        AnimsReloadReserve = none
    endIf
endEvent

event actor.onPlayerLoadGame(actor akSender)
    onInitDebug = ""
    ; register for events
    registerForAnimationEvent(playerRef, "reloadStateEnter")
    registerForAnimationEvent(playerRef, "reloadEnd")
    registerForAnimationEvent(playerRef, "reloadStateExit")
    registerForRemoteEvent(playerRef, "OnPlayerLoadGame")
    ; debug only - output which ones registered
    debugRegistration()

    registerForRemoteEvent(playerRef, "OnItemEquipped")

    ; check if Tactical Reload has been (un)installed
    if game.isPluginInstalled("TacticalReload.esm")
        AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
        debug.messageBox("TR KW yes")
    else
        AnimsReloadReserve = none
        debug.messageBox("TR KW no")
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
    
    ; player starts reloading an enabled weapon
    if sEvent == "reloadStateEnter" && (instanceData.getKeywords(thisInstance)).find(disableChamberedReload) == -1
        ; call a function that blocks jump
        inputLayer = inputEnableLayer.create()
        inputLayer.enableJumping(false)
        startTimer(jumpBlockTimer, jumpTimerID)
        ; check if enabled and weapon isn't excluded
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
                inputLayer = inputEnableLayer.create()
                ; call a function that blocks jump
                inputLayer.enableJumping(false)
                startTimer(jumpBlockTimer, jumpTimerID)
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

    ;--------------------------------------------------------------------
    ; RELOAD AT MAX
    ;--------------------------------------------------------------------

    ; player finishes reloading an empty gun
    if sEvent == "reloadStateExit" && (instanceData.getKeywords(thisInstance)).find(chamberedReload) == -1
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

    ;--------------------------------------------------------------------
    ; BULLET COUNTED RELOAD FIX
    ;--------------------------------------------------------------------

    ; lmao BCR hack stolen from Bingle
    if sEvent == "reloadEnd" && modeBCR == true && (instanceData.GetKeywords(thisInstance)).Find(chamberedReload) != -1
        instanceData.SetAmmoCapacity(thisInstance, AmmoCapacity + 1)
        if inputLayer.isJumpingEnabled() == false
            inputLayer.enableJumping(true)
            cancelTimer(jumpTimerID)
            inputLayer.delete()
        endIf
    elseif sEvent == "reloadEnd" && modeBCR == false
        if inputLayer.isJumpingEnabled() == false
            inputLayer.enableJumping(true)
            cancelTimer(jumpTimerID)
            inputLayer.delete()
        endIf
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

event onTimer(int aiTimerID)
    if aiTimerID == jumpTimerID
        inputLayer.enableJumping(true)
        debug.trace("timer ended and jumping has been enabled")
    endIf
endEvent

function debugRegistration()
    if registerForAnimationEvent(playerRef, "reloadStateEnter")
        onInitDebug = "reloadStateEnter: success \n"
    else
        onInitDebug = onInitDebug + "reloadStateEnter: fail \n"
    endIf
    if registerForAnimationEvent(playerRef, "reloadEnd")
        onInitDebug = onInitDebug + "reloadEnd: success \n"
    else
        onInitDebug = onInitDebug + "reloadEnd: fail \n"
    endIf
    if registerForAnimationEvent(playerRef, "reloadStateExit")
        onInitDebug = onInitDebug + "reloadStateExit: success \n"
    else
        onInitDebug = onInitDebug + "reloadStateExit: fail \n"
    endIf
    if registerForRemoteEvent(playerRef, "OnPlayerLoadGame")
        onInitDebug = onInitDebug + "OnPlayerLoadGame: success \n"
    else
        onInitDebug = onInitDebug + "OnPlayerLoadGame: fail \n"
    endIf
    if registerForRemoteEvent(playerRef, "OnItemEquipped")
        onInitDebug = onInitDebug + "OnItemEquipped: success \n"
    else
        onInitDebug = onInitDebug + "OnItemEquipped: fail \n"
    endIf
    debug.messageBox(onInitDebug)
endFunction