-- handles solar system stuff, uses utils in lib.data.universe.lua

function LoadFirstSystem ()
	
	gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
	
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
	local node = gStarField:GetSceneNode()
	local movable = (node:numAttachedObjects() > 0) and node:getAttachedObject(0)
	if (movable) then movable:setRenderQueueGroup(RENDER_QUEUE_1) end -- render stars early to skip depth problems
		
	
	-- UpdateWorldLight() called depending on sun
	
	
	gMLocBaseGfx = CreateRootGfx3D()
	
	-- spawn solarsystem
	--~ VegaLoadSystem("Crucible/Everett")
	VegaLoadSystem("Crucible/Cephid_17")
	--~ VegaLoadSystem("Sol/Sol")
	--~ VegaLoadExampleSystem()
	local playerspawnbase
	for k,v in ipairs(gNavTargets) do if (v.name == "Atlantis") then playerspawnbase = v break end end
	--~ for k,v in ipairs(gNavTargets) do if (v.name == "jump to Everett") then playerspawnbase = v break end end
	--~ for k,v in ipairs(gNavTargets) do if (v:GetClass() == "JumpPoint") then playerspawnbase = v break end end
	playerspawnbase = playerspawnbase or gNavTargets[math.random((#gNavTargets > 0) and #gNavTargets or 1)]
	SpawnPlayer(playerspawnbase)
	
	if (playerspawnbase) then playerspawnbase:SelectObject() StartDockedMode(playerspawnbase,"ocean") end
	
	NotifyListener("Hook_SystemLoaded",true)
end


function VegaLoadSystem (systempath) -- systempath = sector/system e.g. "Crucible/Cephid_17"
	print("=================\nVegaLoadSystem",systempath)
	
	gCurSystemPath = systempath -- e.g. "Crucible/Cephid_17"
	gCurSystemRadius = 0
	
	local system = VegaLoadSystemToXML (systempath)
	assert(system)
	
	-- extract some data and load the system
	gCurSystemScale = tonumber(system.scalesystem or "") or 1
	print("system:",filepath,system.name,system.background,gCurSystemScale) --~ "Cephid_17","backgrounds/green","1000"
	
	SetSystemBackground(system.background)
	
	local system_root_loc = gVegaUniverseDebugNoGfx and {} or VegaSpawnSystemRootLoc()
	for k,child in ipairs(system) do 
		SpawnSystemEntry(child,system_root_loc,0)
	end
	-- file="stars/white_star.texture" -> white_star__planets
end


function GetJumpByPath (systempath) for k,v in ipairs(gNavTargets) do if (v.dest == systempath) then return v end end end

gSpawnSystemEntryID = 0

function SpawnSystemEntry (child,parentloc,depth)
	gSpawnSystemEntryID = gSpawnSystemEntryID + 1
	if (child._name == "Light") then return end
	if (child._name == "Fog") then return end     
	if (child._name == "Atmosphere") then return end  
	assert(parentloc)
	local s = gCurSystemScale
	--~ print("custom scale",gCurSystemScale)
	local d = (GetOrbitMeanRadiusFromNode(child) or 0)*s
	local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
	--~ print("orbidist",GetDistText(d),GetDistText(Vector.len(x,y,z)))
	if (child.x) then 
		local ax = tonumber(child.x or 0) -- or (x/s)) * s
		local ay = tonumber(child.y or 0) -- or (y/s)) * s
		local az = tonumber(child.z or 0) -- or (z/s)) * s
		if (ax and ay and az and Vector.len(ax,ay,az) ~= 0) then 
			x = ax * s
			y = ay * s
			z = az * s
		end
		--~ print("orbidist custompos (ignored if zero)",GetDistText(Vector.len(ax,ay,az)))
	end
	local loc = gVegaUniverseDebugNoGfx and {} or VegaSpawnMajorLoc(parentloc,x,y,z,child.name)
	local r = child.radius and tonumber(child.radius)
	if (r) then r = r * s end
	local file = child.file
	local unittype = GetUnitTypeFromSectorXMLNode(child)
	local dbg_unitname = unittype and unittype.id or (file and ("NOTFOUND:"..GetPlanetUnitTypeIDFromTexture(file)))
	--~ print(string.rep("+",depth),gSpawnSystemEntryID,pad(child._name or "",10),pad(child.name or "",10),pad(floor(d),10),pad(tostring(r and floor(r)),10),pad(dbg_unitname,20),child.file)
	local unitid = child.file
	
	if (not gVegaUniverseDebugNoGfx) then
		--~ destination="Crucible/Stirling" faction="klkk"
		local obj
		if (child._name == "Unit") then
			obj = cStation:New(loc,0,0,0	,r or 400,GetUnitMeshNameFromNode(child),child)
		elseif (child._name == "Asteroid") then
			obj = cAsteroidField:New(loc,0,0,0,10,GetPlanetMaterialNameFromNode(child),child)  -- TODO!
		elseif (child.file == kJumpTextureName or child._name == "Jump") then
			obj = cJumpPoint:New(loc,0,0,0,10,GetJumpDestinationFromNode(child),child)  -- TODO!
		elseif (child._name == "Planet" and child.light) then
			obj = cSun:New(loc,0,0,0	,r or 6371.0*km,GetPlanetMaterialNameFromNode(child),child)
		elseif (child._name == "Planet") then
			obj = cPlanet:New(loc,0,0,0	,r or 6371.0*km,GetPlanetMaterialNameFromNode(child),child)
		end
		if (obj) then 
			gCurSystemRadius = max(gCurSystemRadius,obj:GetDistToRoot() + (obj.r or 0))
			obj:SetRandomRot()
			obj.name = ImproveObjectName(child.name)
			--~ obj.name = "["..gSpawnSystemEntryID.."]"..obj.name
			loc.primary_object = obj
			obj.orbit_master = parentloc and parentloc.primary_object
			RegisterNavTarget(obj)
		end
	end
	
	for k,subchild in ipairs(child) do SpawnSystemEntry(subchild,loc,depth+1) end
end

--[[
SpawnSystemEntry        Asteroid                        0               AFieldJumpThin
SpawnSystemEntry        Planet          JumpTo17-ar     0               jump.texture
SpawnSystemEntry        Planet          Cephid_17 A     0               stars/white_star.texture
SpawnSystemEntry        Planet          Atlantis        162788240       planets/oceanBase.texture|planets/ocean.texture
SpawnSystemEntry        Planet          Phillies        723268          planets/rock.texture
SpawnSystemEntry        Planet          JumpToEnyo      829181          jump.texture
SpawnSystemEntry        Planet          JumpToCardell   660457          jump.texture
SpawnSystemEntry        Unit            Ataraxia        61717           Fighter_Barracks
SpawnSystemEntry        Planet          JumpToOldziey   145266170       jump.texture
SpawnSystemEntry        Unit            Plainfield      35369           Relay
SpawnSystemEntry        Planet          JumpToEverett   149724056       jump.texture
SpawnSystemEntry        Planet          JumpToStirling  142012802       jump.texture
SpawnSystemEntry        Planet          Cephid_17 B     4574264635      stars/red_star.texture
SpawnSystemEntry        Planet          Wiley           177492695       planets/molten.texture
SpawnSystemEntry        Unit            Serenity        44024           MiningBase
SpawnSystemEntry        Planet          Broadway        120320579       sol/ganymede.texture|planets/rock.texture
]]--


