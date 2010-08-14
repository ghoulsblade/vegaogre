cHudMarker	= RegisterWidgetClass("HudMarker","Group")

	
function cHudMarker:Init (parentwidget, params)
	local r,g,b = self:GetColor()
	local gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("hud_obj_frame.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	tablemod(gfxparam_init,{r=r,g=g,b=b})
	self.frame = self:_CreateChild("Image",{gfxparam_init=gfxparam_init})
	
	--~ local w,h = 32,32
	--~ self.img2 = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("repulsor_beam.image.png"),w,h)})

	local o = params.obj
	if (o.name) then self.text = self:_CreateChild("Text",{text=o.name,textparam={r=0,g=1,b=0}}) end
	--~ self:SetConsumeChildHit(true)  -- not needed due to child events passing through if unhandled
end

function cHudMarker:on_mouse_enter			() self:ShowMouseOverText(true) end
function cHudMarker:on_mouse_leave			() self:ShowMouseOverText(false) end
function cHudMarker:GetColor ()
	return 0,1,0
end

function GetDistText (d) 
	local thres = 0.5
	local u=au				if (d >= thres*u) then return sprintf("%0.2fau",d/u) end
	local u=light_minute	if (d >= thres*u) then return sprintf("%0.2fLm",d/u) end
	local u=light_second	if (d >= thres*u) then return sprintf("%0.2fLs",d/u) end
	local u=km				if (d >= thres*u) then return sprintf("%0.2fkm",d/u) end
	return sprintf("%0.0fm",d)
end
function cHudMarker:ShowMouseOverText (bVisible)
	if (self.overtxt) then self.overtxt:Destroy() self.overtxt = nil end
	if (not bVisible) then return end
	local o = self.params.obj
	local txt = "("..o:GetClass()..")"..GetDistText(o:GetDistToPlayer())
	self.overtxt = self:_CreateChild("Text",{text=txt,textparam={r=0,g=1,b=0}})
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
