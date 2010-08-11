-- objecttypes 

-- ***** ***** ***** ***** ***** global object list 

gObjects = {}
gNewObjects = {} -- delayed insert into the main list

RegisterStepper(function () 
	local dt = gSecondsSinceLastFrame
	for o,v in pairs(gObjects) do 
		o:Step(dt)
		local x = o.x + o.vx * dt
		local y = o.y + o.vy * dt
		local z = o.z + o.vz * dt
		o.x = x
		o.y = y
		o.z = z
		local gfx = o.gfx
		if (gfx) then gfx:SetPosition(x,y,z) end
	end
	if (next(gNewObjects)) then 
		local arr = gNewObjects
		gNewObjects = {}
		for o,v in pairs(arr) do gObjects[o] = true end
	end
	
	--~ handleCollisionBetweenOneAndWorld(gPlayerShip, gObjects)
end)

-- ***** ***** ***** ***** ***** cObject

cObject = CreateClass()

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


function cObject:Step() end
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

-- ***** ***** ***** ***** ***** cShot

cShot = CreateClass(cObject)

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

function cShip:Init (loc,x,y,z,r,meshname)
	self:InitObj(loc,x,y,z,r)
	self:SetScaledMesh(meshname or "llama.mesh",r)
end

-- ***** ***** ***** ***** ***** cNPCShip

cNPCShip = CreateClass(cShip)

function cNPCShip:Init (loc,x,y,z,r,meshname)
	cShip.Init(self,loc,x,y,z,r,meshname or "ruizong.mesh")
end

function cNPCShip:Step ()
	stepHudMarker(self)
end

-- ***** ***** ***** ***** ***** cPlayerShip

cPlayerShip = CreateClass(cShip)

function cPlayerShip:Init (x,y,z,r,meshname)
	cShip.Init(self,x,y,z,r,meshname)
end
function cPlayerShip:Step ()
	
end

-- ***** ***** ***** ***** ***** cStation

cStation = CreateClass(cObject)

function cStation:Init (loc,x,y,z,r,meshname)
	self:InitObj(loc,x,y,z,r)
	self:SetScaledMesh(meshname or "agricultural_station.mesh",r)
end

function cStation:CanDock (o) return true end

function cStation:Step () 
	stepHudMarker(self)
end

-- ***** ***** ***** ***** ***** cLocation

cLocation = CreateClass(cObject)

function cLocation:Init (loc,x,y,z,r)
	self:InitObj(loc,x,y,z,r)
end

function cLocation:CreateChild () return self.gfx:CreateChild() end


-- ***** ***** ***** ***** ***** cPlanet

cPlanet = CreateClass(cObject)

function cPlanet:Init (loc,x,y,z,r,matname)
	self:InitObj(loc,x,y,z,r)
	local steps_h,steps_v,cx,cy,cz = 31,31,r,r,r
	self.gfx:SetMesh(MakeSphereMesh(steps_h,steps_v,cx,cy,cz))
	self.gfx:GetEntity():setMaterialName(matname or "planetbase")
end

function cPlanet:CanDock (o) return true end

function cPlanet:Step () 
end

-- ***** ***** ***** ***** ***** 
