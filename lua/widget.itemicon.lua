cItemIcon	= RegisterWidgetClass("ItemIcon","Group")
cEquipSlot	= RegisterWidgetClass("EquipSlot","Group")
cItemGrid	= RegisterWidgetClass("ItemGrid","Group")

local btn_round			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button.png")							,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back1			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad1.png")	,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_back2			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans_back_grad2.png")	,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
local btn_midtrans		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("rounded_button_mid_trans.png")				,48,48,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)

gEquipSlotType = {
	weapon_light			= { iconback=clonemod(btn_back2,{r=.5,g=.9,b=.5}) }, -- green
	weapon_light_missile	= { iconback=clonemod(btn_back2,{r=.9,g=.5,b=.4}) }, -- red
	
	equip					= { iconback=clonemod(btn_back2,{r=.5,g=.5,b=.5}) }, -- gray
	
	spec					= { iconback=clonemod(btn_back2,{r=.9,g=.8,b=.4}) }, -- yellow
	jump					= { iconback=clonemod(btn_back2,{r=.9,g=.8,b=.4}) }, -- yellow
	sensors					= { iconback=clonemod(btn_back2,{r=.9,g=.8,b=.4}) }, -- yellow
	overdrive				= { iconback=clonemod(btn_back2,{r=.9,g=.8,b=.4}) }, -- yellow
	
	reactor					= { iconback=clonemod(btn_back2,{r=.7,g=.9,b=.7}) }, -- green
	armor					= { iconback=clonemod(btn_back2,{r=.7,g=.7,b=.9}) }, -- blue
	shield					= { iconback=clonemod(btn_back2,{r=.7,g=.7,b=.9}) }, -- blue
	capacitor				= { iconback=clonemod(btn_back2,{r=.7,g=.7,b=.9}) }, -- blue
}
	
function cItemIcon:Init (parentwidget, params)
	local w,h = 48,48
	self.back = self:_CreateChild("Image",{gfxparam_init=btn_back1})
	self.icon = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat(params.image),w,h)})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
	--~ self:SetConsumeChildHit(true)  -- not needed due to child events passing through if unhandled
end

