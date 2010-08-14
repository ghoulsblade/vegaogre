sin = math.sin
cos = math.cos


function MySpaceInit ()
	
    Client_SetSkybox("bluesky")
	
    local cam = GetMainCam()
    cam:SetFOVy(gfDeg2Rad*45)
    --~ cam:SetNearClipDistance(0.01) -- old : 1
	local farclip = 100*1000*km
    cam:SetNearClipDistance(10) -- old : 1
    cam:SetFarClipDistance(farclip) -- ogre defaul : 100000
	
	
	local gNumberOfStars = 10000 
	local gStarsDist = farclip*0.9 -- 80000 
	local gStarColorFactor = 0.5 -- somewhat colorful stars
	gStarField = CreateRootGfx3D()
	gStarField:SetStarfield(gNumberOfStars,gStarsDist,gStarColorFactor,"starbase")
	
	
	-- UpdateWorldLight() called depending on sun
	
	gMaxFPS = 40
end

function UpdateWorldLight (x,y,z)
	-- light 
	Client_ClearLights()
	--~ local x,y,z = .1,-.7,-.9				
	local x,y,z = Vector.normalise(x,y,z)	
	gDirectionalLightSun = Client_AddDirectionalLight(x,y,z)
	local e = .9	local r,g,b = e,e,e		Client_SetLightDiffuseColor(gDirectionalLightSun,r,g,b)
	local e = .9	local r,g,b = e,e,e		Client_SetLightSpecularColor(gDirectionalLightSun,r,g,b)
	local e = .1	local r,g,b = e,e,e		Client_SetAmbientLight(r,g,b, 1)
end



