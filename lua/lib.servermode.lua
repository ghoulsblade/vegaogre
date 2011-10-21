-- server mode


-- to run local server, grab cd into vegastrike-trunk (the dir containing data and vegastrike) and run vegaserver

gProxyHost = "localhost"
--~ gProxyHost = "67.212.92.235"
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
			
			local function MyPacket (title,size,bFromServer,fifo) 
				if (size <= 0) then return end 
				local s2 = size-VNet.PreHeaderLen
				local s3 = size-VNet.PreHeaderLen-VNet.HeaderLen
				proxyprint(title,size.."="..Hex(size),"noprehead="..s2.."="..Hex(s2),"data="..s3.."="..Hex(s3))
				if (size >= VNet.PreHeaderLen+VNet.HeaderLen) then
					local fifo2 = CreateFIFO()
					fifo2:PushFIFOPartRaw(fifo)
					local ph = VNet.PopPreHeader(fifo2)
					print("preheader: _len="..ph._len.."="..Hex(ph._len).." _pri="..ph._pri.." _flags="..Hex(ph._flags))
					local h = VNet.PopHeader(fifo2)
					print("packet: cmd="..h.command.."="..(VNet.GetCmdName(h.command) or "??").." ser="..h.serial.." time="..h.timestamp.." len="..h.data_length.."="..Hex(h.data_length).." flags="..Hex(h.flags).." restlen="..fifo2:Size().."="..Hex(fifo2:Size()))
					proxyprint(FIFOHexDump(fifo))
					--~ proxyprint(FIFOHexDump(fifo2))
					fifo2:Destroy()
				else
					proxyprint(FIFOHexDump(fifo))
				end
				
				-- Packet::Packet( PacketMem &buffer ) : note . packet data (but not header) might be compressed : packet_uncompress( _packet,...)
			end
			MyPacket("datasize_from_server",datasize_from_server,true ,gProxyServerRecvFifo)
			MyPacket("datasize_from_client",datasize_from_client,false,gProxyClientRecvFifo)
			
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

