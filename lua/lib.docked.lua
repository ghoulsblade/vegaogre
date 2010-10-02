-- player docked to a station etc, show background, hide 3d universe

--~ ./sprites/bases/frigid_mud/AridBar1.sprite:1:bases/frigid_mud/AridBar1.image true
--~ ./bases/frigid_mud.py:29:Base.Texture (bar2, 'tex', 'bases/frigid_mud/AridBar1.sprite', 0, 0)

-- base_locationmarker.dds

gDockedInfo = {}

--~ RegisterListener("Hook_SystemLoaded",function () StartDockedMode({},"agriculture") end)
--~ RegisterListener("Hook_SystemLoaded",function () StartDockedMode(nil,"ocean") end)

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

gBaseRooms = {
	agriculture = {
		concourse	= {bg="agricultural_concourse.dds"		,links={ bar={622,440}, hangar={848,406}, trade={495,486}, shipyards={266,474},	}}, -- default conourse positions
		
		hangar		= {bg="agricultural_landing.dds"		,links={ trade={408,435}, weapon={777,426}, concourse={558,304}, LIFTOFF={507,49}, }},
		trade		= {bg="agricultural_traderoom.dds"		,links={ hangar={375,484}, 	}},		-- containers on land zoomin
		weapon		= {bg="agricultural_weaponsroom.dds"	,links={ trade={958,372},	}},		-- weapon room no conn
		
		bar			= {bg="agricultural_bar.dds"			,links={ concourse={627,517}, BARTENDER={162,576}, TABLE1={574,613}, TABLE2={952,703} }},
		ext1		= {bg="agricultural_exterior1.dds"		,links={ hangar={450,650}, ext2={120,456}, shipyards={716,516}, }}, -- mountainview
		ext2		= {bg="agricultural_exterior2.dds"		,links={ hangar={421,316}, ext1={639,142}, shipyards={ 54,376}, }}, -- towers
		shipyards	= {bg="agricultural_exterior3.dds"		,links={ hangar={192,390}, ext1={297,258}, ext2={736,324}, }}, -- ships
	},
	
	ocean = {
		concourse		= {bg="ocean_concourse.dds"			,links={ bar={622,440}, hangar={848,406}, ext_to_trade={495,486}, ext_to_shipy={266,474},	}}, -- default conourse positions
		
		hangar			= {bg="ocean_landing.dds"			,links={ LIFTOFF={350,400}, concourse={495,960}, }},
		bar				= {bg="ocean_bar.dds"				,links={ concourse={528,924}, }},
		trade			= {bg="ocean_exterior1.dds" 		,links={ ext_to_trade={458,168}, }},
		shipyards		= {bg="ocean_exterior4.dds" 		,links={ ext_to_shipy={560,120}, }},
		ext_to_trade	= {bg="ocean_exterior2.dds" 		,links={ concourse={363,441}, trade={195,360}, }}, -- dark big tower view from below
		ext_to_shipy	= {bg="ocean_exterior3.dds" 		,links={ concourse={756,158}, shipyards={230,354}, }}, -- tubes view from above
	},
}

-- ***** ***** ***** ***** ***** rooms

cDockedRoomLink	= RegisterWidgetClass("DockedRoomLink","Group")

function cDockedRoomLink:Init (parentwidget, params)
	self:SetPos(params.x,params.y)
	local w,h = 64,64
	self.img = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("base_locationmarker.dds"),w,h)})
	self.img:SetPos(-w/2,-h/2)
	print("cDockedRoomLink:Init",params.x,params.y)
end
function cDockedRoomLink:on_mouse_left_down		()
	local p = self.params
	print("cDockedRoomLink:on_mouse_left_down",p,p.roomname)
	DockedStartRoom(p.roomname)
end

gDockedRoomLinkWidgets = {}

function ClearRoomGfx ()
	-- kill old 
	for k,widget in ipairs(gDockedRoomLinkWidgets) do widget:Destroy() end 
	gDockedRoomLinkWidgets = {}
end

function DockedStartRoom (roomname)
	print("DockedStartRoom",roomname)
	if (roomname == "LIFTOFF") then EndDockedMode() return end
	ClearRoomGfx()
	
	local basetype = gDockedInfo.basetype
	local rooms = basetype and gBaseRooms[basetype]
	local room = rooms and rooms[roomname]
	SetDockedBackground(room and room.bg or (basetype and gDefaultBaseBackground[basetype]) or "ocean_concourse.dds")
	
	local sx = gDockedInfo.bg_w / gDockedInfo.bg_w_orig
	local sy = gDockedInfo.bg_h / gDockedInfo.bg_h_orig
	local xoff,yoff = gDockedInfo.bg_xoff,gDockedInfo.bg_yoff
	--~ print("rooms off=",xoff,yoff,"s=",sx,sy)
	
	for roomname,pos in pairs(room and room.links or {}) do 
		local x,y = unpack(pos)
		local b = 20
		x = max(b,min(gViewportW-b,floor(xoff + sx*x)))
		y = max(b,min(gViewportH-b,floor(yoff + sy*y)))
		table.insert(gDockedRoomLinkWidgets,GetDesktopWidget():CreateContentChild("DockedRoomLink",{x=x,y=y,roomname=roomname,roomdata=rooms[roomname]}))
	end
end


-- ***** ***** ***** ***** ***** rest


function IsDockedModeActive () return gDockedMode end
function ToggleDockedMode (o) 
	if (gDockedMode) then EndDockedMode() else StartDockedMode(gSelectedObject) end
end

function EndDockedMode ()
	gDockedMode = false
	print("EndDockedMode")
	gSolRootGfx:SetRootAsParent()
	gMLocBaseGfx:SetRootAsParent()
	GetHUDBaseWidget():SetVisible(true)
	ClearRoomGfx()
	SetDockedBackground()
end


function StartDockedMode (base,force_basetype)
	gDockedMode = true
	print("StartDockedMode",base and base:GetFileAttrTxt(),base and base:GetFileAttrLastBase())
	gSolRootGfx:SetParent()
	gMLocBaseGfx:SetParent()
	GetHUDBaseWidget():SetVisible(false) -- hudgfx : target&self indicator, markers
	
	-- todo : decide background and available services from "base" param
	--~ <Unit name="Serenity" file="MiningBase"  radius="130.477371"  faction="klkk"  >
	
	gDockedInfo = {}
	gDockedInfo.base		= base
	gDockedInfo.basetype	= force_basetype or (base and base:GetFileAttrLastBase())
	
	DockedStartRoom("hangar")
end

function GetTextureResolution (texname)
	local tex = GetOgreTexture(texname) assert(tex)
	return tex:getWidth(),tex:getHeight()
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
	local xoff,yoff = floor(gViewportW/2-w/2),floor(gViewportH/2-h/2)
	print("docked bg",xoff,yoff,gViewportW,gViewportH,w,h)
	gBaseBackground:SetPos(xoff,yoff)
	
	local w_orig,h_orig = GetTextureResolution(texname) 
	--~ print("docked bg orig",texname,w_orig,h_orig)
	
	gDockedInfo.bg_xoff = xoff
	gDockedInfo.bg_yoff = yoff
	gDockedInfo.bg_w = w
	gDockedInfo.bg_h = h
	gDockedInfo.bg_w_orig = w_orig
	gDockedInfo.bg_h_orig = h_orig
end

