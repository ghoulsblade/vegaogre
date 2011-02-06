-- hud-image in the lower right corner

RegisterListener("Hook_SelectObject",function (o)
	if (gHudTargetInfo) then gHudTargetInfo:Destroy() gHudTargetInfo = nil end
	gHudTargetInfo = o and GetHUDBaseWidget():CreateChild("HudTargetInfo",{obj=o})
end)
RegisterIntervalStepper(500,function () if (gHudTargetInfo) then gHudTargetInfo:IntervalStep() end end)



cHudTargetInfo		= RegisterWidgetClass("HudTargetInfo","Group")

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

	local b,boff = 2,30
	self.txt_topleft = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})
	self.txt_topleft:SetPos(b,b)
	self.txt_bottomleft = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})
	self.txt_bottomleft:SetPos(b,h-b-boff)
	
	self:UpdateTexts()
end

function cHudTargetInfo:UpdateTexts ()
	local o = self.obj
	local txt1 = o:GetClass()
	if (o.name) then txt1 = txt1 .. "\n" .. o.name end
	if (o.r > 0) then txt1 = txt1 .. "\nradius: " .. GetDistText(o.r) end
	if (o.orbit_master and o.orbit_master.name) then 
		txt1 = txt1 .. "\nin orbit around " .. o.orbit_master.name 
		if (o.orbit_master:GetClass() == "Planet") then 
			txt1 = txt1 .. "\norbit height: " .. GetDistText(o:GetDistToObject(o.orbit_master) - o.orbit_master.r)
		else
			txt1 = txt1 .. "\norbit: " .. GetDistText(o:GetDistToObject(o.orbit_master))
		end
	end
	
	local txt2 = GetDistText(o:GetDistToPlayer())
	
	self.txt_topleft:SetText(txt1)
	self.txt_bottomleft:SetText(txt2)
end

function cHudTargetInfo:IntervalStep () self:UpdateTexts() end