function cItemIcon:on_mouse_left_drag_start		() self:StartDragDrop() end
function cItemIcon:on_start_dragdrop			() return true end -- returns true if allowed
function cItemIcon:on_cancel_dragdrop			() end -- returns true if completely handled (don't use here, default handling will be used instead)
function cItemIcon:on_finish_dragdrop			(w,x,y)
	while w do 
		--~ print("on_finish_dragdrop",w,x,y,w:GetClassName())
		if (w.on_accept_drop and w:on_accept_drop(self,x,y)) then return true end
		w = w:GetParent()
	end
end -- if false/nil is returned, the drop will be cancelled

function cItemIcon:on_mouse_left_down			() if (1 == 2) then print("cItemIcon:on_mouse_left_down			",self.params.image) end end -- don't remove, otherwise passed to parent->nodrag
--~ function cItemIcon:on_mouse_left_up				() if (1 == 2) then print("cItemIcon:on_mouse_left_up			",self.params.image) end end
--~ function cItemIcon:on_mouse_enter				() if (1 == 2) then print("cItemIcon:on_mouse_enter				",self.params.image) end end
--~ function cItemIcon:on_mouse_leave				() if (1 == 2) then print("cItemIcon:on_mouse_leave				",self.params.image) end end
--~ function cItemIcon:on_mouse_left_drag_step		() if (1 == 2) then print("cItemIcon:on_mouse_left_drag_step	",self.params.image) end end
--~ function cItemIcon:on_mouse_left_drag_end		() if (1 == 2) then print("cItemIcon:on_mouse_left_drag_end		",self.params.image) end end -- not used

-- ***** ***** ***** ***** ***** DragDrop base

function cItemIcon:StartDragDrop			()
	if (self.on_start_dragdrop and self:on_start_dragdrop()) then else return end
	self.drag_old_parent = self:GetParent()
	self.drag_old_x,self.drag_old_y = self:GetPos()
	local x,y = self:GetDerivedPos()
	self:SetParent(GetDesktopWidget())
	self:SetPos(x,y)
	self:StartMouseMove(key_mouse_left,nil,nil,function (x,y) self:EndDragDrop(x,y) end,gLastMouseDownX,gLastMouseDownY)
end

function cItemIcon:CancelDragDrop			(x,y)
	if (self.on_cancel_dragdrop and self:on_cancel_dragdrop()) then return end -- returns true if on_cancel was handled completely
	self:SetParent(self.drag_old_parent)
	self:SetPos(self.drag_old_x,self.drag_old_y)
end

function cItemIcon:EndDragDrop				(x,y)
	local w = GetDesktopWidget():GetWidgetUnderPos(x,y)
	--~ print("cItemIcon:EndDragDrop widget under pos",x,y,w)
	if (w and w:GetParent() == self) then print("cItemIcon:todo:disable self-child-hit on dragdrop") w = nil end
	if (w == self) then print("cItemIcon:todo:disable self-hit on dragdrop") w = nil end
	if (not w) then self:CancelDragDrop() return end
	if (self.on_finish_dragdrop and self:on_finish_dragdrop(w,x,y)) then else self:CancelDragDrop() end
end

-- ***** ***** ***** ***** ***** cEquipSlot

function cEquipSlot:Init (parentwidget, params)
	local w,h = 48,48
	assert(params.type) 
	local t = gEquipSlotType[params.type] assert(t,"missing type :"..tostring(params.type))
	self.back = self:_CreateChild("Image",{gfxparam_init=t.iconback})
	self.frame = self:_CreateChild("Image",{gfxparam_init=btn_midtrans})
end

function cEquipSlot:on_accept_drop (w,x,y) -- return false if not accepted
	--~ print("cEquipSlot:on_accept_drop",w,x,y,w:GetClassName())
	if (self.item and self.item:GetParent() == self) then return false end
	self.item = w
	w:SetParent(self)
	w:SetPos(0,0)
	return true
end

-- ***** ***** ***** ***** ***** cItemGrid

function cItemGrid:Init (parentwidget, params)
	self:SetSize(params.w,params.h)
	self:SetIgnoreBBoxHit(false)
end

function cItemGrid:on_mouse_left_down	() end -- override so it isn't passed to parent

function cItemGrid:FindItemOnPos(x,y)
	for k,w in ipairs(self:_GetOrderedChildList()) do local cx,cy = w:GetPos() if (x == cx and y == cy) then return x end end
end

function cItemGrid:on_accept_drop (w,x,y) -- return false if not accepted
	--~ print("cItemGrid:on_accept_drop",w,x,y,w:GetClassName())
	local ox,oy = self:GetDerivedPos()
	local e = 50
	x,y = e*floor((x-ox)/e),e*floor((y-oy)/e)
	if (self:FindItemOnPos(x,y)) then return false end -- already something at this position
	w:SetParent(self)
	w:SetPos(x,y)
	return true
end

-- ***** ***** ***** ***** ***** ScrollPaneB


cScrollPaneB		= RegisterWidgetClass("ScrollPaneB","Group")

local plainborder				= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("plainborder.png")		,8,8,0,0, 0,0, 3,2,3, 3,2,3, 8,8, 1,1, false,false)
local plainborder2				= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("plainborder2.png")		,8,8,0,0, 0,0, 3,2,3, 3,2,3, 8,8, 1,1, false,false)
local matrix_button_small_thumb	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("button_small_thumb.png")	,16,16,0,0, 0,0, 6,4,6, 6,4,6, 32,32, 1,1, false,false)
local matrix_button_small_up	= MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("button_small_up.png")		,16,16,0,0, 0,0, 16,16, 32,32)
local matrix_button_small_down	= MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("button_small_down.png")		,16,16,0,0, 0,0, 16,16, 32,32)
local spritebutton_4x4_mods		= {	gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
									gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
									gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
									gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
									margin_left= 0,
									margin_top= 0,
									margin_right= 0,
									margin_bottom= 0,
								}

