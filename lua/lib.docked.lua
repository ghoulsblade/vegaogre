-- player docked to a station etc, show background, hide 3d universe


function ToggleDockedMode () 
	if (gDockedMode) then EndDockedMode() else StartDockedMode() end
end

function EndDockedMode ()
	gDockedMode = false
	print("EndDockedMode")
	gSolRootGfx:SetRootAsParent()
	gMLocBaseGfx:SetRootAsParent()
	GetHUDBaseWidget():SetVisible(true)
end

function StartDockedMode ()
	gDockedMode = true
	print("StartDockedMode")
	gSolRootGfx:SetParent()
	gMLocBaseGfx:SetParent()
	GetHUDBaseWidget():SetVisible(false)
end


