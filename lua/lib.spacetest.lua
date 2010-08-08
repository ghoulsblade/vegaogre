
function MySpaceInit ()
	local gNumberOfStars = 10000 
	local gStarsDist = 80000 
	local gStarColorFactor = 0.5 -- somewhat colorful stars
	gStarField = CreateRootGfx3D()
	gStarField:SetStarfield(gNumberOfStars,gStarsDist,gStarColorFactor,"starbase")
	
    Client_SetSkybox("bluesky")
	
    local cam = GetMainCam()
    cam:SetFOVy(gfDeg2Rad*45)
    --~ cam:SetNearClipDistance(0.01) -- old : 1
    --~ cam:SetFarClipDistance(2000) -- ogre defaul : 100000
	
	-- light 
    Client_ClearLights()
	local x,y,z = .1,-.7,-.9			gDirectionalLightSun = Client_AddDirectionalLight(x,y,z)
	local e = .9	local r,g,b = e,e,e		Client_SetLightDiffuseColor(gDirectionalLightSun,r,g,b)
	local e = .0	local r,g,b = e,e,e		Client_SetLightSpecularColor(gDirectionalLightSun,r,g,b)
	local e = .2	local r,g,b = e,e,e		Client_SetAmbientLight(r,g,b, 1)

	gMaxFPS = 40
end


RegisterIntervalStepper(100,function ()
	if (gGuiTest_DragDrop_Active) then return end
	if (gKeyPressed[key_mouse_left]) then FireShot() end
end)

function FireShot () if (gPlayerShip) then cShot:New(gPlayerShip) end end

function EnsureMaterialNamePrefix (matname,prefix)
	if (string.find(matname,prefix,nil,true) ~= 1) then return prefix.."_"..matname end
	return matname
end

-- see also    data/convertmaterial.lua   for adjusting the .material files
-- prefix material names at runtime
function EnsureMeshMaterialNamePrefix (meshname,prefix)
	local mesh = MeshManager_load(meshname) assert(mesh)
	--~ print("EnsureMeshMaterialNamePrefix",meshname,mesh:getNumSubMeshes())
	for i=0,mesh:getNumSubMeshes()-1 do 
		local sub = mesh:getSubMesh(i) assert(sub)
		local mat = sub:getMaterialName()
		local mat2 = EnsureMaterialNamePrefix(mat,prefix)
		sub:setMaterialName(mat2)
		--~ print("sub",i,mat2)
	end
end

function ShipTestStep ()
	if (not gPlayerShip) then 
		EnsureMeshMaterialNamePrefix("llama.mesh","llama")
		EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
		EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
		--~ os.exit(0)
	
		gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
		
		-- player ship
		gPlayerShip = cPlayerShip:New(0,0,0	,5,"llama.mesh")
		
		-- npc ship
		for i=1,10 do 
			local x,y,z = Vector.random3(400)
			local o = cNPCShip:New(x,y,z		,10,"ruizong.mesh") 
			o:SetRandomRot()
		end
		
		-- bases
		cStation:New(-1000,0,0	,400,"agricultural_station.mesh")
		cPlanet:New(60000,0,0	,40000,"planetbase"):SetRandomRot()
	end
	

    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
end




function PlayerCamStep (dx,dy)
	local cam = GetMainCam()
	
	local roth = -math.pi * .5 * dx * gSecondsSinceLastFrame
	local rotv = -math.pi * .5 * dy * gSecondsSinceLastFrame
	
	local w0,x0,y0,z0 = cam:GetRot()	
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(roth,0,1,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)	
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)	
	--~ local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)
	cam:SetRot(Quaternion.normalise(w0,x0,y0,z0))
	
	if (not gPlayerShip) then return end
	
	
	
	local ang = math.pi * gMyTicks/1000 * 0.11
	
	local cam = GetMainCam()
	local dt = gSecondsSinceLastFrame
	--~ GetMainCam():SetOrientation(Quaternion.fromAngleAxis(ang,0,1,0))
	--~ local bMoveCam = gKeyPressed[key_mouse_middle]
	--~ local speedfactor = math.pi / 1000 -- 1000pix = pi radians
	--~ local bFlipUpAxis = false
	--~ StepTableCam(cam,bMoveCam,speedfactor,bFlipUpAxis)
	
	local ang = math.pi*dt*.5
	local w0,x0,y0,z0 = cam:GetRot()
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(
			(gKeyPressed[key_e] and -ang or 0) + (gKeyPressed[key_q] and  ang or 0),
		0,0,1)
	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w2,x2,y2,z2)
	cam:SetRot(w0,x0,y0,z0)
	
	if (1 == 1) then 
		local cam = GetMainCam()
		local w0,x0,y0,z0 = cam:GetRot()
		local w2,x2,y2,z2 = Quaternion.fromAngleAxis(math.pi,0,1,0)
		w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w2,x2,y2,z2)	
		local w1,x1,y1,z1 = gPlayerShip.gfx:GetOrientation()
		local bShortestPath = true 
		local t = 0.9
		gPlayerShip.gfx:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t))
	end
	
	
	local w0,x0,y0,z0 = gPlayerShip.gfx:GetOrientation()
	
	local s = gKeyPressed[key_lshift] and 10 or 100
	local as = 10*s
	local ax,ay,az = Quaternion.ApplyToVector(
		(gKeyPressed[key_d] and -s or 0) + (gKeyPressed[key_a] and  s or 0),
		(gKeyPressed[key_f] and -s or 0) + (gKeyPressed[key_r] and  s or 0),
		(gKeyPressed[key_s] and -s or 0) + (gKeyPressed[key_w] and  s or 0)  + (gKeyPressed[key_lcontrol] and as or 0) ,
		w0,x0,y0,z0)
		
	local o = gPlayerShip
	o.vx,o.vy,o.vz = ax,ay,az
	local x,y,z = gPlayerShip:GetPos()
	local ax,ay,az = Quaternion.ApplyToVector(0,4,-5,w0,x0,y0,z0)
	local ox,oy,oz = x+ax,y+ay,z+az
	
	--~ local ox,oy,oz = 0,0,0
	local dist = 15
	StepThirdPersonCam (cam,dist,ox,oy,oz)
end
