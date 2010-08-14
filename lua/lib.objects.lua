-- objecttypes 

-- ***** ***** ***** ***** ***** global object list 

gObjects = {}
gNewObjects = {} -- delayed insert into the main list

function VegaMainStep ()
	local dt = gSecondsSinceLastFrame
	
	GuiTest_CursorCrossHair_Step() -- only moves gui widget to mousepos
	
	for o,v in pairs(gObjects) do o:Step(dt) end -- think, might modify params for physstep ( might also add new items )
	
	for o,v in pairs(gObjects) do o:PhysStep(dt) end -- move items and gfx:SetPos()
	
	--~ handleCollisionBetweenOneAndWorld(gPlayerShip, gObjects)   (do collision, might change pos and speed, so do before physstep) 
	-- deactivated until large-universe rounding errors system finished  (should be between pos+=vel and render, so intersections can be solved before being rendered)
	
	-- insert new items into main list  (can be done after physstep, since InitObj already calls gfx:SetPos())
	if (next(gNewObjects)) then local arr = gNewObjects gNewObjects = {} for o,v in pairs(arr) do gObjects[o] = true end end
	
	
	PlayerStep() -- moves cam and handles player keyboard, changes player velocity, but not position.  call before HUD stuff so cam is up to date for render
	
	NotifyListener("Hook_HUDStep") -- updates special hud elements dependant on object positions that don't have auto-tracking
	
	for o,v in pairs(gObjects) do o:HUDStep(dt) end -- update hud markers, should be done AFTER moving objects and updating cam
	
	NotifyListener("Hook_PreRenderOneFrame")
	
	ShipTestStep()
end

-- ***** ***** ***** ***** ***** cObject

cObject = CreateClass()
function cObject:GetClass() return "Object" end

function cObject:Init (loc,x,y,z,r)
	self:InitObj(loc,x,y,z,r)
end

function cObject:Destroy ()
	if (self.gfx) then self.gfx:Destroy() self.gfx = nil end
	gObjects[self] = nil
	gNewObjects[self] = nil
end

function cObject:InitObj (loc,x,y,z,r)
	local gfx = loc and loc:CreateChild() or CreateRootGfx3D()
	gfx:SetPosition(x,y,z)
	self.loc = loc
	self.gfx = gfx
	self.x = x
	self.y = y
	self.z = z
	self.vx = 0
	self.vy = 0
	self.vz = 0
	self.r = r or 10
	gNewObjects[self] = true
end

function cObject:PhysStep(dt)
	local x = self.x + self.vx * dt
	local y = self.y + self.vy * dt
	local z = self.z + self.vz * dt
	self.x = x
	self.y = y
	self.z = z
	local gfx = self.gfx
	if (gfx) then gfx:SetPosition(x,y,z) end
end

function cObject:Step() end
function cObject:HUDStep() end
function cObject:GetPos() return self.x,self.y,self.z end
function cObject:SetPos(x,y,z) self.x,self.y,self.z = x,y,z end --  self.gfx:SetPosition(x,y,z)
function cObject:SetRandomRot() self:SetRot(Quaternion.random()) end
function cObject:SetRot(w,x,y,z) self.gfx:SetOrientation(w,x,y,z) end
function cObject:GetRot() return self.gfx:GetOrientation() end

function cObject:SetScaledMesh(meshname,r)
	local gfx = self.gfx
	gfx:SetMesh(meshname)
	local s = r / gfx:GetEntity():getBoundingRadius()
	gfx:SetScale(s,s,s)
end

function cObject:CanDock (o) return false end

function cObject:MoveToNewLoc (loc)
	self.gfx:SetParent(loc.gfx)
	self.loc = loc
end 
function cObject:GetPosFromSun () 
	local p = self.loc
	return self.x+p.x,self.y+p.y,self.z+p.z
end
function cObject:GetDistToPlayer () return self:GetDistToObject(gPlayerShip) end
function cObject:GetDistToObject (o) return Vector.len(self:GetVectorToObject(o)) end
function cObject:GetVectorToObject (a) 
	local ao = a.loc
	local so = self.loc
	return	(a.x-self.x)+(ao.x-so.x),
			(a.y-self.y)+(ao.y-so.y),
			(a.z-self.z)+(ao.z-so.z)
end
	