RegisterIntervalStepper(100,function ()
	if (gGuiMouseModeActive) then return end
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

function GetGfxHierarchyText (gfx) return GetNodeHierarchyText(gfx:GetSceneNode()) end
function GetNodeHierarchyText (node) 
	if (not node) then return "." end
	local x,y,z = node:getPosition()
	local ax,ay,az = node:_getDerivedPosition()
	return string.gsub(tostring(node:getRealAddress()),"userdata: ","").."("..x..","..y..","..z..")("..ax..","..ay..","..az.."):"..GetNodeHierarchyText(node:getParentSceneNode())
end

gWorldOriginX = 0
gWorldOriginY = 0
gWorldOriginZ = 0
function MyMoveWorldOriginAgainstLocation (loc)
	local x,y,z = loc.x,loc.y,loc.z
	--~ print("######################################")
	--~ print("### MyMoveWorldOriginAgainstLocation ###",x,y,z)
	--~ print("######################################")
	gWorldOrigin:SetPos(-x,-y,-z)
	gWorldOriginX = x
	gWorldOriginY = y
	gWorldOriginZ = z
	UpdateWorldLight(gWorldOriginX,gWorldOriginY,gWorldOriginZ)
end

-- earth: real:8light hours, vega:1:10: 48 light-minutes = 864.000.000.000 meters.  also: 
light_second = 300*1000*1000 -- 300 mio m/s
light_minute = 60*light_second -- 18.000.000.000 in meters
local vega_factor = 1/10 -- ... useme ? 
au = 150*1000*1000* 1000 * vega_factor    -- (roughly 1 earth-sun distance)
km = 1000

function ShipTestStep ()
	if (not gPlayerShip) then 
		EnsureMeshMaterialNamePrefix("llama.mesh","llama")
		EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
		EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
		--~ os.exit(0)
		
		gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
		
		-- prepare solarsystem : 
		
		local solroot = cLocation:New(nil,0,0,0,0)
		gWorldOrigin = solroot	
		
		-- planets
		local planets = {
			{ "sun"			,0 			,6955*10e5*km	},
			{ "mercury"		,0.4*au 	,2439.7*km		},
			{ "venus"		,0.7*au 	,6051.8*km		},
			{ "earth"		,1.0*au 	,6371.0*km		,bStartHere=true}, -- see also http://en.wikipedia.org/wiki/Earth
			{ "mars"		,1.5*au 	,3396.2*km	},
			-- asteroidbelt:2.3-3.3au   
			-- Asteroids range in size from hundreds of kilometres across to microscopic
			-- The asteroid belt contains tens of thousands, possibly millions, of objects over one kilometre in diameter.
			-- [46] Despite this, the total mass of the main belt is unlikely to be more than a thousandth of that of the Earth.
			-- [47] The main belt is very sparsely populated
			-- outerplanets: 
			{ "jupiter"		,5.2*au		,71492*km			},
			{ "saturn"		,9.5*au     ,60268*km			},
			{ "uranus"		,19.6*au    ,25559*km			},
			{ "neptune"		,30*au      ,24764*km			},
			-- kuiper belt: 30au-50au   pluto:39au   haumea:43.34au  makemake:45.79au
		}	
		function GetRandomOrbitFlatXY (d,dzmax)
			local ang = math.random()*math.pi*2
			local x,y = d*sin(ang),d*cos(ang)
			local z = (math.random()*2-1)*dzmax
			return x,y,z
		end
		
		gPlanetsLocs = {}
		for k,o in pairs(planets) do 
			local name,d,pr = unpack(o)
			local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
			--~ local x,y,z = d,0,0
			local r = 0
			local ploc = cLocation:New(solroot,x,y,z,r)
			table.insert(gPlanetsLocs,ploc)
			ploc.name = name
			
			local planet = cPlanet:New(ploc,0,0,0	,pr,"planetbase")
			ploc.planet = planet
			planet:SetRandomRot()
			planet.name = name
			
			-- player ship
			if (o.bStartHere and (not gPlayerShip)) then 
				local d = - pr * 1.2,0,0
				local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
				-- player ship
				gPlayerShip = cPlayerShip:New(ploc,x,y,z	,5,"llama.mesh")
				--~ MyMoveWorldOriginAgainstLocation(ploc) -- already causes rounding errors even near planet earth for real planet sizes
				MyMoveWorldOriginAgainstPlayerShip()
				
				-- npc ship
				for i=1,10 do 
					local ax,ay,az = Vector.random3(400)
					local o = cNPCShip:New(ploc,x+ax,y+ay,z+az,10,"ruizong.mesh") 
					o:SetRandomRot()
				end
			end
			
			-- stations
			for i = 0,math.random(0,2) do 
				local d = pr * (1.2 + 0.3 * math.random())
				local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
				local s = cStation:New(ploc,x,y,z	,400,"agricultural_station.mesh")
			end
		end
	end
	

    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
end


gDebugJumpPlanetID = 0
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
function MyMoveWorldOriginAgainstPlayerShip ()
	local loc = gPlayerShip.loc
	local x,y,z = gPlayerShip.x+loc.x,gPlayerShip.y+loc.y,gPlayerShip.z+loc.z
	local newloc = cLocation:New(gWorldOrigin,x,y,z,r)
	--~ print("recenter on new loc",x,y,z) 
	MyMoveWorldOriginAgainstLocation(newloc)
	gPlayerShip:MoveToNewLoc(newloc)
	gPlayerShip:SetPos(0,0,0)
end
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
	local cam = GetMainCam()
	local w0,x0,y0,z0 = cam:GetRot()
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(math.pi,0,1,0)
	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w2,x2,y2,z2)	
	local w1,x1,y1,z1 = gPlayerShip.gfx:GetOrientation()
	local bShortestPath = true 
	local t = 0.9
	gPlayerShip.gfx:SetOrientation(Quaternion.Slerp	(w1,x1,y1,z1, w0,x0,y0,z0, t))
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
	local ax,ay,az = Quaternion.ApplyToVector(0,4,-5,w0,x0,y0,z0)
	local ox,oy,oz = x+ax,y+ay,z+az
	
	local dist = 15
	local cam = GetMainCam()
	StepThirdPersonCam(cam,dist,ox,oy,oz)
end
