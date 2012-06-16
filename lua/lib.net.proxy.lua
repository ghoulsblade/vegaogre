-- proxy mode for debugging, sits between original client and original server
-- see also lib.net.proxy-old.lua

--~ gProxyHost = "localhost"
--~ gProxyHost = "67.212.92.235"
gProxyHost = "192.168.178.26"  -- accserver-http-response=192.168.178.264-> '192.168.178.26''4' (from number_space_string protocol) ??    192.168.178.28=client, 192.168.178.26=server
gProxyPort_TCP = 6777
gProxyPort_TCP_Acc = 8080
gProxyPort_UDP_Min = 6771 	--~ <var name="udp_listen_port" value="6771"/>
gProxyPort_UDP_Max = 6776	--~ <var name="udp_listen_port_max" value="6776"/>
-- NOTE: 2012-06-16 accserver(8080) response directly after login contains server ip, so either modify this packet, or modify accountserver.py to return 127.0.0.1(or proxyip) for serverip during p.addChar(ACCT_LOGIN_DATA)

-- idea 2012-06-15 : dumb proxy recording   tcp(vega) + udp(vega) + tcp(notes via netcat) + sleep times   in   .lua syntax (hexdump),
-- analysis / preprocessing to prettier lua in 2nd step, reuse hexdumps for server placeholders until contents are understood and can be modified

cProxyTCP_Bind = CreateClass()
cProxyTCP = CreateClass()
cProxyUDP = CreateClass()

gProxySteppers = {}

kProxyChannelName_Comment = "comment"

function StartProxyMode (port) 
	print("starting proxy mode port=",port)
	
	local hostip = GetHostByName(gProxyHost)
	gProxyHost_Addr = AtoN(hostip)
	print("hostip=",hostip,gProxyHost_Addr)
	assert(gProxyHost_Addr)
	
	cProxyTCP_Bind:New(port,"vega")
	cProxyTCP_Bind:New(gProxyPort_TCP_Acc,"accsrv")
	cProxyTCP_Bind:New(port+100,kProxyChannelName_Comment) -- optional netcat port for comments
	--~ for port = gProxyPort_UDP_Min,gProxyPort_UDP_Max do cProxyUDP:New(port) end  -- NOTE 2012-06-16 23:12 : currently it WORKS without udp, but client gets segfault when udp is enabled  ... prolly prevents client from listening on portnum
	
	gProxyAlive = true
	while gProxyAlive do 
		NetReadAndWrite()
		for o,v in pairs(gProxySteppers) do o:Step() end
		Client_USleep(10)
		-- ex VegaProxyOneConnection
	end
	print("end proxy mode, cleanup...")
	for o,v in pairs(gProxySteppers) do o:Destroy() end
	print("end proxy mode, cleanup done")
end


-- ***** ***** ***** ***** ***** proxy output

gProxyEvent_LastTime = nil
gProxyEvent_MinTimeForSleep = 50

function MyDumpFifo (fifo)
	local len = fifo:Size()
	local hexbytes = {}
	local ascibytes = {}
	for i=0,len-1 do 
		local c = fifo:PeekNetUint8(i)
		table.insert(hexbytes,sprintf("0x%02X",c)) 
		if (c == 0x0d) then 
			table.insert(ascibytes,"\\n") 
		elseif (c == 0x0a) then 
			table.insert(ascibytes,"\\r") 
		elseif (c >= 32 and c < 127) then 
			table.insert(ascibytes,sprintf("%c",c)) 
		else
			table.insert(ascibytes,"?") 
		end
	end
	return hexbytes,table.concat(ascibytes,"")
end

function MyDumpFifoToText (fifo)
	local hexbytes,ascibytes = MyDumpFifo(fifo)
	return ascibytes
end

function MyDumpFifoForNet (fifo)
	local hexbytes,ascibytes = MyDumpFifo(fifo)
	hexbytes = "{"..table.concat(hexbytes,",").."}"
	ascibytes = sprintf("%q",(ascibytes))
	return "Data("..fifo:Size()..","..hexbytes..","..ascibytes..")"
end

function ProxyEvent (prefix,name,paramtxt)
	-- print "sleep(x)" line in case there was a long pause before this event
	local t = Client_GetTicks()
	local dt = gLastProxyEventTime and (t - gLastProxyEventTime)
	gLastProxyEventTime = t
	if (dt and dt > gProxyEvent_MinTimeForSleep) then
		print("Sleep("..dt..")")
		print("")
	end
	
	print(prefix..name.."("..(paramtxt or "")..")")
end

-- ***** ***** ***** ***** ***** cProxyTCP_Bind
 
function cProxyTCP_Bind:Event (name,...) ProxyEvent(self.prefix,name,...) end

