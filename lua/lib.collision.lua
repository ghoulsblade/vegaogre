
-- one can be part of all
-- allobjects as stores in the keys of the table
-- ones position gets adjusted to resolve the collision
-- collision is based on sphere-sphere distance
-- objects must have x,y,z,r
function handleCollisionBetweenOneAndWorld(oneObject, allObjects)
	if oneObject and allObjects then
		local x,y,z,r = oneObject.x,oneObject.y,oneObject.z,oneObject.r
		
		for obj,tmp in pairs(allObjects) do
			if obj ~= oneObject then
				local dist = MinDistSphereSphere(x,y,z,r, obj.x,obj.y,obj.z,obj.r)
				
				if dist < 0 then
					resolveCollision(oneObject, obj, abs(dist))
					
					-- update cached position
					x,y,z,r = oneObject.x,oneObject.y,oneObject.z,oneObject.r
				end
			end
		end
	end
end

-- moves collidingObject to resolve the collision between both objects
-- overlappLen is the amount needed to resolve the collision
-- sphere-sphere
-- see handleCollisionBetweenOneAndWorld
function resolveCollision(collidingObject, staticObject, overlappLen)
	local sx,sy,sz = staticObject.x, staticObject.y, staticObject.z
	local cx,cy,cz = collidingObject.x, collidingObject.y, collidingObject.z
	
	local resolveX, resolveY, resolveZ = Vector.sub(cx,cy,cz, sx,sy,sz)
	resolveX, resolveY, resolveZ = Vector.normalise_to_len(resolveX, resolveY, resolveZ, overlappLen)
	
	collidingObject.x = collidingObject.x + resolveX
	collidingObject.y = collidingObject.y + resolveY
	collidingObject.z = collidingObject.z + resolveZ
end