function cScrollPaneB:Init (parentwidget, params)
	self:SetIgnoreBBoxHit(false)
	local w,h = params.w,params.h
	local e,b = 16,3
	self.clipped	= self:_CreateChild("Group")
	self.content	= self.clipped:_CreateChild("Group")
	self.frame		= self:_CreateChild("Image",{gfxparam_init=clonemod(plainborder2,{w=w-e,h=h})})
	self.frame:SetIgnoreBBoxHit(true) -- pass through to childs of content
	self.bar		= self:_CreateChild("Image",{gfxparam_init=clonemod(plainborder,{w=e,h=h,h=h-2*e+2*b})}) self.bar:SetPos(w-e,e-b)
	self.btn_up		= self:_CreateChild("Button",tablemod({gfxparam_init = matrix_button_small_up		,x=w-e,y=0,w=e,h=e}		,spritebutton_4x4_mods))
	self.btn_dn		= self:_CreateChild("Button",tablemod({gfxparam_init = matrix_button_small_down		,x=w-e,y=h-e,w=e,h=e}	,spritebutton_4x4_mods))
	self.btn_thumb	= self:_CreateChild("Button",tablemod({gfxparam_init = matrix_button_small_thumb	,x=w-e,y=e*3,w=e,h=e}	,spritebutton_4x4_mods))
	local d,dt = 4,25
	self.scroll_x = 0
	self.scroll_y = 0
	self.step_dx = 0
	self.step_dy = 0
	self.w = w
	self.h = h
	self.btn_up.on_mouse_left_down		= function (btn) self:StartButtonScroll(0,-d,btn) end
	self.btn_dn.on_mouse_left_down		= function (btn) self:StartButtonScroll(0, d,btn) end
	self.btn_up.on_mouse_left_up		= function (btn) self:StopButtonScroll(btn) end
	self.btn_dn.on_mouse_left_up		= function (btn) self:StopButtonScroll(btn) end
	self.btn_thumb.on_mouse_left_down	= function (btn) btn:StartMouseMove(key_mouse_left,self.ThumbMoveStep,self) end
	self.clipped:SetClip(0,0,w-e,h)
	self:UpdateScroll(0,0)
	RegisterIntervalStepper(dt,function () return self:ScrollStep() end)
end

function cScrollPaneB:ScrollStep				()
	if (not self:IsAlive()) then return true end
	if (self.step_dx ~= 0 or self.step_dy ~= 0) then self:ScrollDelta(self.step_dx,self.step_dy) end
end
function cScrollPaneB:StopButtonScroll			(btn)		self.step_dx = 0 self.step_dy = 0 end
function cScrollPaneB:StartButtonScroll			(dx,dy,btn)	self.step_dx = dx self.step_dy = dy end

function cScrollPaneB:ScrollDelta			(dx,dy)
	self:UpdateScroll(self.scroll_x + dx,self.scroll_y + dy)
end 
function cScrollPaneB:GetScrollContentWH	()
	local l,t,r,b = self.content:GetRelBounds()
	return r,b
end
function cScrollPaneB:ThumbMoveStep			(x,y) -- returns x,y 
	local max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove = self:GetParams()
	if (max_y > 0) then
		local newscrolly = floor(max_y * max(0,min(1,(y - thumb_yoff) / thumb_maxmove)))
		if (newscrolly ~= self.scroll_y) then self:UpdateScroll(0,newscrolly,true) end
		y = max(thumb_yoff,min(thumb_yoff+thumb_maxmove,y))
	else
		y = 0
	end
	return thumb_x,y
end

-- returns max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove
function cScrollPaneB:GetParams				()
	local sw,sh = self:GetScrollContentWH()
	local w,h = self.w,self.h
	local max_x = floor(max(0,sw-w))
	local max_y = floor(max(0,sh-h))
	local btn_h = 16
	local thumb_w = 16
	local thumb_h = 16
	local thumb_maxmove = self.h - 2*btn_h - thumb_h
	local thumb_yoff = btn_h
	local thumb_x = self.w - thumb_w
	return max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove
end
function cScrollPaneB:UpdateScroll			(newx,newy,bDontMoveThumb)
	local max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove = self:GetParams()
	self.scroll_x = max(0,min(max_x,floor(newx)))
	self.scroll_y = max(0,min(max_y,floor(newy)))
	self.content:SetPos(-self.scroll_x,-self.scroll_y)
	if (not bDontMoveThumb) then 
		local x = thumb_x
		local y = thumb_yoff + ((max_y > 0) and floor(thumb_maxmove * self.scroll_y / max_y) or 0)
		self.btn_thumb:SetPos(x,y)
	end
end 
function cScrollPaneB:on_mouse_left_down	() end -- override so it isn't passed to parent

cScrollPaneB.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function cScrollPaneB:GetContent () return self.content end


