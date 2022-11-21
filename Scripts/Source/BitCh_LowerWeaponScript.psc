ScriptName BitCh_LowerWeaponScript extends Quest

Group Misc
	Actor Property PlayerRef Auto
EndGroup

Group Perks
	Perk Property FixSpeedWalkPerk Auto
EndGroup

Group Animations
	Action Property ActionSheath Auto
	Action Property ActionGunDown Auto
	Idle Property GunRelaxedRootPlayer Auto
EndGroup

Group Bools
	bool Property MCMFixSpeedWalk = True Auto
	bool Property EnableHolster = True Auto

EndGroup

Group Globals
	GlobalVariable Property LongPressTimer Auto
EndGroup

; used to prevent twp short presses from activating a long press
bool InCooldown = False
; used to track short/long keypresses
bool HotKeyIsDown = false

Event OnInit()
	PlayerRef = Game.GetPlayer()
	RegisterCustomEvents()
	If MCMFixSpeedWalk
		PlayerRef.AddPerk(FixSpeedWalkPerk)
	EndIf
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	RegisterCustomEvents()
	If MCMFixSpeedWalk
		; resetting the perk periodically is required, lest you fall victim to the ability condition bug
		PlayerRef.RemovePerk(FixSpeedWalkPerk)
		PlayerRef.AddPerk(FixSpeedWalkPerk)
	EndIf
EndEvent

Event OnControlDown(string control)
		If (control == "Lolster")
			HotKeyIsDown = True
			; we check if the player wants long presses to holster
			If EnableHolster == True
				; wait to see if this is going to be a long press
				Utility.Wait(LongPressTimer.GetValue()) 
				; hotkey is still down, do long press stuff
				If HotKeyIsDown && !InCooldown
					; sheathe weapon. Both first and third person
					PlayerRef.PlayIdleAction(ActionSheath)
					; hotkey is not down, do short press stuff
				Else 
					; lowers weapon in first person
					PlayerRef.PlayIdleAction(ActionGunDown)
					; lowers weapon in third person
					PlayerRef.PlayIdle(GunRelaxedRootPlayer)
				EndIf
			Else
				; if they don't want long presses to holster we just lower the weapon
				PlayerRef.PlayIdleAction(ActionGunDown)
				PlayerRef.PlayIdle(GunRelaxedRootPlayer)
			EndIf
		EndIf
EndEvent

Event OnControlUp(string control, float time)
	; key has been released, reset the bool
	If (control == "Lolster")
		HotKeyIsDown = false
		InCooldown = true
		Utility.Wait(LongPressTimer.GetValue())
		InCooldown = false
	EndIf
EndEvent

; registrations for events
Function RegisterCustomEvents()
	RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
EndFunction

; add or remove the fix speed walk perk
Function ToggleFixSpeedWalk(bool bToggle)
	If bToggle
		PlayerRef.AddPerk(FixSpeedWalkPerk)
	Else
		PlayerRef.RemovePerk(FixSpeedWalkPerk)
	EndIf
EndFunction

Function CheckWeaponControls()
	Input.GetMappedControl(1)
EndFunction
