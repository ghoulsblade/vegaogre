-- proxy mode for debugging, sits between original client and original server
-- see also lib.net.proxy-old.lua


function StartProxyMode (port) 
	print("starting proxy mode port=",port)
	
	--[[
	gServerListenerTCP = VegaProxyOpenListener(port)
	gProxyMode = true
	
	while true do
		local listener = gServerListenerTCP
		local bDone = false
		while true do
			local newcon = listener:IsAlive() and listener:PopAccepted()
			if (not newcon) then break end
			print("--###############################")
			print("--#### PROXY : connection started, listener=",(listener == gServerListenerTCP) and "A" or "B")
			print("--###############################")
			VegaProxyOneConnection(newcon)
			print("--###############################")
			print("--#### PROXY : connection ended")
			print("--###############################")
			--~ listener = gServerListenerTCP2
			--~ print("proxy end") return
			bDone = true
		end
		Client_USleep(10) 
		NetReadAndWrite()
		if (bDone) then break end
	end
	]]--
	
	print("end proxy mode")
end

