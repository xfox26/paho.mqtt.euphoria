namespace MQTT

include std/dll.e
include std/machine.e

atom paho_c_dll = open_dll("paho-mqtt3c.dll")
if paho_c_dll <= 0 then
	abort(1)
end if

--Constants--------------------------------------------------------------------
public constant default_connectOptions = {6,60,1,1,NULL,NULL,NULL,30,0,NULL,0,NULL,0,NULL,0,0,0,NULL,-1,0}

public constant 
	MQTTCLIENT_PERSISTENCE_NONE = 1,
	MQTTCLIENT_SUCCESS = 0

--C_Func-----------------------------------------------------------------------
atom xMQTTClient_create = define_c_func(paho_c_dll, "+MQTTClient_create", {C_HANDLE, C_POINTER ,C_POINTER, C_INT, C_INT}, C_INT)
atom xMQTTClient_setCallbacks = define_c_func(paho_c_dll, "+MQTTClient_setCallbacks", {C_HANDLE, C_POINTER, C_POINTER, C_POINTER, C_POINTER}, C_INT)
atom xMQTTClient_connect = define_c_func(paho_c_dll, "+MQTTClient_connect", {C_HANDLE, C_POINTER}, C_INT)
atom xMQTTClient_subscribe = define_c_func(paho_c_dll, "+MQTTClient_subscribe", {C_HANDLE, C_POINTER, C_INT}, C_INT)
atom xMQTTClient_getVersionInfo = define_c_func(paho_c_dll, "+MQTTClient_getVersionInfo",{}, C_POINTER)
atom xMQTTClient_freeMessage = define_c_proc(paho_c_dll, "+MQTTClient_freeMessage", {C_POINTER})
atom xMQTTClient_free = define_c_proc(paho_c_dll, "+MQTTClient_free", {C_POINTER})

atom xMQTTClient_unsubscribe = define_c_func(paho_c_dll, "+MQTTClient_unsubscribe", {C_HANDLE, C_POINTER}, C_INT)
atom xMQTTClient_disconnect = define_c_func(paho_c_dll, "+MQTTClient_disconnect", {C_HANDLE, C_INT}, C_INT)
atom xMQTTClient_destroy = define_c_proc(paho_c_dll, "+MQTTClient_destroy", {C_HANDLE})

--Local variables
atom user_messageArrived_callback
atom user_deliveryComplete_callback
atom user_connectionLost_callback

--Local Functions--------------------------------------------------------------


--Defaults---------------------------------------------------------------------
function default_messageArrived_dispacher(atom ptr_context, atom ptr_topicName, atom topicLen, atom ptr_client_message)
--	peek({ptr_client_message,4}) --struct_id
--	peek4u(ptr_client_message+4) --struct_version
--	peek4u(ptr_client_message+8) --payloadlen
--	peek4u(ptr_client_message+12) --payload
--	peek4u(ptr_client_message+16) --qos
--	peek4u(ptr_client_message+20) --retained
--	peek4u(ptr_client_message+24) --dup
--	peek4u(ptr_client_message+28) --msgid
--	peek4u(ptr_client_message+32) --properties
--	peek4u(ptr_client_message+36) --properties
--	peek4u(ptr_client_message+40) --properties
--	peek4u(ptr_client_message+44) --properties

	sequence topic = peek_string(ptr_topicName)
	sequence message = peek({peek4u(ptr_client_message+12),peek4u(ptr_client_message+8)})

	--MQTTClient_freeMessage(ptr_client_message) --TODO: Dont work yet...
	MQTTClient_free(ptr_topicName)

	return call_func(user_messageArrived_callback, {topic, message}) --TODO: add context
end function

function default_connectionLost_dispacher(atom ptr_context, atom ptr_cause)
	--TODO: get context
	sequence context = ""
	sequence cause = peek_string(cause)
	
	
	return call_func(user_connectionLost_callback, {context, cause})
end function

function default_deliveryComplete_dispacher(atom ptr_context, atom token)
	--TODO
	sequence context = ""
	
	return call_func(user_deliveryComplete_callback, {context, token})
end function

public atom messageArrived_dispacher = routine_id("default_messageArrived_dispacher")
public atom connectionLost_dispacher = routine_id("default_connectionLost_dispacher")
public atom deliveryComplete_dispacher = routine_id("default_deliveryComplete_dispacher")

--Helper Functions ------------------------------------------------------------