function cProxyTCP_Bind:Init (port,channelname) 
	gProxySteppers[self] = true
	channelname = channelname or "???"
	self.port = port
	self.channelname = channelname
	self.prefix = "TCPListener("..port..",'"..channelname.."'):"
	
	self:Event("Init")
	
	local timeout = Client_GetTicks() + 10*1000
	local listener
	repeat
		listener = NetListen(port)
		if (not listener) then print("cProxyTCP_Bind:Init: port listen bind fail, retrying...",port) Client_USleep(1 * 1000) end
	until listener or Client_GetTicks() > timeout 
	assert(listener,"cProxyTCP_Bind:Init: failed to bind to local port "..(port or 0))
	self.listener = listener
end

function cProxyTCP_Bind:Destroy () 
	self:Event("Destroy")
	if (self.listener) then print("cProxyTCP_Bind:Destroy",self.port) self.listener:Destroy() self.listener = nil end
end

function cProxyTCP_Bind:Step ()
	if (not self.listener) then return end
	while true do
		local newcon = self.listener:IsAlive() and self.listener:PopAccepted()
		if (newcon) then cProxyTCP:New(newcon,self.port,self.channelname) else return end
	end
end

-- ***** ***** ***** ***** ***** cProxyTCP

function cProxyTCP:Event (name,...) ProxyEvent(self.prefix,name,...) end

function cProxyTCP:Init (con,port,channelname)
	gProxySteppers[self] = true
	self.channelname = channelname
	self.prefix = "TCP("..port..",'"..channelname.."'):"
	self.con = con
	self.bIsComment = kProxyChannelName_Comment == self.channelname
	
	self:Event("Init")
	
	if (not self.bIsComment) then
		self.proxy_con = NetConnect(gProxyHost,port) -- port=8080->8080  else port = gProxyPort_TCP
	end
end

function cProxyTCP:Destroy ()
	self:Event("Destroy")
	if (self.con) then self.con:Destroy() self.con = nil  end
	if (self.proxy_con) then self.proxy_con:Destroy() self.proxy_con = nil end
end

function cProxyTCP:Step ()
	if (not self.con) then return end
	
	
	local fifo = CreateFIFO()
	
	self.con:Pop(fifo)
	if (fifo:Size() > 0) then
		self:Event("Recv",MyDumpFifoForNet(fifo))
		if (self.bIsComment) then 
			local txt = MyDumpFifoToText(fifo)
			if (string.find(txt,"quit")) then gProxyAlive = false end
		end
	end
	
	if (self.proxy_con) then
		if (fifo:Size() > 0) then
			self.proxy_con:StepOne()
			self.proxy_con:Push(fifo)
			self.proxy_con:StepOne()
		end
		
		fifo:Clear()
		self.proxy_con:Pop(fifo)
		if (fifo:Size() > 0) then
			self.con:StepOne()
			self.con:Push(fifo)
			self.con:StepOne()
			self:Event("Send",MyDumpFifoForNet(fifo))
		end
	end
	
	fifo:Destroy()
	
	if (not self.con:IsConnected()) then 
		self:Event("TerminateByClient")
		self:Destroy()
		return
	end
	if (self.proxy_con and (not self.proxy_con:IsConnected())) then 
		self:Event("TerminateByServer")
		self:Destroy()
		return
	end
end

-- ***** ***** ***** ***** ***** cProxyUDP

function cProxyUDP:Event (name,...) ProxyEvent(self.prefix,name,...) end

function cProxyUDP:Init (port) 
	gProxySteppers[self] = true
	self.prefix = "UDP("..port.."):"
	self.port = port
	
	self:Event("Init")
	
	self.socket_recv = Create_UDP_ReceiveSocket(port)
	self.socket_send = Create_UDP_SendSocket()
end

function cProxyUDP:Destroy () 
	self:Event("Destroy")
	if (self.socket_recv) then self.socket_recv:Destroy() self.socket_recv = nil end
	if (self.socket_send) then self.socket_send:Destroy() self.socket_send = nil end
end

function cProxyUDP:Step ()
	if (not self.socket_recv) then return end
		
	local fifo = CreateFIFO()
	local addr_client = 0x7f000001
	local addr_server = gProxyHost_Addr 
	assert(gProxyHost_Addr)
	
	local resultcode,remoteaddr = self.socket_recv:Receive(fifo)
	if (fifo:Size() > 0) then
		self:Event("Recv",MyDumpFifoForNet(fifo)..","..tostring(resultcode)..","..tostring(remoteaddr))
		
		--~ if (self.socket_send) then 
				--~ if (remoteaddr == addr_client) then local resultcode = self.socket_send:Send(addr_server,self.port,fifo)
			--~ elseif (remoteaddr == addr_server) then local resultcode = self.socket_send:Send(addr_client,self.port,fifo)
			--~ else
				--~ print("cProxyUDP:Step: got unknown address, don't know where to send",tostring(remoteaddr))
			--~ end
		--~ end
	end
	
	fifo:Destroy()
end

-- ***** ***** ***** ***** ***** end

