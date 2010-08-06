cItemIcon = RegisterWidgetClass("ItemIcon","Group")
cEquipSlot = RegisterWidgetClass("EquipSlot","Group")

local btn_round			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button.png")									,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back1			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad1.png")			,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back2			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad2.png")			,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)

local function copyparam (t,mods) local res = {} for k,v in pairs(t) do res[k] = v end for k,v in pairs(mods or {}) do res[k] = v end return res end

gEquipSlotType = {
	weapon	= { iconback=copyparam(btn_back2,{r=.9,g=.5,b=.4}) }, -- red
	equip	= { iconback=copyparam(btn_back2,{r=.9,g=.8,b=.4}) }, -- yellow
	shield	= { iconback=copyparam(btn_back2,{r=.7,g=.7,b=.9}) }, -- blue
	engine	= { iconback=copyparam(btn_back2,{r=.7,g=.9,b=.7}) }, -- green
}
local btn_back_red		= copyparam(btn_back2,{r=1,g=0,b=0})
local btn_back_green	= copyparam(btn_back2,{r=0,g=1,b=0})
local btn_back_yellow	= copyparam(btn_back2,{r=1,g=1,b=0})
local btn_back_Blue		= copyparam(btn_back2,{r=0,g=0,b=1})
local btn_midtrans		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans.png")						,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
	
function cItemIcon:Init (parentwidget, params)
	local w,h = 48,48
	self.back = self:_CreateChild("Image",{gfxparam_init=btn_back1})
	self.icon = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat(params.image),w,h)})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
end


function cEquipSlot:Init (parentwidget, params)
	local w,h = 48,48
	assert(params.type) 
	local t = gEquipSlotType[params.type] assert(t)
	self.back = self:_CreateChild("Image",{gfxparam_init=t.iconback})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
end

