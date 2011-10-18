-- server mode

gProxyHost = "67.212.92.235"
gProxyPort = 6777
local proxyprint = print

function StartServerMode (port) 
	print("starting servermode",port)
	gServerListenerTCP = VegaProxyOpenListener(port)
	
	while true do
		local listener = gServerListenerTCP
		local bDone = false
		while true do
			local newcon = listener:IsAlive() and listener:PopAccepted()
			if (not newcon) then break end
			proxyprint("###############################")
			proxyprint("#### PROXY : connection started, listener=",(listener == gServerListenerTCP) and "A" or "B")
			proxyprint("###############################")
			VegaProxyOneConnection(newcon)
			proxyprint("###############################")
			proxyprint("#### PROXY : connection ended")
			proxyprint("###############################")
			--~ listener = gServerListenerTCP2
			--~ proxyprint("proxy end") return
			bDone = true
		end
		Client_USleep(10) 
		NetReadAndWrite()
		if (bDone) then break end
	end
	
	print("end server mode")
end


function VegaProxyOneConnection (newcon)
	proxyprint("VegaProxyOneConnection : start")
	gProxyClientCon = newcon NetReadAndWrite() -- read initial data from client
	gProxyServerCon = NetConnect(gProxyHost,gProxyPort)
	
	--~ InitPackets()
	
	assert(gProxyClientCon)
	assert(gProxyServerCon,"failed to connect to real server")
	proxyprint("VegaProxyOneConnection : servercon established")
	
	gProxyClientSendFifo			= CreateFIFO()
	gProxyServerSendFifo			= CreateFIFO()
	gProxyClientRecvFifo			= CreateFIFO()
	gProxyServerRecvFifo			= CreateFIFO()
	
	local bProxyDumb = true
	
	local bAlive = true
	while bAlive do
		-- receive
		gProxyClientCon:Pop(gProxyClientRecvFifo)
		gProxyServerCon:Pop(gProxyServerRecvFifo)
		
		-- handle packets
		if (bProxyDumb) then 
			local datasize_from_server = gProxyServerRecvFifo:Size()
			local datasize_from_client = gProxyClientRecvFifo:Size()
			
			if (datasize_from_server > 0) then proxyprint("datasize_from_server",datasize_from_server) proxyprint(FIFOHexDump(gProxyServerRecvFifo)) end
			if (datasize_from_client > 0) then proxyprint("datasize_from_client",datasize_from_client) proxyprint(FIFOHexDump(gProxyClientRecvFifo)) end
			
			gProxyClientSendFifo:PushFIFOPartRaw(gProxyServerRecvFifo) 
			gProxyServerRecvFifo:Clear()
			
			gProxyServerSendFifo:PushFIFOPartRaw(gProxyClientRecvFifo) 
			gProxyClientRecvFifo:Clear()
		else
			-- not yet implemented
		end
		
		
		gProxyClientCon:Push(gProxyClientSendFifo)
		gProxyClientSendFifo:Clear()
		
		gProxyServerCon:Push(gProxyServerSendFifo)
		gProxyServerSendFifo:Clear()
		
		if (not gProxyClientCon:IsConnected()) then proxyprint("disconnected:client") bAlive = false end
		if (not gProxyServerCon:IsConnected()) then proxyprint("disconnected:server") bAlive = false end
		
		-- hardware-step
		Client_USleep(10)
		NetReadAndWrite()
	end
	
	
	NetReadAndWrite() -- one final netstep to make sure that the last data before conloss is still delivered
	proxyprint("VegaProxyOneConnection ended.")
	gProxyClientCon:Destroy()
	gProxyServerCon:Destroy()
	gProxyClientSendFifo:Destroy()
	gProxyServerSendFifo:Destroy()
	gProxyClientRecvFifo:Destroy()
	gProxyServerRecvFifo:Destroy()
end

function VegaProxyOpenListener (port)
	local timeout = Client_GetTicks() + 5*1000
	local listener
	repeat
		listener = NetListen(port)
		if (not listener) then proxyprint("port listen bind fail, retrying...") Client_USleep(1 * 1000) end
	until listener or Client_GetTicks() > timeout 
	assert(listener,"failed to bind to local port "..(port or 0))
	return listener
end

