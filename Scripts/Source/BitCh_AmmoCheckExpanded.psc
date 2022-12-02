Scriptname BitCh_AmmoCheckExpanded Extends Quest

;--------------------------------------------------------------------
; PROPERTY GROUPS
;--------------------------------------------------------------------

; stuff for the MCM
Group MCM_Booleans
    Bool Property AmmoCapacityEnabled = True Auto
    Bool Property AmmoNameEnabled = True Auto
    Bool Property ModeFallUI = False Auto
    Bool Property LowerExact = True Auto
    Bool Property LowerNormal = True Auto
    Bool Property ReserveNotifEnabled = True Auto
    Bool Property MultiKeyUseEstimate = True Auto
    Bool Property SoundsNormal = True Auto
    Bool Property SoundsExact = True Auto
EndGroup

; more stuff for the MCM
Group MCM_Globals
    GlobalVariable Property MCM_AlmostFull Auto
    GlobalVariable Property MCM_AlmostEmpty Auto
    GlobalVariable Property BlockGunUp Auto
EndGroup

Group Globals
	GlobalVariable Property LongPressTimer Auto
EndGroup

; stuff to play a little animation on ammo check
Group Actions
    Action Property ActionGunDown Auto
    Action Property ActionReload Auto
EndGroup

Group Keywords
    Keyword Property ExactCheckCapability Auto
    Keyword Property WeaponTypePistol Auto
EndGroup

Group Sounds
    Sound Property AmmoCheckSounds Auto
EndGroup

Actor Property PlayerRef Auto
; used to prevent two short presses from activating a long press
bool InCooldown = False
; used to track short/long keypresses
bool HotKeyIsDown = false

Event OnInit()
    PlayerRef = Game.GetPlayer()
EndEvent

;--------------------------------------------------------------------
; EVENT
;--------------------------------------------------------------------
Event OnControlDown(string control)
    If (control == "ReloadCheck")
        HotKeyIsDown = True
        ; wait to see if this is going to be a long press
        Utility.Wait(LongPressTimer.GetValue())
        ; hotkey is still down, do long press stuff
        If HotKeyIsDown && !InCooldown
            ;check if we want estimate or exact ammo check
            If MultiKeyUseEstimate
                EstimateAmmoCheck()
            Else
                ExactAmmoCheck()
            EndIf
        ; do short press stuff
        Else 
            ; reload
            PlayerRef.PlayIdleAction(ActionReload)
        EndIf
    EndIf
EndEvent

Event OnControlUp(string control, float time)
; key has been released, reset the bool
If (control == "ReloadCheck")
    HotKeyIsDown = false
    InCooldown = true
    Utility.Wait(LongPressTimer.GetValue())
    InCooldown = false
EndIf
EndEvent

;--------------------------------------------------------------------
; FUNCTIONS
;--------------------------------------------------------------------

Function EstimateAmmoCheck()
    ;--------------------------------------------------------------------
	; instance stuff Greslin did for me because I am noob
	int slotIndex = Game.GetPlayer().GetEquippedItemType(0) + 32
	instanceData:Owner thisInstance = Game.GetPlayer().GetInstanceOwner(slotIndex)
	; some stuff to make life easier when writing the rest of the script
	; the player
	Actor ThePlayer = Game.GetPlayer()
	; current weapon
	Weapon TheWeapon = ThePlayer.GetEquippedWeapon(0)
	;/ current ammo type in use. Must grab using instanceData otherwise it uses
    the default found in the weapon record /;
	Ammo ChamberedAmmo = instanceData.GetAmmo(thisInstance)
    ; max ammo that can be held by the weapon's magazine
    int MaxAmmo = instanceData.GetAmmoCapacity(thisInstance) as int
    ; ammo currently left in the weapon's magazine
    int CurrentAmmo = UI.Get( "HUDMenu", "root.RightMeters_mc.AmmoCount_mc.ClipCount_tf.text" ) as int
    ; the amount of ammo that is left in the player's inventory
    int ReserveAmmo = MaxAmmo - CurrentAmmo
    ;/ ammo currently left in the weapon's magazine as a %. Must be cast as
    float, otherwise it doesn't work properly /;
    float AmmoPercentage = (CurrentAmmo as float) / (MaxAmmo as float) * 100
    ; timer for animations during ammo check
    float TimerTimer = 1.5

	;--------------------------------------------------------------------

    ; check if the player has a weapon AND if the weapon is not melee AND whether it's drawn
    If TheWeapon as bool && ChamberedAmmo as bool && ThePlayer.IsWeaponDrawn() as bool
        ; check if the player wants to play a little animation
        If LowerNormal == True
            ; lower weapon
            ThePlayer.PlayIdleAction(ActionGunDown)
            ; block the weapon from being raised
            BlockGunUp.SetValue(1)
            ; Play the ammo check sounds
            If SoundsNormal
                AmmoCheckSounds.Play(ThePlayer)
            EndIf
            ; wait a bit
            Utility.Wait(TimerTimer)
            ; allow the weapon to be raised
            BlockGunUp.SetValue(0)
            ; raise the weapon
            ThePlayer.PlayIdleAction(ActionGunDown)
        EndIf
        ;/ checks to see how much ammo is left as a % and a 
        message is displayed to give the player a rough idea
        of how much is left /;
        If (instancedata.GetKeywords(thisInstance)).Find(ExactCheckCapability) == -1
            If AmmoPercentage == 100.0
                Debug.Notification("Full")
            ElseIf AmmoPercentage <= 60.0 && AmmoPercentage >= 40.0 
                Debug.Notification("About half")
            ElseIf AmmoPercentage == 0.0
                Debug.Notification("Empty")
            ElseIf AmmoPercentage >= MCM_AlmostFull.GetValue() as float
                Debug.Notification("Almost full")
            Elseif AmmoPercentage > 60.0
                Debug.Notification("More than half")
            ElseIf AmmoPercentage > MCM_AlmostEmpty.GetValue() as float
                Debug.Notification("Less than half")
            Else
                Debug.Notification("Almost empty")
            EndIf
        Else
            Debug.Notification(CurrentAmmo as string + "/" + MaxAmmo as string)
        EndIf
    EndIf
