-- hud-image in the lower right corner

function HUD_UpdateDisplaySelf ()
	if (gHudDisplaySelf) then gHudDisplaySelf:Destroy() gHudDisplaySelf = nil end
	gHudDisplaySelf = GetDesktopWidget():CreateChild("HudDisplaySelf")
end
--~ RegisterIntervalStepper(500,function () if (gHudDisplaySelf) then gHudDisplaySelf:IntervalStep() end end)



cHudDisplaySelf	= RegisterWidgetClass("HudDisplaySelf","Group")

function cHudDisplaySelf:Init (parentwidget, params)
	local w,h = 256,256
	local x,y = 0,gViewportH-h
	self:SetPos(x,y)
	
	local o = gPlayerShip  assert(o)
	self.obj = o
	local imgname = o:GetHUDImageName() 
	
	
	local iw = w * 0.5
	self.img = self:_CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat(imgname or "dummy.png"),iw,iw)})
	self.img:SetPos(w/2-iw/2,h/2-iw/2)

	local b,loff,boff,roff = 2,5,30,64
	local t = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})	self.txt_TL = t		t:SetPos(b+loff,b)
	local t = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})	self.txt_TR = t		t:SetPos(w-b-roff,b)
	local t = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})	self.txt_BL = t		t:SetPos(b+loff,h-b-boff)
	local t = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})	self.txt_BR = t		t:SetPos(w-b-roff,h-b-boff)
	
	local t = self:_CreateChild("Text",{text="",textparam={r=1,g=1,b=1}})	self.txt_R2 = t		t:SetPos(w+b,b+20)
	
	self.txt_TR.on_mouse_left_down = function () ToggleAutoPilot() end
	
	self:UpdateTexts()
end

function cHudDisplaySelf:UpdateTexts ()
	local o = gPlayerShip
	self.txt_TL:SetText("SPEC:OFF")
	if (gAutoPilotActive) then self.txt_TR:SetCol(0,1,0) else self.txt_TR:SetCol(1,1,1) end
	self.txt_TR:SetText(gAutoPilotActive and "AUTO:ON" or "AUTO:OFF")
	self.txt_BL:SetText("CLK: N/A")
	self.txt_BR:SetText("ECM: N/A")
	self.txt_R2:SetText("Mass:100% (base)\nGCNT:MANEUVER")
end

function cHudDisplaySelf:IntervalStep () self:UpdateTexts() end