--MQTT Functions---------------------------------------------------------------
public function MQTTClient_create(sequence server_uri, sequence client_id, atom persistence_type, atom persistence_context)
	atom hndl = allocate_data(4) 
	atom ptr_server_uri = allocate_string(server_uri) 
	atom ptr_client_id = allocate_string(client_id) 
 
	atom ret = c_func(xMQTTClient_create, {hndl, ptr_server_uri, ptr_client_id, MQTTCLIENT_PERSISTENCE_NONE, NULL}) 
		if ret = MQTTCLIENT_SUCCESS then 
			ret = peek4u(hndl) 
		else 
			ret = NULL 
		end if 
	free(ptr_server_uri) 
	free(ptr_client_id) 
	free(hndl) 
	return ret 
end function

public function MQTTClient_connect(atom hndl, sequence options=default_connectOptions)
	atom MQTTClient_connectOptions = allocate_data(4*21)

	poke(MQTTClient_connectOptions+4*0,"MQTC")--must be MQTC
	poke4(MQTTClient_connectOptions+4*1, options[1])--sctruct version
	poke4(MQTTClient_connectOptions+4*2, options[2])--keepAliveInterval
	poke4(MQTTClient_connectOptions+4*3, options[3])--cleansession
	poke4(MQTTClient_connectOptions+4*4, options[4])--reliable
	poke4(MQTTClient_connectOptions+4*5, options[5])--will
	poke4(MQTTClient_connectOptions+4*6, options[6])--username
	poke4(MQTTClient_connectOptions+4*7, options[7])--password
	poke4(MQTTClient_connectOptions+4*8, options[8])--connectTimeout
	poke4(MQTTClient_connectOptions+4*9, options[9])--retryInterval
	poke4(MQTTClient_connectOptions+4*10, options[10])--ssl
	poke4(MQTTClient_connectOptions+4*11, options[11])--serverURIcount
	poke4(MQTTClient_connectOptions+4*12, options[12])--serverURIs
	poke4(MQTTClient_connectOptions+4*13, options[13])--MQTTVersion
	poke4(MQTTClient_connectOptions+4*14, options[14])--serverURI
	poke4(MQTTClient_connectOptions+4*15, options[15])--MQTTVersion again
	poke4(MQTTClient_connectOptions+4*16, options[16])--sessionPresent
	poke4(MQTTClient_connectOptions+4*17, options[17])--len binary password length
	poke4(MQTTClient_connectOptions+4*18, options[18])--data binary password data
	poke4(MQTTClient_connectOptions+4*19, options[19]) --maxInflightMessages
	poke4(MQTTClient_connectOptions+4*20, options[20])--cleanstart

	atom ret = c_func(xMQTTClient_connect, {hndl, MQTTClient_connectOptions})

	return ret
end function

public function MQTTClient_subscribe(atom hndl, sequence topic, atom qos)
	atom ptr_topic = allocate_string(topic)

	atom ret = c_func(xMQTTClient_subscribe, {hndl, ptr_topic, qos})

	free(ptr_topic)
	
	return ret
end function

public function MQTTClient_getVersionInfo()
	atom ret = c_func(xMQTTClient_getVersionInfo, {})

	sequence ptrs = peek4u({ret,2})
	
	return {peek_string(ptrs[1]),peek_string(ptrs[2])}
end function

public function MQTTClient_setCallbacks(atom hndl, atom rid_messageArrived = 0,  atom rid_deliveryComplete = 0, atom rid_connectionLost = 0) --TODO add other callbacks
	atom ma = NULL
	atom cl = NULL
	atom dc = NULL
	
	if rid_messageArrived != 0 then
		user_messageArrived_callback = rid_messageArrived
		ma = call_back({'+', messageArrived_dispacher})
	end if

	if rid_deliveryComplete != 0 then
		user_deliveryComplete_callback = rid_deliveryComplete
		dc = call_back({'+', deliveryComplete_dispacher})
	end if

	if rid_connectionLost != 0 then
		user_connectionLost_callback = rid_connectionLost
		cl  = call_back({'+', connectionLost_dispacher})
	end if

	--TODO: context
	atom ret = c_func(xMQTTClient_setCallbacks, {hndl, dll:NULL, cl, ma, dc})

	return ret
end function

procedure MQTTClient_freeMessage(atom ptr_msg)
	c_proc(xMQTTClient_freeMessage, {ptr_msg})
end procedure

procedure MQTTClient_free(atom pointer)
	c_proc(xMQTTClient_free, {pointer})
end procedure

public function MQTTClient_unsubscribe(atom hndl, sequence topic)
	atom ptr_topic = allocate_string(topic)

	atom ret = c_func(xMQTTClient_unsubscribe, {hndl, ptr_topic})

	free(ptr_topic)

	return ret
end function

public function MQTTClient_disconnect(atom hndl, atom timeout)
	return c_func(xMQTTClient_disconnect, {hndl, timeout})
end function

public procedure MQTTClient_destroy(atom hndl)
	c_proc(xMQTTClient_destroy, {hndl})
end procedure
