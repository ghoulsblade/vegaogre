
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

function ShipTestStep ()
	if (not gMyShipTest) then 
		local gfx = CreateRootGfx3D()
		gfx:SetMesh("llama.mesh")
		gMyShipTest = gfx
		gMyShipTest:SetNormaliseNormals(true)
	end
	local ang = math.pi * gMyTicks/1000 * 0.05
	gMyShipTest:SetOrientation(Quaternion.fromAngleAxis(ang,0,1,0))
	
	
    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
	local ang = math.pi * gMyTicks/1000 * 0.11
	
	--~ GetMainCam():SetOrientation(Quaternion.fromAngleAxis(ang,0,1,0))
	--~ local bMoveCam = gKeyPressed[key_mouse_middle]
	--~ local speedfactor = math.pi / 1000 -- 1000pix = pi radians
	--~ local bFlipUpAxis = false
	--~ local cam = GetMainCam()
	--~ StepTableCam(cam,bMoveCam,speedfactor,bFlipUpAxis)
	--~ local ox,oy,oz = 0,3,0
	--~ local dist = 15
	--~ StepThirdPersonCam (cam,dist,ox,oy,oz)
end

