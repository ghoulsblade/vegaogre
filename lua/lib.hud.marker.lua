cHudMarker	= RegisterWidgetClass("HudMarker","Group")

gSelectedObject = nil

RegisterIntervalStepper(500,function () if (gHudMarkerMouseOver) then gHudMarkerMouseOver:IntervalStep() end end)
	
function cHudMarker:Init (parentwidget, params)
	local o = params.obj
	self.obj = o
	
	local r,g,b = self:GetColor()
	local gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("hud_obj_frame.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	self.gfxparam_init = gfxparam_init
	tablemod(gfxparam_init,{r=r,g=g,b=b})
	self.frame = self:_CreateChild("Image",{gfxparam_init=gfxparam_init})
	
	--~ local w,h = 32,32
	--~ self.img2 = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("repulsor_beam.image.png"),w,h)})

	if (o.name) then self.text = self:_CreateChild("Text",{text=o.name,textparam={r=r,g=g,b=b}}) end
	
	--~ self:SetConsumeChildHit(true)  -- not needed due to child events passing through if unhandled
end

function cHudMarker:on_mouse_left_down		() if (gGuiMouseModeActive) then self:SetSelected() end end
function cHudMarker:on_mouse_enter			() self:ShowMouseOverText(true) gHudMarkerMouseOver = self end
function cHudMarker:on_mouse_leave			() self:ShowMouseOverText(false) if (gHudMarkerMouseOver == self) then gHudMarkerMouseOver = nil end end

function cHudMarker:GetColor ()
	if (self.obj == gSelectedObject) then return 0,1,0 end
	return 1,1,1
end

function cHudMarker:SetSelected () self.obj:SelectObject() end

function cHudMarker:UpdateDistanceFade ()
	local s = 1
	if (self.obj ~= gSelectedObject) then 
		local d = self.params.obj:GetDistToPlayer()
		if (d > 100*km) then s = 0.9 end
		if (d > 10*1000*km) then s = 0.8 end
		if (d > 0.1*au) then s = 0.5 end
	end
	if (self.fade_strength == s) then return end
	self.fade_strength = s
	self:UpdateGfx()
end
function cHudMarker:UpdateGfx ()
	local r,g,b = self:GetColor()
	local p = self.gfxparam_init
	local s = self.fade_strength or 1
	p.r = s*r 
	p.g = s*g 
	p.b = s*b 
	p.a = s 
	self.frame:SetGfxParam(p)
	local o = self.obj
	if (o.name and self.text) then self.text:SetCol(p.r,p.g,p.b,p.a) self.text:SetText(o.name) end
end
function cHudMarker:IntervalStep ()
	self:ShowMouseOverText(true)
end
function cHudMarker:ShowMouseOverText (bVisible)
	if (self.overtxt) then self.overtxt:Destroy() self.overtxt = nil end
	if (not bVisible) then return end
	local o = self.params.obj
	local txt = "("..o:GetClass()..")"..GetDistText(o:GetDistToPlayer())
	local r,g,b = self:GetColor()
	self.overtxt = self:_CreateChild("Text",{text=txt,textparam={r=r,g=g,b=b}})
	self.overtxt:SetPos(0,-20)
end
function cHudMarker:Step (obj)
	local x,y,z = obj:GetPosForMarker()
	local bIsInFront,px,py,cx,cy = ProjectSizeAndPos(x,y,z, obj.r)
	
	local w = (cx * gViewportW)
	local h = (cy * gViewportH)

	local minSize = 16
	local maxSize = 128

	w = max(minSize, min(w, maxSize))
	h = max(minSize, min(h, maxSize))

	local x = floor(gViewportW * ( px+1)/2)
	local y = floor(gViewportH * (-py+1)/2)
	
	self:SetPos(x, y)
	self.frame:SetPos(-w/2,-h/2)
	self.frame:SetSize(w, h)
	self:UpdateDistanceFade()
end

-- draws hud markers at obj.x/y/z with size obj.r
function stepHudMarker(obj)
	if (not obj.guiMarker) then obj.guiMarker = GetDesktopWidget():CreateContentChild("HudMarker",{obj=obj}) end
	if (obj.guiMarker) then obj.guiMarker:Step(obj) end
end

function destroyHudMarker(obj)
	if (obj.guiMarker) then obj.guiMarker:Destroy() obj.guiMarker = nil end
end

