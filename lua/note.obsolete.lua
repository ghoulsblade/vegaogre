-- obsolete stuff, kept for reference. e.g. interesting code or similar

-- obsolete, was used to manually assemble sol-like system for testing before vega-system-file-loader was ready. 
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


-- obsolete, was used by first generation mesh import via .obj, now replaced by xmesh import with proper material name fixes
--~ EnsureMeshMaterialNamePrefix("llama.mesh","llama")
--~ EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
--~ EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
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
function EnsureMaterialNamePrefix (matname,prefix)
	if (string.find(matname,prefix,nil,true) ~= 1) then return prefix.."_"..matname end
	return matname
end


-- obsolete, was used for location/mayorloc debug
function GetGfxHierarchyText (gfx) return GetNodeHierarchyText(gfx:GetSceneNode()) end
function GetNodeHierarchyText (node) 
	if (not node) then return "." end
	local x,y,z = node:getPosition()
	local ax,ay,az = node:_getDerivedPosition()
	return string.gsub(tostring(node:getRealAddress()),"userdata: ","").."("..x..","..y..","..z..")("..ax..","..ay..","..az.."):"..GetNodeHierarchyText(node:getParentSceneNode())
end


