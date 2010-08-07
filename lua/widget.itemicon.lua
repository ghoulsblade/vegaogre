cItemIcon = RegisterWidgetClass("ItemIcon","Group")
cEquipSlot = RegisterWidgetClass("EquipSlot","Group")

local btn_round			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button.png")							,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back1			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad1.png")	,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back2			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad2.png")	,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_midtrans		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans.png")				,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)

gEquipSlotType = {
	weapon	= { iconback=clonemod(btn_back2,{r=.9,g=.5,b=.4}) }, -- red
	equip	= { iconback=clonemod(btn_back2,{r=.9,g=.8,b=.4}) }, -- yellow
	shield	= { iconback=clonemod(btn_back2,{r=.7,g=.7,b=.9}) }, -- blue
	engine	= { iconback=clonemod(btn_back2,{r=.7,g=.9,b=.7}) }, -- green
}
	
function cItemIcon:Init (parentwidget, params)
	local w,h = 48,48
	self.back = self:_CreateChild("Image",{gfxparam_init=btn_back1})
	self.icon = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat(params.image),w,h)})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
end
function cItemIcon:on_mouse_left_down	() print("cItemIcon:on_mouse_left_down	",self.params.image) end
function cItemIcon:on_mouse_left_up		() print("cItemIcon:on_mouse_left_up	",self.params.image) end
function cItemIcon:on_mouse_enter		() print("cItemIcon:on_mouse_enter		",self.params.image) end
function cItemIcon:on_mouse_leave		() print("cItemIcon:on_mouse_leave		",self.params.image) end

function cEquipSlot:Init (parentwidget, params)
	local w,h = 48,48
	assert(params.type) 
	local t = gEquipSlotType[params.type] assert(t)
	self.back = self:_CreateChild("Image",{gfxparam_init=t.iconback})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
end

