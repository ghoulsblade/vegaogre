

function AutoPilotMsg (...) print("AutoPilot:",...) end

function ToggleAutoPilot ()
	if (not gSelectedObject) then AutoPilotMsg("select a target first") return end
	gAutoPilotActive = not gAutoPilotActive
	HUD_UpdateDisplaySelf()
	if (not gAutoPilotActive) then AutoPilotMsg("deactivated") return end
	gAutoPilotTarget = gSelectedObject
	AutoPilotMsg("activated, target="..tostring(gAutoPilotTarget:GetNameForMessageText()))
end

function StepAutoPilot () 
	if (not gAutoPilotActive) then return end
	local my = gPlayerShip
	local to = gAutoPilotTarget
	local x,y,z = my:GetVectorToObject(to) 
	local d = my:GetDistToObject(to) - to.r
	
	local w0,x0,y0,z0 = Quaternion.getRotation (0,0,1, x,y,z) 
	local w1,x1,y1,z1 = my.gfx:GetOrientation()
	local t = 0.9
	my.gfx:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t))
	
	local min_d_hyper = 10*km
	local min_d_auto = 1*km
	local f = 0.5*gSecondsSinceLastFrame
	if (d > min_d_hyper) then 
		MyPlayerHyperMoveRel(x*f,y*f,z*f)
	elseif (d < min_d_auto) then 
		my.vx = 0
		my.vy = 0
		my.vz = 0
		AutoPilotMsg("arrived")
		ToggleAutoPilot()
	else
		local f = 0.5
		my.vx = x * 0.5
		my.vy = y * 0.5
		my.vz = z * 0.5
	end
end
