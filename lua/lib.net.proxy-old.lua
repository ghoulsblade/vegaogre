
--~ gProxyHost = "localhost"
gProxyHost = "192.168.178.26"
--~ gProxyHost = "67.212.92.235"
gProxyPort = 6777

function StartProxyMode (port) 
	print("starting servermode",port)
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
	
	print("end server mode")
end


function VegaProxyOpenListener (port)
	local timeout = Client_GetTicks() + 5*1000
	local listener
	repeat
		listener = NetListen(port)
		if (not listener) then print("port listen bind fail, retrying...") Client_USleep(1 * 1000) end
	until listener or Client_GetTicks() > timeout 
	assert(listener,"failed to bind to local port "..(port or 0))
	return listener
end

function VegaProxyOneConnection (newcon)
	print("--VegaProxyOneConnection : start")
	gProxyClientCon = newcon NetReadAndWrite() -- read initial data from client
	gProxyServerCon = NetConnect(gProxyHost,gProxyPort)
	
	--~ InitPackets()
	
	local client = {ip="127.0.0.1",SendPacket=NetSendClientPacket}
	
	assert(gProxyClientCon)
	assert(gProxyServerCon,"failed to connect to real server")
	print("--VegaProxyOneConnection : servercon established")
	
	gProxyClientSendFifo			= CreateFIFO()
	gProxyServerSendFifo			= CreateFIFO()
	gProxyClientRecvFifo			= CreateFIFO()
	gProxyServerRecvFifo			= CreateFIFO()
	
	gProxyClientRecvDecodeFifo		= CreateFIFO()
	gProxyServerRecvDecodeFifo		= CreateFIFO()
	gPayloadBuffer					= CreateFIFO()
	
	gVegaHandlerNetBuf = cVegaNetBuf:New()
	
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
			
			-- push into decode fifos
			gProxyClientRecvDecodeFifo:PushFIFOPartRaw(gProxyClientRecvFifo)
			gProxyServerRecvDecodeFifo:PushFIFOPartRaw(gProxyServerRecvFifo)
			
			-- handle one packet, returns false if packet incomplete, otherwise returns true and pops packet from fifo
			local function MyDecodePacket (fifo,size,bFromServer)
				if (size <= 0) then return end 
				--~ if (VNet.PreHeaderLen+VNet.HeaderLen			> size) then print("packet incomplete, headers") return false end
				--~ if (VNet.PeekPreHeaderLen(fifo)					> size) then print("packet incomplete, datalen prehead") return false end
				--~ if (VNet.PeekHeaderLen(fifo,VNet.PreHeaderLen)	> size) then print("packet incomplete, datalen head") return false end
				
				local fromtxt = (bFromServer and "server" or "client")
				--~ local bPrintIncomplete = false
				local bPrintIncomplete = true
				local lmin = VNet.PreHeaderLen+VNet.HeaderLen												if (lmin > size) then if (bPrintIncomplete) then print("-- from:"..fromtxt.." packet incomplete, headers",lmin,size) end return false end
				local lmin = VNet.PreHeaderLen+VNet.PeekPreHeaderLen(fifo)									if (lmin > size) then if (bPrintIncomplete) then print("-- from:"..fromtxt.." packet incomplete, datalen prehead",lmin,size) end return false end
				local lmin = VNet.PreHeaderLen+VNet.HeaderLen+VNet.PeekHeaderLen(fifo,VNet.PreHeaderLen)	if (lmin > size) then if (bPrintIncomplete) then print("-- from:"..fromtxt.." packet incomplete, datalen head",lmin,size) end return false end
				
				
				local ph = VNet.PopPreHeader(fifo)
				print("--preheader: _len="..ph._len.."="..Hex(ph._len).." _pri="..ph._pri.." _flags="..Hex(ph._flags))
				local h = VNet.PopHeader(fifo)
				local cmdname = VNet.GetCmdName(h.command)
				print("{ "..(bFromServer and "fromserver" or "fromclient")..": cmd="..h.command.."="..(cmdname or "??").." ser="..h.serial.." time="..h.timestamp.." len="..h.data_length.."="..Hex(h.data_length).." flags="..Hex(h.flags).." restlen="..fifo:Size().."="..Hex(fifo:Size()))
				local datalen = h.data_length
				
				-- handler
				local handlerlist = bFromServer and gNetCmdFromServer or gNetCmdFromClient
				local packetformats = bFromServer and gPacketFormatFromServer or gPacketFormatFromClient
				local handler = cmdname and handlerlist[cmdname]
				if (handler) then
					local packetformat = packetformats[h.command]
					gPayloadBuffer:Clear()
					gPayloadBuffer:PushFIFOPartRaw(fifo,0,min(datalen,fifo:Size()))
					gVegaHandlerNetBuf:ReInit(gPayloadBuffer)
					-- TODO : global handle time from header ?
					if (bFromServer) then
						-- from server
						if (packetformat) then -- if packet format is fixed and known, extract parameters
							handler(gVegaHandlerNetBuf,h,ph,PacketFormatExtract(gVegaHandlerNetBuf,unpack(packetformat)))
						else
							handler(gVegaHandlerNetBuf,h,ph)
						end
					else
						-- from client, add client param
						if (packetformat) then -- if packet format is fixed and known, extract parameters
							handler(gVegaHandlerNetBuf,h,ph,client,PacketFormatExtract(gVegaHandlerNetBuf,unpack(packetformat)))
						else
							handler(gVegaHandlerNetBuf,h,ph,client)
						end
					end
					local restlen = gPayloadBuffer:Size()
					if (restlen > 0) then print("--#### unhandled payload rest:",restlen,FIFOHexDump(gPayloadBuffer)) end
				else	
					print("warning, no handler for packet")
				end
				
				-- remove data
				if (datalen >= 0 and datalen <= fifo:Size()) then
					--~ print("payload:"..FIFOHexDump(fifo,0,datalen))
					if (datalen > 0) then fifo:PopRaw(datalen) end
					print("removing payload data. removed,remaining=",datalen,fifo:Size())
				else
					print("failed to remove payload data, clearing fifo for recovery. payload request, actual size",datalen,fifo:Size())
					fifo:Clear()
				end
				print("}")
				return true
			end
			
			-- try to handle packet data directly as it arrives, turned out this alone doesn't work, so decode fifo was added
			local function MyHandlePacketDirect (title,size,bFromServer,fifo,decodefifo) 
				if (size <= 0) then return end 
				local s2 = size-VNet.PreHeaderLen
				local s3 = size-VNet.PreHeaderLen-VNet.HeaderLen
				print(title,size.."="..Hex(size),"noprehead="..s2.."="..Hex(s2),"data="..s3.."="..Hex(s3))
				while MyDecodePacket(decodefifo,decodefifo:Size(),bFromServer) do end
				--~ print(FIFOHexDump(fifo))
			end
			
			
			MyHandlePacketDirect("--datasize_from_server",datasize_from_server,true ,gProxyServerRecvFifo,gProxyServerRecvDecodeFifo)
			MyHandlePacketDirect("--datasize_from_client",datasize_from_client,false,gProxyClientRecvFifo,gProxyClientRecvDecodeFifo)
			
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
		
		if (not gProxyClientCon:IsConnected()) then print("disconnected:client") bAlive = false end
		if (not gProxyServerCon:IsConnected()) then print("disconnected:server") bAlive = false end
		
		-- hardware-step
		Client_USleep(10)
		NetReadAndWrite()
	end
	
	
	NetReadAndWrite() -- one final netstep to make sure that the last data before conloss is still delivered
	print("VegaProxyOneConnection ended.")
	gProxyClientCon:Destroy()
	gProxyServerCon:Destroy()
	gProxyClientSendFifo:Destroy()
	gProxyServerSendFifo:Destroy()
	gProxyClientRecvFifo:Destroy()
	gProxyServerRecvFifo:Destroy()
	gProxyClientRecvDecodeFifo:Destroy()
	gProxyServerRecvDecodeFifo:Destroy()
end
