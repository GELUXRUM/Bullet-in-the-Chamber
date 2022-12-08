scriptname BitCh_AmmoCheckExpanded extends quest

;--------------------------------------------------------------------
; PROPERTY GROUPS
;--------------------------------------------------------------------

group actors
    actor property playerRef auto
    {the player}
endGroup

; stuff for the MCM
group MCM_Booleans
    bool property ammoCapacityEnabled = true auto
    {track if ammo check shows max capacity}
    bool property ammoNameEnabled = true auto
    {track if ammo check shows ammo name}
    bool property reserveNotifEnabled = true auto
    {track if ammo check shows ammo in inventory}
    bool property modeFallUI = false auto
    {track if FallUI is on}
    bool property lowerNormal = true auto
    {track if weapon gets lowered during estimate check}
    bool property lowerExact = true auto
    {track if weapon gets lowered during exact check}
    bool property multiKeyUseEstimate = true auto
    {idk, eclix made this for his multi-use function}
    bool property soundsNormal = true auto
    {track if ammo check play sounds during estimate check}
    bool property soundsExact = true auto
    {track if ammo check play sounds during exact check}
EndGroup

; more stuff for the MCM
group MCM_Globals
    globalVariable property MCM_AlmostFull auto
    {track amount of ammo as a % needed to show "Almost full"}
    globalVariable property MCM_AlmostEmpty auto
    {track amount of ammo as a % needed to show "Almost empty"}
    globalVariable property blockGunUp auto
    {track whether the weapon can be raised or not during ammo check}
EndGroup

group globals
	globalVariable property longPressTimer auto
    {how long it needs to be held to count as a long press}
EndGroup

; stuff to play a little animation on ammo check
group actions
    action property actionGunDown auto
    action property actionReload auto
EndGroup

group keywords
    keyword property exactCheckCapability auto
EndGroup

group sounds
    sound property ammoCheckSounds auto
EndGroup

;--------------------------------------------------------------------
; VARIABLES
;--------------------------------------------------------------------

; used to track short/long keypresses
bool hotKeyIsDown = false
; timer ID for the long-press hotkey
int reloadCheckTimerID = 21
; timer for animations during ammo check
; TODO make it configurable
float timerTimer = 1.5

;--------------------------------------------------------------------
; EVENT
;--------------------------------------------------------------------

event onControlDown(string sControl)
    if sControl == "reloadCheck"
        startTimer(longPressTimer.getValue(), reloadCheckTimerID)
        hotkeyIsDown = true
    endIf
endEvent

event onControlUp(string control, float time)
    ;/ if the bool is true, timer hasn't ended yet
    meaning the player released before long-press
    has been detected /;
    if hotkeyIsDown == true
        ; player released the button, cancel the timer
        cancelTimer(reloadCheckTimerID)
        ; this isn't a long-press, so we reload
        playerRef.playIdleAction(actionReload)
        hotkeyIsDown = false
    endIf
endEvent

event onTimer(int aiTimerID)
    ; timer ended, so we check ammo
    if aiTimerID == reloadCheckTimerID
        hotkeyIsDown = false
        if multiKeyUseEstimate
            estimateAmmoCheck()
        else
            exactAmmoCheck()
        endIf
    endIf
endEvent

;--------------------------------------------------------------------
; FUNCTIONS
;--------------------------------------------------------------------

