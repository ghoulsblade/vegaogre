
BindDown("A",function () ToggleAutoPilot() end)

function AutoPilotMsg (...) print("AutoPilot:",...) end

function ToggleAutoPilot ()
	if (not gSelectedObject) then AutoPilotMsg("select a target first") return end
	gAutoPilotActive = not gAutoPilotActive
	HUD_UpdateDisplaySelf()
	if (not gAutoPilotActive) then AutoPilotMsg("deactivated") return end
	gAutoPilotTarget = gSelectedObject
	AutoPilotMsg("activated, target="..tostring(gAutoPilotTarget:GetNameForMessageText()))
end
