-- hud-image in the lower right corner

	
function HUD_UpdateDisplayNav ()
	if (gHudDisplayNav) then gHudDisplayNav:Destroy() gHudDisplayNav = nil end
	gHudDisplayNav = GetHUDBaseWidget():CreateChild("HudDisplayNav")
end
RegisterListener("Hook_SystemLoaded",function (bGameInit) HUD_UpdateDisplayNav() end)
RegisterIntervalStepper(500,function () if (gHudDisplayNav) then gHudDisplayNav:IntervalStep() end end)
RegisterListener("Hook_MainWindowResized",function () HUD_UpdateDisplayNav() end)



cHudDisplayNav	= RegisterWidgetClass("HudDisplayNav","Group")

function cHudDisplayNav:Init (parentwidget, params)
	local w,h = 256,256
	local x,y = gViewportW/2,gViewportH-h
	self:SetPos(x,y)
	
	local b,loff,boff,roff = 2,5,30,64
	local t = self:_CreateChild("Text",{text="???",textparam={r=1,g=1,b=1}})	self.txt_speed = t		t:SetPos(b+loff,b+128)
	local t = self:_CreateChild("Text",{text="???",textparam={r=1,g=1,b=1}})	self.txt_dockdist = t		t:SetPos(b+loff,b+128+20)
	
	self:UpdateTexts()
end

function cHudDisplayNav:UpdateTexts ()
	self.txt_speed:SetText("Speed:"..tostring(GetDistText(PlayerHyperFly_GetSpeed()))..",Exponent:"..tostring(PlayerHyperFly_GetExponent()))
	local d = gSelectedObject and Player_GetDistUntilDock(gSelectedObject)
	self.txt_dockdist:SetText(d and ("docking: "..GetDistText(d)) or "")
end

function cHudDisplayNav:IntervalStep () self:UpdateTexts() end
