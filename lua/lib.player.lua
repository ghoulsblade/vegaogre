

-- ***** ***** ***** ***** ***** hotkeys

SetMacro("tab", function () ToggleGuiMouseMode() end)
SetMacro("alt+a",function () ToggleAutoPilot() end)
SetMacro("ctrl+a",function () ToggleAutoPilot() end)
SetMacro("shift+n",function ()	Player_SelectPrevNavTarget() end)
SetMacro("n",function () 		Player_SelectNextNavTarget() end)

SetMacro("alt+d",function () Player_DockToSelected() end)
SetMacro("ctrl+d",function () Player_DockToSelected() end)

gPlayerHyperKeyList = {
	[key_npadd]	=1,
	[key_npsub]	=-1,
	["unknown_043"]	=1,
	[key_minus]	=-1,
	[key_x]		=1,
	[key_y]		=-1
}
SetMacro("backspace",function () PlayerHyperFly_Zero() end)

--~ gMacroPrintAllKeyCombos = true


-- ***** ***** ***** ***** ***** external api


function PlayerStep ()
	PlayerCam_Rot_Step() -- depends on mouse
	PlayerCam_Roll_Step() -- depends on keys (e,q)
	
	if (not gPlayerShip) then return end
	if (gKeyPressed[key_rshift]) then return end
	
	Player_RotateShip_Step() -- depends on camera orientation
	Player_MoveShip_Step() -- depends on keys (wasd rf) and player-ship orientation
	PlayerCam_Pos_Step() -- depends on player ship position, moves cam position
end


function SpawnPlayer (base)
	if (gPlayerShip) then return end
	local pr = base and base.r or 0
	local loc = base and base.loc or gSolRoot
	local d = - pr * 1.2,0,0
	local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
	-- player ship
	gPlayerShip = cPlayerShip:New(loc,x,y,z	,5,"llama.mesh")
	MyMoveWorldOriginAgainstPlayerShip()
	
	-- npc ship
	--~ local x,y,z = 0,0,0
	--~ local loc = gPlayerShip.loc
	--~ for i=1,10 do 
		--~ local ax,ay,az = Vector.random3(400)
		--~ local o = cNPCShip:New(loc,x+ax,y+ay,z+az,10,"ruizong.mesh") 
		--~ o:SetRandomRot()
	--~ end
end


-- ***** ***** ***** ***** ***** shot

RegisterIntervalStepper(100,function ()
	if (gGuiMouseModeActive) then return end
	if (gKeyPressed[key_mouse_left]) then FireShot() end
end)

function FireShot () if (gPlayerShip) then cShot:New(gPlayerShip) end end

-- ***** ***** ***** ***** ***** hyperspeed control

gHyperFlySpeed = 0
function PlayerHyperFly_Zero	() gHyperFlySpeed = 0 HUD_UpdateDisplayNav() end
function PlayerHyperFly_Faster	() gHyperFlySpeed = gHyperFlySpeed + 1 HUD_UpdateDisplayNav() end
function PlayerHyperFly_Slower	() gHyperFlySpeed = max(0,gHyperFlySpeed - 1) HUD_UpdateDisplayNav() end
function PlayerHyperFly_GetSpeed	() return (gHyperFlySpeed == 0) and 0 or (((gHyperFlySpeed > 0) and 1 or -1) * math.pow(2,math.abs(gHyperFlySpeed))) end
function PlayerHyperFly_GetExponent () return math.abs(gHyperFlySpeed) end

gPlayerHyperFlyStep_NextAccelDecelKeyStep = 0

