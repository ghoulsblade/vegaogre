
function MySpaceInit ()
	EnsureMeshMaterialNamePrefix("llama.mesh","llama")
	EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
	EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
	
	gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
	
	
	-- skybox
    Client_SetSkybox("bluesky")
	
    local cam = GetMainCam()
    cam:SetFOVy(gfDeg2Rad*45)
    --~ cam:SetNearClipDistance(0.01) -- old : 1
	local farclip = 1000*1000*km
    cam:SetNearClipDistance(10) -- old : 1
    cam:SetFarClipDistance(farclip) -- ogre defaul : 100000
	
	
	local gNumberOfStars = 10000 
	local gStarsDist = farclip*0.9 -- 80000 
	local gStarColorFactor = 0.5 -- somewhat colorful stars
	gStarField = CreateRootGfx3D()
	gStarField:SetStarfield(gNumberOfStars,gStarsDist,gStarColorFactor,"starbase")
	
	-- UpdateWorldLight() called depending on sun
	
	
	gMLocBaseGfx = CreateRootGfx3D()
	
	-- spawn solarsystem
	VegaLoadSystem("Crucible/Cephid_17")
	--~ VegaLoadExampleSystem()
	local playerspawnbase
	for k,v in ipairs(gNavTargets) do if (v.name == "Atlantis") then playerspawnbase = v break end end
	playerspawnbase = playerspawnbase or gNavTargets[math.random((#gNavTargets > 0) and #gNavTargets or 1)]
	SpawnPlayer(playerspawnbase)
	
	HUD_UpdateDisplaySelf()
end

function GetRandomOrbitFlatXY (d,dzmax)
	local ang = math.random()*math.pi*2
	local x,y = d*sin(ang),d*cos(ang)
	local z = (math.random()*2-1)*dzmax
	return x,y,z
end

function SpawnPlayer (base)
	if (gPlayerShip) then return end
	local pr = base.r
	local loc = base.loc or gSolRoot
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

function VegaSpawnMajorLoc (parentloc,x,y,z,debugname)
	local loc = cLocation:New(parentloc,x,y,z,0,"majorloc:"..(debugname or "?"))
	RegisterMajorLoc(loc)
	return loc
end
function VegaSpawnSystemRootLoc (debugname)
	local solroot = cLocation:New(nil,0,0,0,0,"system-root-loc")
	gSolRootGfx = solroot.gfx
	gSolRoot = solroot
	return solroot
end

function VegaLoadExampleSystem ()
	local solroot = VegaSpawnSystemRootLoc("sol-root-loc")
	
	-- planets
	local planets = {
		{ "sun"			,0 			,6955*10e5*km	,0},
		{ "mercury"		,0.4*au 	,2439.7*km		},
		{ "venus"		,0.7*au 	,6051.8*km		},
		{ "earth"		,1.0*au 	,6371.0*km		,bStartHere=true}, -- see also http://en.wikipedia.org/wiki/Earth
		{ "mars"		,1.5*au 	,3396.2*km		},
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
	
	
	for k,o in pairs(planets) do 
		local name,d,pr,maxstations = unpack(o)
		maxstations = maxstations or 2
		local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
		--~ local x,y,z = d,0,0
		local r = 0
		local ploc = cLocation:New(solroot,x,y,z,r,"planet-loc "..name)
		RegisterMajorLoc(ploc)
		ploc.name = name
		
		local planet = cPlanet:New(ploc,0,0,0	,pr,"planetbase")
		ploc.planet = planet
		planet:SetRandomRot()
		planet.name = name
		RegisterNavTarget(planet)
		
		-- stations
		for i = 1,math.random(0,maxstations) do 
			local d = pr * (1.2 + 0.3 * math.random())
			local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
			local sloc = cLocation:New(ploc,x,y,z,0,"station-loc under "..planet.name)
			RegisterMajorLoc(sloc)
			local s = cStation:New(sloc,0,0,0	,400,"agricultural_station.mesh")
			s.orbit_master = planet
			RegisterNavTarget(s)
		end
		
		-- player ship
		if (o.bStartHere and (not gPlayerShip)) then SpawnPlayer(planet) end
	end
end

function UpdateWorldLight (x,y,z)
	-- light 
	Client_ClearLights()
	--~ local x,y,z = .1,-.7,-.9				
	local x,y,z = Vector.normalise(x,y,z)	
	gDirectionalLightSun = Client_AddDirectionalLight(x,y,z)
	local e = .9	local r,g,b = e,e,e		Client_SetLightDiffuseColor(gDirectionalLightSun,r,g,b)
	local e = .5	local r,g,b = e,e,e		Client_SetLightSpecularColor(gDirectionalLightSun,r,g,b)
	local e = .1	local r,g,b = e,e,e		Client_SetAmbientLight(r,g,b, 1)
end

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






-- ***** ***** ***** ***** ***** world origin (against rounding errors)

gMajorLocs = {}
function RegisterMajorLoc (loc) gMajorLocs[loc] = true end
function FindNearestMajorLoc (o) 
	local mind,minloc
	for loc,v in pairs(gMajorLocs) do 
		local d = o:GetDistToObject(loc)
		if ((not minloc) or d < mind) then mind,minloc = d,loc end
	end
	return minloc
end

function GetPlayerMoveLoc ()
	local moveloc = gPlayerShip.moveloc 
	if (moveloc) then return moveloc end
	print("GetPlayerMoveLoc:create new")
	local o = gPlayerShip
	moveloc = cLocation:New(o.loc,o.x,o.y,o.z,0)
	o.moveloc = moveloc
	o:MoveToNewLoc(moveloc)
	o:SetPos(0,0,0)
	return moveloc,true
end

function RecenterPlayerMoveLoc ()
	local moveloc = GetPlayerMoveLoc()
	local mloc = FindNearestMajorLoc(gPlayerShip) -- gCurrentMajorLoc must be considered, otherwise we'd constantly jitter between the nearest two
	
	-- recenter player in move loc
	local o = gPlayerShip
	--~ print("RecenterPlayerMoveLoc:",o.x,o.y,o.z)
	moveloc:SetPos(	moveloc.x + o.x,
					moveloc.y + o.y,
					moveloc.z + o.z)
	o:SetPos(0,0,0)
	
	-- change to new major loc if needed
	local old = gCurrentMajorLoc
	if (old ~= mloc) then
		print("change major loc to "..(mloc.locname or "???"))
		if (old) then -- re-integrate
			old.gfx:SetPosition(old.x,old.y,old.z)
			old.gfx:SetParent(old.loc.gfx)
		end
		gCurrentMajorLoc = mloc
		mloc.gfx:SetPosition(0,0,0)
		mloc.gfx:SetParent(gMLocBaseGfx)
		
		-- move ship to mloc
		local x,y,z = mloc:GetVectorToObject(moveloc)
		moveloc:MoveToNewLoc(mloc)
		moveloc:SetPos(x,y,z)
	end
		
	-- move world origin so that moveloc is at global zero/origin
	-- gSolRootGfx > solroot > all normal locations (hopefully far away from player)
	-- gMLocBaseGfx > mloc = player-move-loc
	local x,y,z = moveloc:GetVectorToObject(mloc)
	gMLocBaseGfx:SetPosition(x,y,z)
	local x,y,z = moveloc:GetVectorToObject(gSolRoot)
	gSolRootGfx:SetPosition(x,y,z)
	
	UpdateWorldLight(-x,-y,-z)
	
	-- problem : hyper-moving to station at absolute pos results in jitter (small movement vs big relative hyper-coords )
	-- solution : target(or nearest major location) is 0  # , so movement gets closer to 0 and more exact the closer it gets -> no jitter
	-- needed : re-attach major loc to world origin to avoid jitter there ? (maybe not needed)
	-- needed : constantly recenter world so that player is at absolute 0  #  (conflict with other #)   to avoid relative move-jitter (>100km)
end

function MyMoveWorldOriginAgainstPlayerShip ()
	RecenterPlayerMoveLoc()
end

function MyPlayerHyperMoveRel (dx,dy,dz)
	gPlayerShip.vx = 0
	gPlayerShip.vy = 0
	gPlayerShip.vz = 0
	local moveloc = GetPlayerMoveLoc() 
	--~ print("MyPlayerHyperMoveRel: moveloc abs.pos.len",sprintf("%0.0f",Vector.len(moveloc.x,moveloc.y,moveloc.z)))
	moveloc:SetPos(	moveloc.x + dx,
					moveloc.y + dy,
					moveloc.z + dz )
	RecenterPlayerMoveLoc()
end

-- big problem : PlayerCam_Pos_Step () .. gPlayerShip:GetPos()   ..  relative to world origin ? 
