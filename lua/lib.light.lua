-- lighting conditions

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
