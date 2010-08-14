cHudMarker	= RegisterWidgetClass("HudMarker","Group")

gHudMarkerSelected = nil

	
function cHudMarker:Init (parentwidget, params)
	local r,g,b = self:GetColor()
	local gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("hud_obj_frame.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	self.gfxparam_init = gfxparam_init
	tablemod(gfxparam_init,{r=r,g=g,b=b})
	self.frame = self:_CreateChild("Image",{gfxparam_init=gfxparam_init})
	
	--~ local w,h = 32,32
	--~ self.img2 = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("repulsor_beam.image.png"),w,h)})

	local o = params.obj
	self.obj = o
	if (o.name) then self.text = self:_CreateChild("Text",{text=o.name,textparam={r=r,g=g,b=b}}) end
	--~ self:SetConsumeChildHit(true)  -- not needed due to child events passing through if unhandled
end

function cHudMarker:on_mouse_left_down		() if (gGuiMouseModeActive) then self:SetSelected() end end
function cHudMarker:on_mouse_enter			() self:ShowMouseOverText(true) end
function cHudMarker:on_mouse_leave			() self:ShowMouseOverText(false) end

function cHudMarker:GetColor ()
	if (self == gHudMarkerSelected) then return 0,1,0 end
	return 1,1,1
end

function cHudMarker:SetSelected () 
	if (self == gHudMarkerSelected) then return end
	local old = gHudMarkerSelected
	gHudMarkerSelected = self
	if (old) then old:UpdateGfx() end
	self:UpdateGfx()
	HUD_UpdateSelectedObject(self.obj)
end

function GetDistText (d) 
	local thres = 0.5
	local u=au				if (d >= thres*u) then return sprintf("%0.2fau",d/u) end
	local u=light_minute	if (d >= thres*u) then return sprintf("%0.2fLm",d/u) end
	local u=light_second	if (d >=   0.1*u) then return sprintf("%0.2fLs",d/u) end
	local u=km				if (d >= thres*u) then return sprintf("%0.2fkm",d/u) end
	return sprintf("%0.0fm",d)
end
function cHudMarker:UpdateGfx ()
	local r,g,b = self:GetColor()
	local p = self.gfxparam_init
	p.r = r 
	p.g = g 
	p.b = b 
	self.frame:SetGfxParam(p)
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
end

-- draws hud markers at obj.x/y/z with size obj.r
function stepHudMarker(obj)
	if (not obj.guiMarker) then obj.guiMarker = GetDesktopWidget():CreateContentChild("HudMarker",{obj=obj}) end
	if (obj.guiMarker) then obj.guiMarker:Step(obj) end
end

function destroyHudMarker(obj)
	if (obj.guiMarker) then obj.guiMarker:Destroy() obj.guiMarker = nil end
end

-- ***** ***** ***** ***** ***** hud-image in the lower right corner

function HUD_UpdateSelectedObject (o)
	if (gHudTargetInfo) then gHudTargetInfo:Destroy() gHudTargetInfo = nil end
	gHudTargetInfo = o and GetDesktopWidget():CreateChild("HudTargetInfo",{obj=o})
end
RegisterIntervalStepper(500,function () if (gHudTargetInfo) then gHudTargetInfo:IntervalStep() end end)



cHudTargetInfo	= RegisterWidgetClass("HudTargetInfo","Group")

function cHudTargetInfo:Init (parentwidget, params)
	local w,h = 256,256
	local x,y = gViewportW-w,gViewportH-h
	self:SetPos(x,y)
	
	local o = params.obj  assert(o)
	self.obj = o
	local imgname = o:GetHUDImageName() 
	
	
	local iw = w * 0.75
	self.img = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat(imgname or "dummy.png"),iw,iw)})
	self.img:SetPos(w/2-iw/2,h/2-iw/2)

	local b = 2
	self.txt_topleft = self:_CreateChild("Text",{text="aaa",textparam={r=1,g=1,b=1}})
	self.txt_topleft:SetPos(b,b)
	self.txt_bottomleft = self:_CreateChild("Text",{text="bbb",textparam={r=1,g=1,b=1}})
	self.txt_bottomleft:SetPos(b,h-14-b-20)
	
	self:UpdateTexts()
end

function cHudTargetInfo:UpdateTexts ()
	local o = self.obj
	local txt1 = o:GetClass()
	if (o.name) then txt1 = txt1 .. "\n" .. o.name end
	
	local txt2 = GetDistText(o:GetDistToPlayer())
	
	self.txt_topleft:SetText(txt1)
	self.txt_bottomleft:SetText(txt2)
end

function cHudTargetInfo:IntervalStep () self:UpdateTexts() end

