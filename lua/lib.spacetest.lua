sin = math.sin
cos = math.cos


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
    cam:SetFarClipDistance(10000000) -- ogre defaul : 100000
	
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

function MySetCamBaseGfx (gfx)
	--~ assert(false) -- disabled for now
	local node = gfx:GetSceneNode()
	local camnode = node -- direct
	
	-- indirect test : 
	local camsubgfx = gfx:CreateChild()
	camsubgfx:SetPosition(0,0,0)
	camnode = camsubgfx:GetSceneNode()
	
	-- cam raw
	local cam = GetMainCam():GetQuickHandle()
	local cammov = cam:CastToMovable()
	local camholder = cammov:getParentSceneNode()
	
	local oldparentnode = camholder:getParentSceneNode()
	if (oldparentnode) then oldparentnode:removeChild2(camholder) end
	node:addChild(camholder)
	
	
	--[[
	local oldp = cammov:getParentSceneNode()
	if (oldp) then oldp:detachObject2(cammov) end
	node:attachObject(cammov)
	]]--
end

function GetGfxHierarchyText (gfx) return GetNodeHierarchyText(gfx:GetSceneNode()) end
function GetNodeHierarchyText (node) 
	if (not node) then return "." end
	local x,y,z = node:getPosition()
	local ax,ay,az = node:_getDerivedPosition()
	return string.gsub(tostring(node:getRealAddress()),"userdata: ","").."("..x..","..y..","..z..")("..ax..","..ay..","..az.."):"..GetNodeHierarchyText(node:getParentSceneNode())
end

function MyMoveWorldOriginAgainstGfxPos (gfx) 
	local x,y,z = gfx:GetDerivedPosition()
	print("######################################")
	print("### MyMoveWorldOriginAgainstGfxPos ###",x,y,z)
	print("######################################")
	gWorldOrigin:SetPosition(-x,-y,-z)
	
end

function ShipTestStep ()
	if (not gPlayerShip) then 
		EnsureMeshMaterialNamePrefix("llama.mesh","llama")
		EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
		EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
		--~ os.exit(0)
		
		gBoltMeshName = gBoltMeshName or GenerateBoltMesh()
		
		-- prepare solarsystem : 
		
		local solroot = cLocation:New(nil,0,0,0,0)
		gWorldOrigin = solroot.gfx		
		
		-- planets : 
		-- earth: real:8light hours, vega:1:10: 48 light-minutes = 864.000.000.000 meters.  also: http://en.wikipedia.org/wiki/Earth
		-- local earth = 3rd planet
		local light_second = 300*1000*1000 -- 300 mio m/s
		local light_minute = 60*light_second -- 18.000.000.000 in meters
		local vega_factor = 1/10 -- ... useme ? 
		local au = 150*1000*1000* 1000 * vega_factor    -- (roughly 1 earth-sun distance)
		local planets = {
			--~ { "sun"			,0 			},
			--~ { "test1"		,0				,bStartHere=true}, -- test for rounding errors due to origin-dist
			--~ { "test2"		,10				,bStartHere=true}, -- test for rounding errors due to origin-dist
			--~ { "test3"		,40*1000		,bStartHere=true}, -- test for rounding errors due to origin-dist
			--~ { "test4"		,10*1000*1000	,bStartHere=true}, -- test for rounding errors due to origin-dist
			--~ { "mercury"		,0.4*au 	},
			--~ { "venus"		,0.7*au 	},
			{ "earth"		,1.0*au 	,bStartHere=true},
			--~ { "mars"		,1.5*au 	},
			-- asteroidbelt:2.3-3.3au   
			-- Asteroids range in size from hundreds of kilometres across to microscopic
			-- The asteroid belt contains tens of thousands, possibly millions, of objects over one kilometre in diameter.
			-- [46] Despite this, the total mass of the main belt is unlikely to be more than a thousandth of that of the Earth.
			-- [47] The main belt is very sparsely populated
			-- outerplanets: 
			--~ { "jupiter"		,5.2*au		},
			--~ { "saturn"		,9.5*au     },
			--~ { "uranus"		,19.6*au    },
			--~ { "neptune"		,30*au      },
			-- kuiper belt: 30au-50au   pluto:39au   haumea:43.34au  makemake:45.79au
		}	
		function GetRandomOrbitFlatXY (d,dzmax)
			local ang = math.random()*math.pi*2
			local x,y = d*sin(ang),d*cos(ang)
			local z = (math.random()*2-1)*dzmax
			return x,y,z
		end
		for k,o in pairs(planets) do 
			local name,d = unpack(o)
			--~ local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
			local x,y,z = d,0,0
			local r = 0
			local ploc = cLocation:New(solroot,x,y,z,r)
			
			local pr = 40000
			local planet = cPlanet:New(ploc,0,0,0	,pr,"planetbase")
			planet:SetRandomRot()
			
			-- player ship
			if (o.bStartHere and (not gPlayerShip)) then 
				local x,y,z = pr * 1.2,0,0
				-- player ship
				gPlayerShip = cPlayerShip:New(ploc,x,y,z	,5,"llama.mesh")
				MyMoveWorldOriginAgainstGfxPos(ploc.gfx) 
				--~ MySetCamBaseGfx(ploc.gfx)
				
				if (1 == 2) then 
					print("#################################")
					print("### near-far-near test active ###")
					print("#################################")
					local gfx_far = CreateRootGfx3D()
					local gfx_far2 = gfx_far:CreateChild()
					local gfx_near = gfx_far2:CreateChild()
					local e = 100000000000000000000000000000000000000
					gfx_far:SetPosition(e,0,0)
					gfx_far2:SetPosition(0,e,0)
					gfx_near:SetPosition(-e,-e,0)
					--~ gfx_near:SetPosition(-e-11,0,0)
					gPlayerShip.gfx:SetParent(gfx_near)
					MySetCamBaseGfx(gfx_near)
					-- no rounding errors when moving back and forth...
				end
				
	
				
				
				-- npc ship
				for i=1,10 do 
					local ax,ay,az = Vector.random3(400)
					local o = cNPCShip:New(ploc,x+ax,y+ay,z+az,10,"ruizong.mesh") 
					o:SetRandomRot()
				end
			end
			
			-- stations
			for i = 0,math.random(0,2) do 
				local d = pr * (1.5 + 2.0 * math.random())
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




