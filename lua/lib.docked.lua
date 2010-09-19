-- player docked to a station etc, show background, hide 3d universe


function ToggleDockedMode (o) 
	if (gDockedMode) then EndDockedMode() else StartDockedMode(gSelectedObject) end
end

function EndDockedMode ()
	gDockedMode = false
	print("EndDockedMode")
	gSolRootGfx:SetRootAsParent()
	gMLocBaseGfx:SetRootAsParent()
	GetHUDBaseWidget():SetVisible(true)
	SetDockedBackground()
end

function StartDockedMode (base)
	gDockedMode = true
	print("StartDockedMode")
	gSolRootGfx:SetParent()
	gMLocBaseGfx:SetParent()
	GetHUDBaseWidget():SetVisible(false) -- hudgfx : target&self indicator, markers
	
	-- todo : decide background and available services from "base" param
	SetDockedBackground("ocean_concourse.dds")
end

function SetDockedBackground (texname)
	if (gBaseBackground) then gBaseBackground:Destroy() gBaseBackground = nil end
	
	if (not texname) then return end
	-- texname = "ocean_concourse.dds"
	-- texname = "military_concourse.dds"
	local s = min(gViewportW,gViewportH) s = 1024
	local w,h = s,s
	gBaseBackground = GetDesktopWidget():CreateContentChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetTexturedMat("background_base",texname),w,h)})
	--~ gBaseBackground = GetDesktopWidget():CreateContentChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetTexturedMat("guibasemat",texname),w,h)})
	gBaseBackground:SetPos(gViewportW/2-w/2,gViewportH/2-h/2)
end