function PlayerHyperFlyStep ()
	if (IsAutoPilotActive()) then return end

	-- while key is pressed adjust speed up/down every x msec
	if (gMyTicks >= gPlayerHyperFlyStep_NextAccelDecelKeyStep) then 
		local add = 0
		for k,v in pairs(gPlayerHyperKeyList) do if (IsHotKeyPressed(k)) then add = add + v end end
		if (add ~= 0) then
			gPlayerHyperFlyStep_NextAccelDecelKeyStep = gMyTicks + 200
			if (add < 0) then PlayerHyperFly_Slower() else PlayerHyperFly_Faster() end
		end
	end
	
	-- if hyperspeed not null, move ship
	if (gHyperFlySpeed ~= 0) then 
		local w0,x0,y0,z0 = gPlayerShip.gfx:GetOrientation()
		local s = PlayerHyperFly_GetSpeed() 
		local ax,ay,az = Quaternion.ApplyToVector(0,0,s*gSecondsSinceLastFrame,w0,x0,y0,z0)
		MyPlayerHyperMoveRel (ax,ay,az)
	end
end


-- ***** ***** ***** ***** ***** docking



function Player_GetDistUntilDock (base)
	return base and base:CanDock(gPlayerShip) and math.max(0,base:GetDistToPlayer() - (2*base.r + 1000))
end

function Player_DockToSelected ()
	PlayerHyperFly_Zero() -- stop hyperspeed flight
	if (IsDockedModeActive()) then EndDockedMode() return end
	
	local base = gSelectedObject
	if (not base) then print("Player_DockToSelected:no selected obj") return end
	if (not base:CanDock(gPlayerShip)) then print("Player_DockToSelected: dock not allowed") return end
	local d = Player_GetDistUntilDock(base)
	if (d > 0) then print("Player_DockToSelected:too far",GetDistText(d)) return end
	print("Player_DockToSelected: OK",base:GetClass(),base:DockIsJump())
	if (base:DockIsJump()) then Player_ExecuteJump(base) return end
	StartDockedMode(base)
end

-- ***** ***** ***** ***** ***** object selection

function Player_ClearSelectedObject ()
	if (not gSelectedObject) then return end
	local old = gSelectedObject
	gSelectedObject = nil
	if (old.guiMarker) then old.guiMarker:UpdateGfx() end
	NotifyListener("Hook_SelectObject")
end

-- ***** ***** ***** ***** ***** nav targets

gNavTargets = {}
function ClearNavTargets () gNavTargets = {} end
function RegisterNavTarget (o) table.insert(gNavTargets,o) end

function Player_SelectNextNavTarget () Player_SelectNavTarget_ByIdx((gNavTargetIdx or -1) + 1) end
function Player_SelectPrevNavTarget () Player_SelectNavTarget_ByIdx((gNavTargetIdx or  0) - 1) end
function Player_SelectNavTarget_ByIdx (idx)
	gNavTargetIdx = ((idx or 0) + #gNavTargets) % #gNavTargets
	--~ print("Player_SelectNavTarget_ByIdx",#gNavTargets,idx,gNavTargetIdx)
	local p = gNavTargets[gNavTargetIdx+1]
	if (p) then p:SelectObject() end
end


-- ***** ***** ***** ***** ***** cam+ship : rotate and move

function PlayerCam_Rot_Step ()
	if (gGuiMouseModeActive) then return end
	if (gAutoPilotActive) then return end
	local mx,my = GetMousePos()
	local cx,cy = gViewportW/2,gViewportH/2
	local dx,dy = (mx-cx)/cx,(my-cy)/cy
	
	local s = gSecondsSinceLastFrame * GetAutoPilotAfterMouseSlow() -- GetAutoPilotAfterMouseSlow in [0,1]
	local roth = -math.pi * .5 * dx * s
	local rotv = -math.pi * .5 * dy * s
	
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
	local x,y,z = gPlayerShip:GetPos()
	--~ local x,y,z = gPlayerShip.gfx:GetDerivedPosition()
	--~ local x,y,z = gPlayerShip.gfx:GetDerivedPosition()
	local ax,ay,az = Quaternion.ApplyToVector(0,4,-5,w0,x0,y0,z0)
	local ox,oy,oz = x+ax,y+ay,z+az
	
	local dist = 15
	local cam = GetMainCam()
	StepThirdPersonCam(cam,dist,ox,oy,oz)
end
