
RegisterIntervalStepper(100,function ()
	if (gGuiMouseModeActive) then return end
	if (gKeyPressed[key_mouse_left]) then FireShot() end
end)

function FireShot () if (gPlayerShip) then cShot:New(gPlayerShip) end end


BindDown("tab", function () ToggleGuiMouseMode() end)
BindDown("a",function () if (gGuiMouseModeActive) then ToggleAutoPilot() end end)

gDebugJumpPlanetID = 0

BindDown("n",function ()
	gDebugJumpPlanetID = (gDebugJumpPlanetID + 1) % #gPlanetsLocs
	local newloc = gPlanetsLocs[gDebugJumpPlanetID+1]
	local p = newloc.planet 
	if (p and p.guiMarker) then p.guiMarker:SetSelected() end
end)

--[[
BindDown("j",function ()
	gDebugJumpPlanetID = (gDebugJumpPlanetID + 1) % #gPlanetsLocs
	local newloc = gPlanetsLocs[gDebugJumpPlanetID+1]
	print("recenter",newloc.name) 
	gPlayerShip:MoveToNewLoc(newloc)
	local r = newloc.planet and newloc.planet.r or 0
	gPlayerShip:SetPos(r*1.2,0,0)
	MyMoveWorldOriginAgainstPlayerShip()
	print("position from sun:",gPlayerShip:GetPosFromSun())
end)
]]--

BindDown("k",function ()
	MyMoveWorldOriginAgainstPlayerShip()
	print("position from sun:",gPlayerShip:GetPosFromSun())
end)






function PlayerStep ()
	PlayerCam_Rot_Step() -- depends on mouse
	PlayerCam_Roll_Step() -- depends on keys (e,q)
	
	if (not gPlayerShip) then return end
	if (gKeyPressed[key_rshift]) then return end
	
	Player_RotateShip_Step() -- depends on camera orientation
	Player_MoveShip_Step() -- depends on keys (wasd rf) and player-ship orientation
	PlayerCam_Pos_Step() -- depends on player ship position, moves cam position
end

function PlayerCam_Rot_Step ()
	if (gGuiMouseModeActive) then return end
	if (gAutoPilotActive) then return end
	local mx,my = GetMousePos()
	local cx,cy = gViewportW/2,gViewportH/2
	local dx,dy = (mx-cx)/cx,(my-cy)/cy
	
	local roth = -math.pi * .5 * dx * gSecondsSinceLastFrame
	local rotv = -math.pi * .5 * dy * gSecondsSinceLastFrame
	
	local cam = GetMainCam()
	local w0,x0,y0,z0 = cam:GetRot()	
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(roth,0,1,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)
	cam:SetRot(Quaternion.normalise(w0,x0,y0,z0))
	
	--~ local bMoveCam = gKeyPressed[key_mouse_middle]
	--~ local speedfactor = math.pi / 1000 -- 1000pix = pi radians
	--~ local bFlipUpAxis = false
	--~ StepTableCam(cam,bMoveCam,speedfactor,bFlipUpAxis)
end

function PlayerCam_Roll_Step ()
	if (gGuiMouseModeActive) then return end
	local cam = GetMainCam()
	local ang = math.pi*gSecondsSinceLastFrame*.5
	local w0,x0,y0,z0 = cam:GetRot()
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(
			(gKeyPressed[key_e] and -ang or 0) + (gKeyPressed[key_q] and  ang or 0),
		0,0,1)
	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w2,x2,y2,z2)
	cam:SetRot(w0,x0,y0,z0)
end

function Player_RotateShip_Step ()
	if (not gPlayerShip) then return end
	if (gAutoPilotActive) then return end
	Player_RotateShipToCam_Step()
end

function Player_RotateShipToCam_Step ()
	local cam = GetMainCam()
	local w0,x0,y0,z0 = cam:GetRot()
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(math.pi,0,1,0)
	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w2,x2,y2,z2)	
	local w1,x1,y1,z1 = gPlayerShip.gfx:GetOrientation()
	local bShortestPath = true 
	local t = 0.9
	gPlayerShip.gfx:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t, bShortestPath))
end

function Player_MoveShip_Step ()
	if (gGuiMouseModeActive) then return end
	if (not gPlayerShip) then return end

	local w0,x0,y0,z0 = gPlayerShip.gfx:GetOrientation()
	
	local s = gKeyPressed[key_lshift] and 100 or 1000
	local as = 10*s
	if (gKeyPressed[key_lcontrol]) then s = s * 100 as = 0 end 
	if (gKeyPressed[key_lcontrol] and gKeyPressed[key_lshift]) then s = s * 1000 as = 0 end 
	local ax,ay,az = Quaternion.ApplyToVector(
		(gKeyPressed[key_d] and -s or 0) + (gKeyPressed[key_a] and  s or 0),
		(gKeyPressed[key_f] and -s or 0) + (gKeyPressed[key_r] and  s or 0),
		(gKeyPressed[key_s] and -s or 0) + (gKeyPressed[key_w] and  s or 0)  + (gKeyPressed[key_lcontrol] and as or 0) ,
		w0,x0,y0,z0)
	
	local o = gPlayerShip
	o.vx,o.vy,o.vz = ax,ay,az
end

function PlayerCam_Pos_Step ()
	if (not gPlayerShip) then return end
	local w0,x0,y0,z0 = gPlayerShip.gfx:GetOrientation()
	--~ local x,y,z = gPlayerShip:GetPos()
	local x,y,z = gPlayerShip.gfx:GetDerivedPosition()
	local ax,ay,az = Quaternion.ApplyToVector(0,4,-5,w0,x0,y0,z0)
	local ox,oy,oz = x+ax,y+ay,z+az
	
	local dist = 15
	local cam = GetMainCam()
	StepThirdPersonCam(cam,dist,ox,oy,oz)
end