function estimateAmmoCheck()

    ;--------------------------------------------------------------------

	; instance stuff Greslin did for me because I am noob
	int slotIndex = playerRef.GetEquippedItemType(0) + 32
	instanceData:Owner thisInstance = playerRef.getInstanceOwner(slotIndex)
	; some stuff to make life easier when writing the rest of the script
	; current weapon
	weapon theWeapon = playerRef.getEquippedWeapon(0)
	;/ current ammo type in use. Must grab using instanceData otherwise it uses
    the default found in the weapon record /;
	ammo chamberedAmmo = instanceData.getAmmo(thisInstance)
    ; max ammo that can be held by the weapon's magazine
    int maxAmmo = instanceData.getAmmoCapacity(thisInstance) as int
    ; ammo currently left in the weapon's magazine
    int currentAmmo = UI.get( "HUDMenu", "root.RightMeters_mc.AmmoCount_mc.ClipCount_tf.text" ) as int
    ; the amount of ammo that is left in the player's inventory
    int reserveAmmo = playerRef.getItemCount(chamberedAmmo as Form) as int - CurrentAmmo
    ;/ ammo currently left in the weapon's magazine as a %. Must be cast as
    float, otherwise it doesn't work properly /;
    float ammoPercentage = (currentAmmo as float) / (maxAmmo as float) * 100

	;--------------------------------------------------------------------

    ; check if the player has a weapon AND if the weapon is not melee AND whether it's drawn
    if theWeapon as bool && chamberedAmmo as bool && playerRef.isWeaponDrawn() as bool
        ; check if the player wants to play a little animation
        if lowerNormal == true
            ; lower weapon
            playerRef.playIdleAction(actionGunDown)
            ; block the weapon from being raised
            blockGunUp.setValue(1)
            ; play the ammo check sounds
            if soundsNormal
                ammoCheckSounds.play(playerRef)
            endIf
            ; wait a bit
            utility.wait(timerTimer)
            ; allow the weapon to be raised
            blockGunUp.setValue(0)
            ; raise the weapon
            playerRef.playIdleAction(actionGunDown)
        endIf
        ;/ checks to see how much ammo is left as a % and a 
        message is displayed to give the player a rough idea
        of how much is left /;
        if (instancedata.GetKeywords(thisInstance)).find(exactCheckCapability) == -1
            if ammoPercentage == 100.0
                debug.notification("Full")
            elseIf ammoPercentage <= 60.0 && ammoPercentage >= 40.0 
                debug.notification("About half")
            elseIf ammoPercentage == 0.0
                debug.notification("Empty")
            elseIf ammoPercentage >= MCM_AlmostFull.GetValue() as float
                debug.notification("Almost full")
            elseIf ammoPercentage > 60.0
                debug.notification("More than half")
            elseIf ammoPercentage > MCM_AlmostEmpty.GetValue() as float
                debug.notification("Less than half")
            else
                debug.notification("Almost empty")
            endIf
        else
            debug.notification(currentAmmo as string + "/" + maxAmmo as string)
        endIf
    endIf
endFunction

function exactAmmoCheck()
    
    ;--------------------------------------------------------------------
    
	; instance stuff Greslin did for me because I am noob
	int slotIndex = playerRef.GetEquippedItemType(0) + 32
	instanceData:Owner thisInstance = playerRef.getInstanceOwner(slotIndex)
	; some stuff to make life easier when writing the rest of the script
	; current weapon
	weapon theWeapon = playerRef.getEquippedWeapon(0)
	;/ current ammo type in use. Must grab using instanceData otherwise it uses
    the default found in the weapon record /;
	ammo chamberedAmmo = instanceData.getAmmo(thisInstance)
    ; max ammo that can be held by the weapon's magazine
    int maxAmmo = instanceData.getAmmoCapacity(thisInstance) as int
    ; ammo currently left in the weapon's magazine
    int currentAmmo = UI.get( "HUDMenu", "root.RightMeters_mc.AmmoCount_mc.ClipCount_tf.text" ) as int
    ; the amount of ammo that is left in the player's inventory
    int reserveAmmo = playerRef.getItemCount(chamberedAmmo as Form) as int - CurrentAmmo
    ;/ ammo currently left in the weapon's magazine as a %. Must be cast as
    float, otherwise it doesn't work properly /;
    float ammoPercentage = (currentAmmo as float) / (maxAmmo as float) * 100
    ; string for ammo check output
    string output = (currentAmmo) as string

	;--------------------------------------------------------------------

    ; check if the player has a weapon AND if the weapon is not melee AND whether it's drawn
    if theWeapon as bool && chamberedAmmo as bool && playerRef.isWeaponDrawn() as bool
        ; check if the player wants to play a little animation
        if lowerExact == true
            ; lower weapon
            playerRef.playIdleAction(actionGunDown)
            ; block the weapon from being raised
            blockGunUp.setValue(1)
            ; play the ammo check sounds
            if soundsExact
                ammoCheckSounds.play(playerRef)
            endIf
            ; wait a bit
            utility.wait(timerTimer)
            ; allow the weapon to be raised
            blockGunUp.setValue(0)
            ; raise the weapon
            playerRef.playIdleAction(actionGunDown)
        endIf

        ; optional mode for FallUI users
        if modeFallUI == true
            ; check if the player wants to see max capacity
            if ammoCapacityEnabled == true
                output = output + "/" + (maxAmmo) as string
            endIf
            ;/ check if the player wants to see how much ammo they are
            currently holding in their inventory /;
            if reserveNotifEnabled == true
                output = output + " | " + (reserveAmmo) as string
            endIf
            ; check if the player wants to be told what ammo they're using
            if ammoNameEnabled == true
                ;/ using a bullet point here to keep consistency and not break
                the automatic FallUI formatting /;
                output = output + " | " + chamberedAmmo.getName() as string 
            endIf
        ; same thing as before but for non-FallUI users    
        elseIf modeFallUI == false
            if ammoCapacityEnabled == true
                output = output + "/" + (maxAmmo) as string
            endIf
            if reserveNotifEnabled == true
                output = output + " • " + (reserveAmmo) as string
            endIf
            if ammoNameEnabled == true
                output = output + " • " + ChamberedAmmo.GetName() as string 
            endIf
        endIf
        ; output the ammo check notification
        debug.notification(output)
	endIf

EndFunction