function PlayerCamStep (dx,dy)
	local cam = GetMainCam()
	
	local roth = -math.pi * .5 * dx * gSecondsSinceLastFrame
	local rotv = -math.pi * .5 * dy * gSecondsSinceLastFrame
	
	local w0,x0,y0,z0 = cam:GetRot()	
	--~ print("PlayerCamStep",dx,dy,w0,x0,y0,z0)
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(roth,0,1,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)	
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)	
	--~ local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)
	cam:SetRot(Quaternion.normalise(w0,x0,y0,z0))
	
	--~ print("cam",cam:GetQuickHandle():getDerivedPosition())
	--~ if (true) then return end
	
	if (not gPlayerShip) then return end
	
	
	
	local ang = math.pi * gMyTicks/1000 * 0.11
	
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
	if (gKeyPressed[key_lcontrol]) then s = s * 100 as = 0 end 
	if (gKeyPressed[key_lcontrol] and gKeyPressed[key_lshift]) then s = s * 10000 as = 0 end 
	local ax,ay,az = Quaternion.ApplyToVector(
		(gKeyPressed[key_d] and -s or 0) + (gKeyPressed[key_a] and  s or 0),
		(gKeyPressed[key_f] and -s or 0) + (gKeyPressed[key_r] and  s or 0),
		(gKeyPressed[key_s] and -s or 0) + (gKeyPressed[key_w] and  s or 0)  + (gKeyPressed[key_lcontrol] and as or 0) ,
		w0,x0,y0,z0)
		
	local o = gPlayerShip
	o.vx,o.vy,o.vz = ax,ay,az
	local x,y,z = gPlayerShip:GetPos()
	--~ print("playerpos",x,y,z)
	local ax,ay,az = Quaternion.ApplyToVector(0,4,-5,w0,x0,y0,z0)
	local ox,oy,oz = x+ax,y+ay,z+az
	
	--~ print("playerderived",gPlayerShip.gfx:GetDerivedPosition())
	
	--~ local ox,oy,oz = 0,0,0
	local dist = 15
	StepThirdPersonCam (cam,dist,ox,oy,oz)
end
