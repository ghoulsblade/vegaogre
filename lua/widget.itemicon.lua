cItemIcon = RegisterWidgetClass("ItemIcon","Group")
cEquipSlot = RegisterWidgetClass("EquipSlot","Group")

local btn_round		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button.png")							,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back1		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad1.png")	,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back2		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad2.png")	,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_midtrans	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans.png")				,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
	
function cItemIcon:Init (parentwidget, params)
	local w,h = 48,48
	self.back = self:_CreateChild("Image",{gfxparam_init=btn_back1})
	self.icon = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat(params.image),w,h)})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})

end


function cEquipSlot:Init (parentwidget, params)
	local w,h = 48,48
	self.back = self:_CreateChild("Image",{gfxparam_init=btn_back2})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
end


--[[

	-- Image params: gfxparam_init(w,h):CreateSpritePanel 
function cItemIcon:Init 	(parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = false,true
	self:InitAsSpritePanel(parentwidget,params,bVertexBufferDynamic,bVertexCol)
	
	self.content = self:_CreateChild("Group") -- for sub-widgets like label,image...
	
	if (params.label) then 
		params.label_params = {text=params.label,textparam=params.textcol,font=params.font}
	end
	
	if (params.label_params) then self.text = self:CreateContentChild("Text",params.label_params) end
	if (params.image_params) then self:CreateContentChild("Image",params.image_params) end
	self:UpdateContent()
	if (params.x) then self:SetLeftTop(params.x,params.y) end
	if (params.on_button_click) then self.on_button_click = params.on_button_click end
end

gWidgetPrototype.Button.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function gWidgetPrototype.Button:GetContent					() return self.content end

function gWidgetPrototype.Button:SetText			(text) if (self.text) then self.text:SetText(text) end end
function gWidgetPrototype.Button:UpdateContent		() 
	local cont = self.content
	local l = self.params.margin_left	or 0
	local t = self.params.margin_top	or 0
	local r = self.params.margin_right	or 0
	local b = self.params.margin_bottom	or 0
	cont:SetLeftTop(l,t)
	local w,h = cont:GetSize()
	if (self.params.w) then w = self.params.w end
	if (self.params.h) then h = self.params.h end
	self:SetSize(l+w+r,t+h+b)
end

function gWidgetPrototype.Button:on_set_size			(w,h) 
	local gfxparam = self.params.gfxparam_init
	if (not gfxparam) then return end
	gfxparam.w = w
	gfxparam.h = h
	self.spritepanel:Update(gfxparam) -- adjust base geometry
	self:UpdateGfx() -- apply mods
end

function gWidgetPrototype.Button:on_mouse_left_down	() self.bMouseDown = true		self:UpdateGfx() end
function gWidgetPrototype.Button:on_mouse_left_up	() self.bMouseDown = false		self:UpdateGfx() end
function gWidgetPrototype.Button:on_mouse_enter		() self.bMouseInside = true		self:UpdateGfx() end
function gWidgetPrototype.Button:on_mouse_leave		() self.bMouseInside = false	self:UpdateGfx() end

function gWidgetPrototype.Button:UpdateGfx	()
	self.spritepanel:Update( self:GetGfxParam(self.bMouseInside,self.bMouseDown) )
end

function gWidgetPrototype.Button:SetGfxParam	(bMouseInside,bMouseDown,gfxparam)
	if (bMouseInside) then
			if (bMouseDown) then self.params.gfxparam_in_down  = gfxparam else self.params.gfxparam_in_up  = gfxparam end
	else	if (bMouseDown) then self.params.gfxparam_out_down = gfxparam else self.params.gfxparam_out_up = gfxparam end
	end
end

function gWidgetPrototype.Button:GetGfxParam	(bMouseInside,bMouseDown)
	if (bMouseInside) then
			if (bMouseDown) then return self.params.gfxparam_in_down  else return self.params.gfxparam_in_up  end
	else	if (bMouseDown) then return self.params.gfxparam_out_down else return self.params.gfxparam_out_up end
	end
end
]]--

