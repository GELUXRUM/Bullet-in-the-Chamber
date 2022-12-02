ScriptName BitCh_FireModeExpanded extends Quest
{script by eclix used to allow auto weapons to fire in semi-auto}

Group Actions
    Action Property ActionRightRelease Auto
EndGroup

Group Keywords
    ;/ we only want weapons that are automatic by default to be
    eligible for the switch to semi-auto mode/;
    Keyword Property WeaponTypeAutomatic Auto
    ; the keyword used to track the fire-mode of the weapon
    Keyword Property FireModeControl Auto
EndGroup

Group Sounds
    Sound Property SwitchSound Auto
EndGroup

Actor PlayerRef

Event OnInit()
    PlayerRef = Game.GetPlayer()
    RegisterForControl("PrimaryAttack")
    RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    ; just in case
    RegisterForControl("PrimaryAttack")
EndEvent

Event OnControlDown(string control)
    ; trigger has been pressed and the weapon is in our semi auto mode
    If control == "PrimaryAttack" && PlayerRef.WornHasKeyword(FireModeControl)
        ; send the action to release the trigger
        PlayerRef.PlayIdleAction(ActionRightRelease)
    EndIf
EndEvent

Function ToggleFireMode()
    ; check if the gun is automatic
    If (PlayerRef.WornHasKeyword(WeaponTypeAutomatic))
        ; some stuff to make life easier when writing the rest of the script:
        int slotIndex = Game.GetPlayer().GetEquippedItemType(0) + 32
        instanceData:Owner thisInstance = Game.GetPlayer().GetInstanceOwner(slotIndex)
        ; the player
        Actor ThePlayer = Game.GetPlayer()
        ; current weapon
        Weapon TheWeapon = ThePlayer.GetEquippedWeapon(0)
        ; we check if their weapon is already in semi auto mode
        If (instancedata.GetKeywords(thisInstance)).Find(FireModeControl) == -1
            ; add the keyword
            instancedata.SetKeywords(thisInstance, AddRemoveSemiKeyword(instancedata.GetKeywords(thisInstance), FireModeControl, "Add"))
            If (instancedata.GetKeywords(thisInstance)).Find(FireModeControl) != -1
                ; check it worked and send notification
                Debug.Notification("Semi-auto")
            EndIf
        Else
            ; remove the keyword
            instancedata.SetKeywords(thisInstance, AddRemoveSemiKeyword(instancedata.GetKeywords(thisInstance), FireModeControl, "Remove"))
            ; check it worked and send notification
            If (instancedata.GetKeywords(thisInstance)).Find(FireModeControl) == -1
                Debug.Notification("Full auto")
            EndIf
        EndIf
        ; play the sound to indicate that fire-mode has been switched
        SwitchSound.Play(PlayerRef)
    EndIf
EndFunction

; this will add/remove a keyword to the current instance of a weapon
Keyword[] Function AddRemoveSemiKeyword(Keyword[] mainArray, keyword OurSemiAutoKeyword, string sWhatDo)
	; generate an array for later
	Keyword[] tempArray = new Keyword[0]
	; copy the keywords on the weapon into the new array
	tempArray = mainArray
	; do different stuff depending on what sorts of stuff we want to do
	if sWhatDo == "Add"
		; add the keyword into the array
		tempArray.Add(OurSemiAutoKeyword)
		; this is the final array
		return tempArray
	elseIf sWhatdo == "Remove"
		; find the position of the keyword we want to remove 
		int removeFrom = tempArray.Find(OurSemiAutoKeyword)
		; remove the keyword from that position
		tempArray.Remove(removeFrom)
		; this is the final array 2: electric boogaloo
		return tempArray
	endIf
endFunction