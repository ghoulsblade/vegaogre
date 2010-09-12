-- hyperspeed graphical effect
-- tex : data/hyperspeed.dds  nat : hyperspeedmat


cHyperGfx = CreateClass()

RegisterListener("Hook_VegaInit",function () gHyperGfx = cHyperGfx:New() end)



function cHyperGfx:Init ()
	self.lastmovet = 0
	self.dx = 0
	self.dy = 0
	self.dz = 1
	RegisterStepper(function () self:Step() end)
	RegisterListener("Hook_PlayerHyperMoveStep",function (...) self:PlayerHyperMoveStep(...) end) 
	
	InvokeLater(1000,function () Player_SelectNextNavTarget() ToggleAutoPilot() end) -- easy testing
end

function cHyperGfx:PlayerHyperMoveStep (dx,dy,dz)
	self.lastmovet = gMyTicks
	self.dx = dx
	self.dy = dy
	self.dz = dz
end


function cHyperGfx:Step ()
	local fadet = 1000
	local age = gMyTicks - self.lastmovet
	local f = (age > fadet) and 0 or (1 - age/fadet)
	--~ print("cHyperGfx",f)
	local bActive = true
	
	if (bActive) then 
		local gfx = self.gfx
		if (not gfx) then gfx = GetPlayerMoveLoc().gfx:CreateChild() self.gfx = gfx end
		
		if (not gfx.bHyperInit) then 
			gfx.bHyperInit = true
			if (1 == 1) then 
				gfx:SetMesh(CreateTunnelMesh("hyperspeedmat"))
			else 
				local r = 7
				local res = 51 -- 31
				local steps_h,steps_v,cx,cy,cz = res,res,r,r,r
				gfx:SetMesh(MakeSphereMesh(steps_h,steps_v,cx,cy,cz))
				gfx:GetEntity():setMaterialName("hyperspeedmat")
			end
			-- Ogre::MovableObject::setRenderQueueGroup(uint8 queueID)  see RenderQueue for details , see RenderQueueGroupID enum (OgreRenderQueue.h)
			gfx:GetEntity():setRenderQueueGroup(RENDER_QUEUE_6) -- one after default
		end
		
		gfx:SetOrientation(Quaternion.getRotation(0,0,1,self.dx,self.dy,self.dz))
		
	end
	
end

-- ***** ***** ***** ***** ***** tunnelgfx


function CreateTunnelMeshGeometry ()
	local vb0 = cVertexBuffer:New()
	local ib = cIndexBuffer:New()
	
	local function vertex	(x,y,z,u,v)	vb0:Vertex(x,y,z,u,v) end
	local function tri		(a,b,c)		ib:MultiIndex(a,b,c) end
	
	
	local rbase0 = 0
	local rbase1 = 40
	local zlen = 100
	local sin = math.sin
	local cos = math.cos
	local pi = math.pi
	local waverep = 5
	local wavestr = 0.01
	
	local izsegs = 32 -- "down" the tunnel
	local radsegs = 31
	local vc_per_z = radsegs+1 -- (start and end have same pos but different texcoords : two vertices)
	for iz = 0,izsegs do 
		local u = iz/izsegs
		local u_inv = 1 - u
		local z = zlen * u
		local r = u * rbase0 + u_inv * rbase1 * ( 1 + wavestr * sin(u*waverep*pi*2))  -- todo : * sinus?
		for iv = 0,radsegs do 
			local v = iv/radsegs
			local ang = v*pi*2
			local x,y = r*sin(ang),r*cos(ang)
			vertex(x,y,z,u,v)
		end
		if (iz < izsegs) then 
			local i0 = iz * vc_per_z
			local i1 = i0 + vc_per_z
			for i = 0,radsegs-1 do 
				tri(i0+i  ,i1+i+1,i1+i)
				tri(i0+i+1,i1+i+1,i0+i)
			end
		end
	end
	
	-- geometry (normals ? nah..)
	
	vb0:CheckSize()
	return vb0,ib,math.max(zlen,rbase0,rbase1)
end

function CreateTunnelMesh (msMatName,szMeshName,...)
	msMatName = msMatName or "basewhitenolighting"
	szMeshName = szMeshName or "myTunnelMesh"
	local pMesh = MeshManager_createManual(szMeshName) -- 	Ogre::MeshPtr
	
	-- create submesh
	local sub = pMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(msMatName)
	sub:setUseSharedVertices(false)
	
	sub:setOperationType(OT_TRIANGLE_LIST)
	
	local vb0,ib,r = CreateTunnelMeshGeometry(...)
	
	local vertexData = CreateVertexData()
	local indexData = CreateIndexData()
	sub:setVertexData(vertexData)
	sub:setIndexData(indexData)
	
	local vdecl = cVertexDecl:New()
	vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
	--~ vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
	vdecl:addElement(0,VET_FLOAT2,VES_TEXTURE_COORDINATES)
	--~  TODO : if (bUseColors)		offset += decl.addElement(0, offset, VET_COLOUR, VES_DIFFUSE).getSize()      autoorganize position!!!
	
	vertexData:setVertexDecl(vdecl:GetOgreVertexDecl())
	vertexData:createAndBindVertexBuffer(vb0:GetVertexSize(),vb0:GetVertexNum(),HBU_STATIC_WRITE_ONLY,false,0) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
	indexData:createAndBindIndexBuffer(IT_32BIT,ib:GetIndexNum(),HBU_STATIC_WRITE_ONLY) -- (iIndexType,iNumIndexes,iUsage,bUseShadowBuffer=false)
	
	vertexData:setVertexStart(0)
	indexData:setIndexStart(0)
	vertexData:setVertexCount(vb0:GetVertexNum())
	indexData:setIndexCount(ib:GetIndexNum())
	
	vertexData:writeToVertexBuffer(vb0:GetFIFO(),0)
	indexData:writeToIndexBuffer(ib:GetFIFO()) 
	
	--~ calculate bounds,  todo : calc for whole mesh, not only for this submesh
	pMesh:_setBounds({-r,-r,-r,r,r,r},false)
	pMesh:_setBoundingSphereRadius(r)
	
	vb0:Destroy()
	ib:Destroy()
	
	return szMeshName
end