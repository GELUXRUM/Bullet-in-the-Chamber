scriptname BitCh_ButtonsForMCM extends quest
{used to repair broken mechanics or shutdown event calls}

BitCh_ReloadExpanded property reloadScript auto
BitCh_AmmoDropScript property ammoDropScript auto

function registerEvents()
    debug.notification("Beginning Event registration:")
    reloadScript.registerEvents()
    ammoDropScript.registerEvents()
    debug.notification("Event registration complete!")
endFunction

function unregisterEvents()
    debug.notification("Beginning Event unregistration:")
    reloadScript.unregisterEvents()
    ammoDropScript.unregisterEvents()
    debug.notification("Event unregistration complete!")
endFunction