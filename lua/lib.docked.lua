-- player docked to a station etc, show background, hide 3d universe

--~ ./sprites/bases/frigid_mud/AridBar1.sprite:1:bases/frigid_mud/AridBar1.image true
--~ ./bases/frigid_mud.py:29:Base.Texture (bar2, 'tex', 'bases/frigid_mud/AridBar1.sprite', 0, 0)

gDefaultBaseBackground = {
	rock						= "landing.dds",
	frigid_mud					= "AridConcourse.dds",
	military					= "military_concourse.dds",
	civilian					= "civilian_concourse.dds",
	carribean					= "concourse.dds",
	forest						= "concourse.dds",
	commerce					= "missioninside.dds",
	aera						= "aera_planet.dds",
	Rlaan_Star_Fortress			= "rlaan_landing.dds",
	generic						= "base_concourse.dds",		--data/sprites/bases/ocean/ocean_concourse.dds
	mining						= "mining_concourse.dds",
	agriculture					= "agricultural_concourse.dds",
	desert						= "desert_concourse.dds",
	Lava						= "landing.dds",
	industrial					= "industrial_concourse.dds",
	Shaper_Bio_Adaptation		= "landing.dds",
	Snow						= "concourse.dds",
	ocean						= "ocean_concourse.dds",
	gas							= "landing.dds",
	generic_ship				= "generic_ship.dds",
	
	MiningBase					= "mining_concourse.dds", -- data/bases/MiningBase.py -> mining_lib.py -> data/sprites/bases/mining
	Fighter_Barracks			= "military_concourse.dds", -- data/bases/Fighter_Barracks.py -> military_lib.py 
}


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
	print("StartDockedMode",base and base:GetFileAttrTxt(),base and base:GetFileAttrLastBase())
	gSolRootGfx:SetParent()
	gMLocBaseGfx:SetParent()
	GetHUDBaseWidget():SetVisible(false) -- hudgfx : target&self indicator, markers
	
	
	-- todo : decide background and available services from "base" param
	--~ <Unit name="Serenity" file="MiningBase"  radius="130.477371"  faction="klkk"  >
	SetDockedBackground(base and gDefaultBaseBackground[base:GetFileAttrLastBase()] or "ocean_concourse.dds")
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


