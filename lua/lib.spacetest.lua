
function MySpaceInit ()
	local gNumberOfStars = 10000 
	local gStarsDist = 9000 
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
	
	local x,y,z = 0,0,0
	local s = 100
	local vx,vy,vz = Quaternion.ApplyToVector(0,0,-s,w0,x0,y0,z0)
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
	print("EnsureMeshMaterialNamePrefix",meshname,mesh:getNumSubMeshes())
	for i=0,mesh:getNumSubMeshes()-1 do 
		local sub = mesh:getSubMesh(i) assert(sub)
		local mat = sub:getMaterialName()
		local mat2 = EnsureMaterialNamePrefix(mat,prefix)
		sub:setMaterialName(mat2)
		print("sub",i,mat2)
	end
end

function ShipTestStep ()
	if (not gMyShipTest) then 
		EnsureMeshMaterialNamePrefix("llama.mesh","llama")
		EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
		EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
		--~ os.exit(0)
	
		local gfx = CreateRootGfx3D()
		
		gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
		
		gfx:SetMesh("llama.mesh")
		--~ gfx:SetMesh(gBoltMeshName)
		gMyShipTest = gfx
		gMyShipTest:SetNormaliseNormals(true)
		
		local gfx = CreateRootGfx3D()
		gfx:SetMesh("ruizong.mesh")
		gfx:SetPosition(10,0,0)
		local s = 0.05
		gfx:SetScale(s,s,s)
		
		local gfx = CreateRootGfx3D()
		gfx:SetMesh("agricultural_station.mesh")
		gfx:SetPosition(-10,0,0)
		local s = 0.05
		gfx:SetScale(s,s,s)
	end
	--~ local ang = math.pi * gMyTicks/1000 * 0.05
	--~ gMyShipTest:SetOrientation(Quaternion.fromAngleAxis(ang,0,1,0))
	
	if (1 == 2) then 
		local cam = GetMainCam()
		local w0,x0,y0,z0 = cam:GetRot()
		local w2,x2,y2,z2 = Quaternion.fromAngleAxis(math.pi,0,1,0)
		w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w2,x2,y2,z2)	
		local w1,x1,y1,z1 = gMyShipTest:GetOrientation()
		local bShortestPath = true 
		local t = 0.9
		gMyShipTest:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t))
	end
	
	
    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
	local ang = math.pi * gMyTicks/1000 * 0.11
	
	local cam = GetMainCam()
	--~ GetMainCam():SetOrientation(Quaternion.fromAngleAxis(ang,0,1,0))
	--~ local bMoveCam = gKeyPressed[key_mouse_middle]
	--~ local speedfactor = math.pi / 1000 -- 1000pix = pi radians
	--~ local bFlipUpAxis = false
	--~ StepTableCam(cam,bMoveCam,speedfactor,bFlipUpAxis)
	
	local w0,x0,y0,z0 = gMyShipTest:GetOrientation()
	local ox,oy,oz = Quaternion.ApplyToVector(0,4,-10,w0,x0,y0,z0)
	
	--~ local ox,oy,oz = 0,0,0
	local dist = 15
	StepThirdPersonCam (cam,dist,ox,oy,oz)
end

