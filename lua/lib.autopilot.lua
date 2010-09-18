

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
	local d = my:GetDistToObject(to)
	local f = 1 - to.r / d
	d = d * f
	x = x * f
	y = y * f
	z = z * f
	
	--[[
	local w0,x0,y0,z0 = Quaternion.getRotation (0,0,1, x,y,z) 
	local w1,x1,y1,z1 = my.gfx:GetOrientation()
	local bShortestPath = true 
	local t = 0.9
	my.gfx:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t, bShortestPath))
	]]--
	
	-- autopilot rorates cam
	if (1 == 1) then 
		local cam = GetMainCam()
		local w1,x1,y1,z1 = cam:GetRot()
		local fx,fy,fz = Quaternion.ApplyToVector (0,0,-1,w1,x1,y1,z1) 
		local w0,x0,y0,z0 = Quaternion.getRotation (fx,fy,fz, x,y,z) 
		w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)
	
		local bShortestPath = true 
		local t = 0.9
		w1,x1,y1,z1 = Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t, bShortestPath)
		cam:SetRot(Quaternion.normalise(w1,x1,y1,z1))
		Player_RotateShipToCam_Step()
	end
	
	local min_d_hyper = 10*km
	local min_d_auto = 1*km
	local per_second = 0.9999999999999999
	
	if (d > min_d_hyper) then 
		local f = per_second*gSecondsSinceLastFrame
		MyPlayerHyperMoveRel(x*f,y*f,z*f)
	elseif (d < min_d_auto) then 
		my.vx = 0
		my.vy = 0
		my.vz = 0
		AutoPilotMsg("arrived")
		ToggleAutoPilot()
	else
		my.vx = x * per_second
		my.vy = y * per_second
		my.vz = z * per_second
	end
end
