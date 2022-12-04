scriptname BitCh_SeamlessTacticalReload extends quest

group actors
	actor property playerRef auto
endGroup

function racticalReloadToggle()
	; check if TR is installed before doing anything
	if game.isPluginInstalled("TacticalReload.esm")
		;/ grab the keyword from Tactical Reload. This allows us to not have it
		as a master to the main mod which will benefit players who do not use TR/;
		keyword AnimsReloadReserve = game.getFormFromFile(0x00001734, "TacticalReload.esm") as keyword
    	; setting up the instance
    	int slotIndex = playerRef.getEquippedItemType(0) + 32
    	instanceData:Owner thisInstance = playerRef.getInstanceOwner(slotIndex)
    	; check if the player has a weapon AND if the weapon is not melee AND whether it's drawn
    	if playerRef.getEquippedWeapon(0) as bool && instanceData.getAmmo(thisInstance) as bool && playerRef.isWeaponDrawn() as bool
			; if there is no AnimsReloadReserve keyword
    	    if (instanceData.getKeywords(thisInstance)).find(AnimsReloadReserve) == -1
				; we add it!
    	        instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), AnimsReloadReserve, "add"))
    	        debug.notification("TR Keyword Applied")
			; and if there is
			else
				; we remove it!
    	        instanceData.setKeywords(thisInstance, chamberTheKeyword(instanceData.getKeywords(thisInstance), AnimsReloadReserve, "remove"))
    	        debug.notification("TR Keyword Removed")
    	    endIf
    	endIf
	else
		; in case the player is silly and tries to use TR without having TR
		debug.messageBox("Tactical Reload is not installed!")
	endIf
endFunction

keyword[] function chamberTheKeyword(keyword[] mainArray, keyword keywordToDoButtStuffWith, string sWhatDo)
	; generate an array for later
	keyword[] tempArray = new keyword[0]
	; copy the keywords on the weapon into the new array
	tempArray = mainArray
	; do different stuff depending on what sorts of stuff we want to do
	if sWhatDo == "add"
		; add the keyword into the array
		tempArray.add(keywordToDoButtStuffWith)
		; this is the final array
		return tempArray
	elseIf sWhatdo == "remove"
		; find the position of the keyword we want to remove 
		int removeFrom = tempArray.find(keywordToDoButtStuffWith)
		; remove the keyword from that position
		tempArray.remove(removeFrom)
		; this is the final array 2: electric boogaloo
		return tempArray
	endIf
endFunction