function cObject:GetPosForMarker () 
	return self.gfx:GetDerivedPosition()
	--~ local o = gPlayerShip.loc
	--~ local p = self.loc
	
	--~ gWorldOriginX = x
	--~ gWorldOriginY = y
	--~ gWorldOriginZ = z
	
	--~ return (self.x+p.x)-o.x,(self.y+p.y)-o.y,(self.z+p.z)-o.z
	--~ return self.x+(p.x-o.x),self.y+(p.y-o.y),self.z+(p.z-o.z)
	--~ return self.x,self.y,self.z
	--~ return self.x+(p.x),self.y+(p.y),self.z+(p.z)
	--~ return self.x+(p.x-gWorldOriginX),self.y+(p.y-gWorldOriginY),self.z+(p.z-gWorldOriginZ)
	--~ return self.x+p.x+gWorldOriginX,self.y+p.y+gWorldOriginY,self.z+p.z+gWorldOriginZ
end

-- ***** ***** ***** ***** ***** cShot

cShot = CreateClass(cObject)
function cShot:GetClass() return "Shot" end

function cShot:Init (o)
	--~ print("cShot:Init",o)
	local loc = o.loc
	local x,y,z = o:GetPos()
	local r = 1
	local w0,x0,y0,z0 = o:GetRot()
	local s = 100
	local vx,vy,vz = Quaternion.ApplyToVector(0,0,s,w0,x0,y0,z0)
	vx,vy,vz = vx+o.vx,vy+o.vy,vz+o.vz
	local dt = gSecondsSinceLastFrame
	self:InitObj(loc,x+dt*vx,y+dt*vy,z+dt*vz,r)
	self:SetScaledMesh(gBoltMeshName,r)
	self:SetRot(w0,x0,y0,z0)
	self.vx,self.vy,self.vz = vx,vy,vz
end


-- ***** ***** ***** ***** ***** cShip

cShip = CreateClass(cObject)
function cShip:GetClass() return "Ship" end

function cShip:Init (loc,x,y,z,r,meshname)
	self:InitObj(loc,x,y,z,r)
	self:SetScaledMesh(meshname or "llama.mesh",r)
end


-- ***** ***** ***** ***** ***** cNPCShip

cNPCShip = CreateClass(cShip)
function cNPCShip:GetClass() return "NPCShip" end

function cNPCShip:Init (loc,x,y,z,r,meshname)
	cShip.Init(self,loc,x,y,z,r,meshname or "ruizong.mesh")
end

function cNPCShip:HUDStep ()
	stepHudMarker(self)
end

-- ***** ***** ***** ***** ***** cPlayerShip

cPlayerShip = CreateClass(cShip)
function cPlayerShip:GetClass() return "PlayerShip" end

function cPlayerShip:Init (x,y,z,r,meshname)
	cShip.Init(self,x,y,z,r,meshname)
end
function cPlayerShip:Step ()
	
end

-- ***** ***** ***** ***** ***** cStation

cStation = CreateClass(cObject)
function cStation:GetClass() return "Station" end

function cStation:Init (loc,x,y,z,r,meshname)
	self:InitObj(loc,x,y,z,r)
	self:SetScaledMesh(meshname or "agricultural_station.mesh",r)
	--~ self.name = "station"
end

function cStation:CanDock (o) return true end

function cStation:HUDStep () 
	stepHudMarker(self)
end

-- ***** ***** ***** ***** ***** cLocation

cLocation = CreateClass(cObject)
function cLocation:GetClass() return "Location" end

function cLocation:Init (loc,x,y,z,r)
	self:InitObj(loc,x,y,z,r)
end

function cLocation:CreateChild () return self.gfx:CreateChild() end

function cLocation:PhysStep(dt) end -- DONT MOVE GFX! (hard to find error if it resets offset)

function cLocation:SetPos(x,y,z) self.x,self.y,self.z = x,y,z self.gfx:SetPosition(x,y,z) end

-- ***** ***** ***** ***** ***** cPlanet

cPlanet = CreateClass(cObject)
function cPlanet:GetClass() return "Planet" end

function cPlanet:Init (loc,x,y,z,r,matname)
	self:InitObj(loc,x,y,z,r)
	local steps_h,steps_v,cx,cy,cz = 31,31,r,r,r
	self.gfx:SetMesh(MakeSphereMesh(steps_h,steps_v,cx,cy,cz))
	self.gfx:GetEntity():setMaterialName(matname or "planetbase")
end

function cPlanet:CanDock (o) return true end

function cPlanet:HUDStep () 
	stepHudMarker(self)
end

-- ***** ***** ***** ***** ***** 
