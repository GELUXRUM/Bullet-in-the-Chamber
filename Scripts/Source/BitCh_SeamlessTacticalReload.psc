Scriptname BitCh_SeamlessTacticalReload extends Quest

Function TacticalReloadToggle()
	; check if TR is installed before doing anything
	If Game.IsPluginInstalled("TacticalReload.esm")
		;/ grab the keyword from Tactical Reload. This allows us to not have it
		as a master to the main mod which will benefit players who do not use TR/;
		Keyword AnimsReloadReserve = Game.GetFormFromFile(0x00001734, "TacticalReload.esm") as Keyword
    	; setting up the instance
    	int slotIndex = Game.GetPlayer().GetEquippedItemType(0) + 32
    	instanceData:Owner thisInstance = Game.GetPlayer().GetInstanceOwner(slotIndex)
    	; check if the player has a weapon AND if the weapon is not melee AND whether it's drawn
    	If Game.GetPlayer().GetEquippedWeapon(0) as bool && instanceData.GetAmmo(thisInstance) as bool && Game.GetPlayer().IsWeaponDrawn() as bool
			; if there is no AnimsReloadReserve keyword
    	    If (instanceData.GetKeywords(thisInstance)).Find(AnimsReloadReserve) == -1
				; we add it!
    	        instanceData.SetKeywords(thisInstance, ChamberTheKeyword(instanceData.GetKeywords(thisInstance), AnimsReloadReserve, "Add"))
    	        Debug.Notification("TR Keyword Applied")
			; and if there is
    	    Else
				; we remove it!
    	        instanceData.SetKeywords(thisInstance, ChamberTheKeyword(instanceData.GetKeywords(thisInstance), AnimsReloadReserve, "Remove"))
    	        Debug.Notification("TR Keyword Removed")
    	    EndIf
    	EndIf
	Else
		; in case the player is silly and tries to use TR without having TR
		Debug.MessageBox("Tactical Reload is not installed!")
	EndIf
EndFunction

Keyword[] Function ChamberTheKeyword(Keyword[] mainArray, keyword keywordToDoButtStuffWith, string sWhatDo)
	; generate an array for later
	Keyword[] tempArray = new Keyword[0]
	; copy the keywords on the weapon into the new array
	tempArray = mainArray
	; do different stuff depending on what sorts of stuff we want to do
	if sWhatDo == "Add"
		; add the keyword into the array
		tempArray.Add(keywordToDoButtStuffWith)
		; this is the final array
		return tempArray
	elseIf sWhatdo == "Remove"
		; find the position of the keyword we want to remove 
		int removeFrom = tempArray.Find(keywordToDoButtStuffWith)
		; remove the keyword from that position
		tempArray.Remove(removeFrom)
		; this is the final array 2: electric boogaloo
		return tempArray
	endIf
endFunction