
function MySpaceInit ()
	local gNumberOfStars = 10000 
	local gStarsDist = 50000 
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


gObjects = {}

function FireShot () 
	--~ print("FireShot")
	local cam = GetMainCam()
	local w0,x0,y0,z0 = cam:GetRot()
	
	local x,y,z = gMyShipTest:GetPos()
	local s = 100
	local vx,vy,vz = Quaternion.ApplyToVector(0,0,-s,w0,x0,y0,z0)
	local o = gMyShipTest
	vx,vy,vz = vx+o.vx,vy+o.vy,vz+o.vz
	local gfx = CreateRootGfx3D()
	gfx:SetMesh(gBoltMeshName)
	gfx:SetOrientation(w0,x0,y0,z0)
	local o = {x=x,y=y,z=z,vx=vx,vy=vy,vz=vz,gfx=gfx}
	gObjects[o] = true
end

RegisterStepper(function () 
	local dt = gSecondsSinceLastFrame
	for o,v in pairs(gObjects) do 
		o.x = o.x + o.vx * dt
		o.y = o.y + o.vy * dt
		o.z = o.z + o.vz * dt
		o.gfx:SetPosition(o.x,o.y,o.z)
	end
end)
       

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
	if (not gMyShipTest) then 
		EnsureMeshMaterialNamePrefix("llama.mesh","llama")
		EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
		EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
		--~ os.exit(0)
	
		gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
		
		-- player ship
		gMyShipTest = cShip:New(0,0,0	,5,"llama.mesh")
		
		-- alien ship
		cNPCShip:New(10,0,0		,50,"ruizong.mesh") 
		
		-- bases
		cStation:New(-1000,0,0	,100,"agricultural_station.mesh")
		cPlanet:New(40000,0,0	,16000,"planetbase")
	end
	--~ local ang = math.pi * gMyTicks/1000 * 0.05
	--~ gMyShipTest.gfx:SetOrientation(Quaternion.fromAngleAxis(ang,0,1,0))
	
	
	
    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
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
		local w1,x1,y1,z1 = gMyShipTest.gfx:GetOrientation()
		local bShortestPath = true 
		local t = 0.9
		gMyShipTest.gfx:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t))
	end
	
	
	local w0,x0,y0,z0 = gMyShipTest.gfx:GetOrientation()
	
	local x,y,z = gMyShipTest:GetPos()
	local s = 100
	local as = 10*s
	local ax,ay,az = Quaternion.ApplyToVector(
		(gKeyPressed[key_d] and -s or 0) + (gKeyPressed[key_a] and  s or 0),
		(gKeyPressed[key_f] and -s or 0) + (gKeyPressed[key_r] and  s or 0),
		(gKeyPressed[key_s] and -s or 0) + (gKeyPressed[key_w] and  s or 0)  + (gKeyPressed[key_lshift] and as or 0) ,
		w0,x0,y0,z0) x,y,z = x+ax*dt,y+ay*dt,z+az*dt
	local o = gMyShipTest
	o.vx,o.vy,o.vz = ax,ay,az
	gMyShipTest:SetPos(x,y,z)
	
	local ax,ay,az = Quaternion.ApplyToVector(0,4,-5,w0,x0,y0,z0)
	local ox,oy,oz = x+ax,y+ay,z+az
	
	--~ local ox,oy,oz = 0,0,0
	local dist = 15
	StepThirdPersonCam (cam,dist,ox,oy,oz)
end

