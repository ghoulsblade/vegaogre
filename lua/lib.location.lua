-- solarsystem divided into multiple "major locations" to avoid rounding errors/jitter due to the incredibly large distances

function Player_ExecuteJump (jumppoint)
	print("Player_ExecuteJump",jumppoint)
	local oldsystempath = gCurSystemPath -- e.g. "Crucible/Cephid_17"
	Player_ClearSelectedObject()
	VegaUnloadSystem()
	VegaLoadSystem(jumppoint.dest or "Crucible/Cephid_17") 
	NotifyListener("Hook_SystemLoaded") -- hud
	-- TODO : move player to return-jump if available
	RecenterPlayerMoveLoc()
end

function VegaUnloadSystem ()
	--~ VegaDestroySystemRootLoc() --gSolRoot ....  undoes VegaSpawnSystemRootLoc    done by DestroyAllObjectsExceptPlayer
	DestroyAllObjectsExceptPlayer()  -- delete children...     foreach  gObjects[o] .. gNewObjects[o]  o~= playership ??
	gPlayerShip.loc = nil		-- WARNING! cannot be left this way, need RecenterPlayerMoveLoc()
	gPlayerShip.moveloc = nil	-- WARNING! cannot be left this way, need RecenterPlayerMoveLoc()
	gSolRoot = nil
	gCurrentMajorLoc = nil
	-- SpawnSystemEntry(..,system_root_loc,...
	ClearNavTargets() -- RegisterNavTarget(obj)
	ClearMajorLocs() -- RegisterMajorLoc
	-- player loc to new ?
	--~ RecenterPlayerMoveLoc() -- bad idea, no major locs currently
	-- TODO : delete hud markers
	-- TODO : recenter player ? move player to travel-back jumppoint if possible
end



-- ***** ***** ***** ***** ***** MajorLoc

gMajorLocs = {}

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

function ClearMajorLocs () gMajorLocs = {} end
function RegisterMajorLoc (loc) gMajorLocs[loc] = true end
function FindNearestMajorLoc (o) 
	local mind,minloc
	for loc,v in pairs(gMajorLocs) do 
		local d = o:GetDistToObject(loc)
		if ((not minloc) or d < mind) then mind,minloc = d,loc end
	end
	return minloc
end

-- ***** ***** ***** ***** ***** player move loc



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
	if (mloc) then 
		local x,y,z = moveloc:GetVectorToObject(mloc)
		gMLocBaseGfx:SetPosition(x,y,z)
	else
		gMLocBaseGfx:SetPosition(0,0,0)
	end
	
	if (gSolRoot) then
		local x,y,z = moveloc:GetVectorToObject(gSolRoot)
		gSolRootGfx:SetPosition(x,y,z)
		UpdateWorldLight(-x,-y,-z)
	end
	
	
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
	NotifyListener("Hook_PlayerHyperMoveStep",dx,dy,dz) -- hypergfx
end

-- big problem : PlayerCam_Pos_Step () .. gPlayerShip:GetPos()   ..  relative to world origin ? 
