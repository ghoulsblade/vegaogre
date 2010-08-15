
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
	
	
	gMLocZeroGfx = CreateRootGfx3D()
	
	-- prepare solarsystem : 
	
	local solroot = cLocation:New(nil,0,0,0,0)
	gSolRoot = solroot
	gWorldOrigin = solroot	
	
	-- planets
	local planets = {
		{ "earth"		,0*au 	,6371.0*km		,bStartHere=true}, -- see also http://en.wikipedia.org/wiki/Earth
		--~ { "sun"			,0 			,6955*10e5*km	},
		{ "mercury"		,0.4*au 	,2439.7*km		},
		--~ { "venus"		,0.7*au 	,6051.8*km		},
		--~ { "earth"		,1.0*au 	,6371.0*km		,bStartHere=true}, -- see also http://en.wikipedia.org/wiki/Earth
		--~ { "mars"		,1.5*au 	,3396.2*km	},
		-- asteroidbelt:2.3-3.3au   
		-- Asteroids range in size from hundreds of kilometres across to microscopic
		-- The asteroid belt contains tens of thousands, possibly millions, of objects over one kilometre in diameter.
		-- [46] Despite this, the total mass of the main belt is unlikely to be more than a thousandth of that of the Earth.
		-- [47] The main belt is very sparsely populated
		-- outerplanets: 
		--~ { "jupiter"		,5.2*au		,71492*km			},
		--~ { "saturn"		,9.5*au     ,60268*km			},
		--~ { "uranus"		,19.6*au    ,25559*km			},
		--~ { "neptune"		,30*au      ,24764*km			},
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
		RegisterMajorLoc(ploc)
		ploc.name = name
		
		local planet = cPlanet:New(ploc,0,0,0	,pr,"planetbase")
		ploc.planet = planet
		planet:SetRandomRot()
		planet.name = name
		
		-- stations
		for i = 0,math.random(0,2) do 
			local d = pr * (1.2 + 0.3 * math.random())
			local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
			local sloc = cLocation:New(ploc,x,y,z,0)
			RegisterMajorLoc(sloc)
			local s = cStation:New(sloc,0,0,0	,400,"agricultural_station.mesh")
		end
		
		-- player ship
		if (o.bStartHere and (not gPlayerShip)) then 
			local d = - pr * 1.2,0,0
			local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
			-- player ship
			gPlayerShip = cPlayerShip:New(ploc,x,y,z	,5,"llama.mesh")
			MyMoveWorldOriginAgainstPlayerShip()
			
			-- npc ship
			for i=1,10 do 
				local ax,ay,az = Vector.random3(400)
				local o = cNPCShip:New(ploc,x+ax,y+ay,z+az,10,"ruizong.mesh") 
				o:SetRandomRot()
			end
		end
	end
	
	HUD_UpdateDisplaySelf()
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


function MyMoveWorldOriginAgainstLocation (loc)
	local x,y,z = loc.x,loc.y,loc.z
	gWorldOrigin:SetPos(-x,-y,-z)
	UpdateWorldLight(x,y,z)
end

function MyMoveWorldOriginAgainstPlayerShip ()
	--[[
	local mloc = FindNearestMajorLoc(gPlayerShip) -- todo : consider gCurrentMajorLoc !
	
	local old = gCurrentMajorLoc
	if (old ~= mloc) then
		if (old) then -- re-integrate
			old.gfx:SetPosition(old.x,old.y,old.z)
			old.gfx:SetParent(old.loc.gfx)
		end
		gCurrentMajorLoc = mloc
		mloc.gfx:SetPosition(0,0,0)
		mloc.gfx:SetParent(gMLocZeroGfx)
		
		-- move ship to mloc
		local x,y,z = mloc:GetVectorToObject(gPlayerShip)
		gPlayerShip:MoveToNewLoc()
		gPlayerShip:SetPos(x,y,z)
		
		-- move world origin
		
		-- gSolRoot == gWorldOrigin
		local x,y,z = mloc:GetVectorToObject(gSolRoot)
		mloc.oldx = mloc.x
		mloc.oldy = mloc.y
		mloc.oldz = mloc.z
		mloc:SetPos()
	end
	]]--
	

	local loc = gPlayerShip.loc
	local x,y,z = gPlayerShip.x+loc.x,gPlayerShip.y+loc.y,gPlayerShip.z+loc.z
	local moveloc = gPlayerShip.moveloc
	if (not moveloc) then 
		moveloc = cLocation:New(gWorldOrigin,x,y,z,r)
		gPlayerShip.moveloc = moveloc
		gPlayerShip:MoveToNewLoc(moveloc)
	else
		moveloc:SetPos(x,y,z)
	end
	--~ print("recenter on new loc",x,y,z) 
	MyMoveWorldOriginAgainstLocation(moveloc)
	gPlayerShip:SetPos(0,0,0)
end

function MyPlayerHyperMoveRel (dx,dy,dz)
	gPlayerShip.vx = 0
	gPlayerShip.vy = 0
	gPlayerShip.vz = 0
	local moveloc = gPlayerShip.moveloc
	if (not moveloc) then MyMoveWorldOriginAgainstPlayerShip()  moveloc = gPlayerShip.moveloc end
	moveloc:SetPos(	moveloc.x + dx,
					moveloc.y + dy,
					moveloc.z + dz )
	MyMoveWorldOriginAgainstLocation(moveloc)
end

-- big problem : PlayerCam_Pos_Step () .. gPlayerShip:GetPos()   ..  relative to world origin ? 
