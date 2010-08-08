-- objecttypes 

-- ***** ***** ***** ***** ***** cObject

cObject = CreateClass()

function cObject:Init (x,y,z,r,matname)
	self:InitObj(x,y,z,r)
end

function cObject:Destroy ()
	if (self.gfx) then self.gfx:Destroy() self.gfx = nil end
end

function cObject:InitObj (x,y,z,r)
	local gfx = CreateRootGfx3D()
	gfx:SetPosition(x,y,z)
	self.gfx = gfx
	self.x = x
	self.y = y
	self.z = z
	self.vx = 0
	self.vy = 0
	self.vz = 0
	self.r = r or 10
end


function cObject:GetPos() return self.x,self.y,self.z end
function cObject:SetPos(x,y,z) self.x,self.y,self.z = x,y,z self.gfx:SetPosition(x,y,z) end

function cObject:SetScaledMesh(meshname,r)
	local gfx = self.gfx
	gfx:SetMesh(meshname)
	local s = r / gfx:GetEntity():getBoundingRadius()
	gfx:SetScale(s,s,s)
end

function cObject:CanDock (o) return false end

-- ***** ***** ***** ***** ***** cShip

cShip = CreateClass(cObject)

function cShip:Init (x,y,z,r,meshname)
	self:InitObj(x,y,z,r)
	self:SetScaledMesh(meshname or "llama.mesh",r)
end

-- ***** ***** ***** ***** ***** cNPCShip

cNPCShip = CreateClass(cShip)

function cNPCShip:Init (x,y,z,r,meshname)
	cShip.Init(self,x,y,z,r,meshname or "ruizong.mesh")
end

-- ***** ***** ***** ***** ***** cStation

cStation = CreateClass(cObject)

function cStation:Init (x,y,z,r,meshname)
	self:InitObj(x,y,z,r)
	self:SetScaledMesh(meshname or "agricultural_station.mesh",r)
end

function cStation:CanDock (o) return true end

-- ***** ***** ***** ***** ***** cPlanet

cPlanet = CreateClass(cObject)

function cPlanet:Init (x,y,z,r,matname)
	self:InitObj(x,y,z,r)
	local steps_h,steps_v,cx,cy,cz = 31,31,r,r,r
	self.gfx:SetMesh(MakeSphereMesh(steps_h,steps_v,cx,cy,cz))
	self.gfx:GetEntity():setMaterialName(matname or "planetbase")
end

function cPlanet:CanDock (o) return true end

-- ***** ***** ***** ***** ***** 