EndFunction

Function ExactAmmoCheck()
    
    ;--------------------------------------------------------------------
    
	; instance stuff Greslin did for me because I am noob
	int slotIndex = Game.GetPlayer().GetEquippedItemType(0) + 32
	instanceData:Owner thisInstance = Game.GetPlayer().GetInstanceOwner(slotIndex)
	; some stuff to make life easier when writing the rest of the script
	; the player
	Actor ThePlayer = Game.GetPlayer()
	; current weapon
	Weapon TheWeapon = ThePlayer.GetEquippedWeapon(0)
	;/ current ammo type in use. Must grab using instanceData otherwise it uses
    the default found in the weapon record /;
	Ammo ChamberedAmmo = instanceData.GetAmmo(thisInstance)
    ; max ammo that can be held by the weapon's magazine
    int MaxAmmo = instanceData.GetAmmoCapacity(thisInstance) as int
    ; ammo currently left in the weapon's magazine
    int CurrentAmmo = UI.Get( "HUDMenu", "root.RightMeters_mc.AmmoCount_mc.ClipCount_tf.text" ) as int
    ; the amount of ammo that is left in the player's inventory
    int ReserveAmmo = ThePlayer.GetItemCount(ChamberedAmmo) - CurrentAmmo
    ;/ ammo currently left in the weapon's magazine as a %. Must be cast as
    float, otherwise it doesn't work properly /;
    float AmmoPercentage = (CurrentAmmo as float) / (MaxAmmo as float) * 100
    ; timer for animations during ammo check
    float TimerTimer = 1.5
    ; string for ammo check output
    string Output = (CurrentAmmo) as string

	;--------------------------------------------------------------------

    ; check if the player has a weapon AND if the weapon is not melee AND whether it's drawn
    If TheWeapon as bool && ChamberedAmmo as bool && ThePlayer.IsWeaponDrawn() as bool
        ; check if the player wants to play a little animation
        If LowerExact == True
            ; lower weapon
            ThePlayer.PlayIdleAction(ActionGunDown)
            ; block the weapon from being raised
            BlockGunUp.SetValue(1)
             ; Play the ammo check sounds
             If SoundsExact
                AmmoCheckSounds.Play(ThePlayer)
            EndIf
            ; wait a bit
            Utility.Wait(TimerTimer)
            ; allow the weapon to be raised
            BlockGunUp.SetValue(0)
            ; raise the weapon
            ThePlayer.PlayIdleAction(ActionGunDown)
        EndIf
        
        ; optional mode for FallUI users
        If ModeFallUI == True
            ; check if the player wants to see max capacity
            If AmmoCapacityEnabled == True
                Output = Output + "/" + (MaxAmmo) as string
            EndIf
            ;/ check if the player wants to see how much ammo they are
            currently holding in their inventory /;
            If ReserveNotifEnabled == True
                Output = Output + " | " + (ReserveAmmo) as string
            EndIf
            ; check if the player wants to be told what ammo they're using
            If AmmoNameEnabled == True
                ;/ using a bullet point here to keep consistency and not break
                the automatic FallUI formatting /;
                Output = Output + " | " + ChamberedAmmo.GetName() as string 
            EndIf
        ; same thing as before but for non-FallUI users    
        ElseIf ModeFallUI == False
            If AmmoCapacityEnabled == True
                Output = Output + "/" + (MaxAmmo) as string
            EndIf
            If ReserveNotifEnabled == True
                Output = Output + " • " + (ReserveAmmo) as string
            EndIf
            If AmmoNameEnabled == True
                Output = Output + " • " + ChamberedAmmo.GetName() as string 
            EndIf
        EndIf
        ; output the ammo check notification
        Debug.Notification(Output)
	EndIf
    
EndFunction