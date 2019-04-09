namespace MQTT

include std/dll.e
include std/machine.e

atom paho_c_dll = open_dll("paho-mqtt3c.dll")
if paho_c_dll <= 0 then
	abort(1)
end if

--Constants--------------------------------------------------------------------
public constant default_connectOptions = {6,60,1,1,NULL,NULL,NULL,30,0,NULL,0,NULL,0,NULL,0,0,0,NULL,-1,0}

--Return Codes
public constant
	MQTTCLIENT_SUCCESS = 0,
	MQTTCLIENT_FAILURE = -1,
	MQTTCLIENT_DISCONNECTED = -3,
	MQTTCLIENT_MAX_MESSAGES_INFLIGHT = -4,
	MQTTCLIENT_BAD_UTF8_STRING = -5,
	MQTTCLIENT_NULL_PARAMETER = -6,
	MQTTCLIENT_TOPICNAME_TRUNCATED = -7,
	MQTTCLIENT_BAD_STRUCTURE = -8,
	MQTTCLIENT_BAD_QOS = -9,
	MQTTCLIENT_SSL_NOT_SUPPORTED = -10,
	MQTTCLIENT_BAD_MQTT_VERSION = -11,
	MQTTCLIENT_BAD_PROTOCOL = -14,
	MQTTCLIENT_BAD_MQTT_OPTION = -15,
	MQTTCLIENT_WRONG_MQTT_VERSION = -16

--Persistence Options
public constant 
	MQTTCLIENT_PERSISTENCE_DEFAULT = 0,
	MQTTCLIENT_PERSISTENCE_NONE = 1,
	MQTTCLIENT_PERSISTENCE_USER = 2

--Client Options
public enum
	CO_STRUCT_VERSION,
	CO_KEEPALIVEINTERVAL,
	CO_CLEANSESSION,
	CO_RELIABLE,
	CO_WILL,
	CO_USERNAME,
	CO_PASSWORD,
	CO_CONNECTTIMEOUT,
	CO_RETRYINTERVAL,
	CO_SSL,
	CO_SERVERURICOUNT,
	CO_SERVERURIS,
	CO_MQTTVERSION,
	CO_SERVERURI_RETURNED,
	CO_MQTTVERSION_RETURNED,
	CO_SESSIONPRESENT_RETURNED,
	CO_LEN,
	CO_DATA,
	CO_MAXINFLIGHTMESSAGES,
	CO_CLEANSTART

--C_Func-----------------------------------------------------------------------
atom xMQTTClient_connect = define_c_func(paho_c_dll, "+MQTTClient_connect", {C_HANDLE, C_POINTER}, C_INT)
atom xMQTTClient_create = define_c_func(paho_c_dll, "+MQTTClient_create", {C_HANDLE, C_POINTER ,C_POINTER, C_INT, C_INT}, C_INT)
--MQTTClient_createWithOptions
atom xMQTTClient_destroy = define_c_proc(paho_c_dll, "+MQTTClient_destroy", {C_HANDLE})
atom xMQTTClient_disconnect = define_c_func(paho_c_dll, "+MQTTClient_disconnect", {C_HANDLE, C_INT}, C_INT)
atom xMQTTClient_free = define_c_proc(paho_c_dll, "+MQTTClient_free", {C_POINTER})
atom xMQTTClient_freeMessage = define_c_proc(paho_c_dll, "+MQTTClient_freeMessage", {C_POINTER})
--MQTTClient_getPendingDeliveryTokens
atom xMQTTClient_getVersionInfo = define_c_func(paho_c_dll, "+MQTTClient_getVersionInfo", {}, C_POINTER)
atom xMQTTClient_global_init = define_c_proc(paho_c_dll, "+MQTTClient_global_init", {C_POINTER})
atom xMQTTClient_isConnected = define_c_func(paho_c_dll, "+MQTTClient_isConnected", {C_HANDLE}, C_INT)
atom xMQTTClient_publish = define_c_func(paho_c_dll, "+MQTTClient_publish", {C_HANDLE, C_POINTER, C_INT, C_POINTER, C_INT, C_INT, C_POINTER}, C_INT)
--MQTTClient_publishMessage
--MQTTClient_receive
atom xMQTTClient_setCallbacks = define_c_func(paho_c_dll, "+MQTTClient_setCallbacks", {C_HANDLE, C_POINTER, C_POINTER, C_POINTER, C_POINTER}, C_INT)
--MQTTClient_setDisconnected
--MQTTClient_setPublished
--MQTTClient_setTraceCallback
--MQTTClient_setTraceLevel
atom xMQTTClient_strerror = define_c_func(paho_c_dll, "+MQTTClient_strerror", {C_INT}, C_POINTER)
atom xMQTTClient_subscribe = define_c_func(paho_c_dll, "+MQTTClient_subscribe", {C_HANDLE, C_POINTER, C_INT}, C_INT)
--MQTTClient_subscribeMany
atom xMQTTClient_unsubscribe = define_c_func(paho_c_dll, "+MQTTClient_unsubscribe", {C_HANDLE, C_POINTER}, C_INT)
--MQTTClient_unsubscribeMany
atom xMQTTClient_waitForCompletion = define_c_func(paho_c_dll, "+MQTTClient_waitForCompletion", {C_HANDLE, C_INT, C_ULONG}, C_INT)
atom xMQTTClient_yield = define_c_proc(paho_c_dll, "+MQTTClient_yield", {})

-------MQTT v5
--MQTTClient_connect5
--MQTTClient_disconnect5
--MQTTClient_publish5
--MQTTClient_publishMessage
--MQTTClient_subscribe5
--MQTTClient_subscribeMany5
--MQTTClient_unsubscribe5
--MQTTClient_unsubscribeMany5
--MQTTProperties_add
--MQTTProperties_copy
--MQTTProperties_free
--MQTTProperties_getNumericValue
--MQTTProperties_getNumericValueAt
--MQTTProperties_getProperty
--MQTTProperties_getPropertyAt
--MQTTProperties_hasProperty
--MQTTProperties_propertyCount
--MQTTProperty_getType
--MQTTPropertyName
--MQTTReasonCode_toString
--MQTTResponse_free


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
	sequence context = peek_string(ptr_context)

	MQTTClient_freeMessage(ptr_client_message)
	MQTTClient_free(ptr_topicName)

	return call_func(user_messageArrived_callback, {topic, message, context})
end function

function default_connectionLost_dispacher(atom ptr_context, atom ptr_cause)
	sequence context = peek_string(ptr_context)
	sequence cause = peek_string(cause)
	
	return call_func(user_connectionLost_callback, {context, cause})
end function

function default_deliveryComplete_dispacher(atom ptr_context, atom token)
	sequence context = peek_string(ptr_context)
	
	return call_func(user_deliveryComplete_callback, {context, token})
end function

public atom messageArrived_dispacher = routine_id("default_messageArrived_dispacher")
public atom connectionLost_dispacher = routine_id("default_connectionLost_dispacher")
public atom deliveryComplete_dispacher = routine_id("default_deliveryComplete_dispacher")

--Helper Functions ------------------------------------------------------------




--MQTT Functions---------------------------------------------------------------
public function MQTTClient_create(sequence server_uri, sequence client_id, atom persistence_type = MQTTCLIENT_PERSISTENCE_NONE, atom persistence_context = NULL)
	atom hndl = allocate_data(4) 
	atom ptr_server_uri = allocate_string(server_uri) 
	atom ptr_client_id = allocate_string(client_id) 
 
	atom ret = c_func(xMQTTClient_create, {hndl, ptr_server_uri, ptr_client_id, persistence_type, persistence_context}) 
		if ret = MQTTCLIENT_SUCCESS then 
			ret = peek4u(hndl)
		end if 
	free(ptr_server_uri) 
	free(ptr_client_id) 
	free(hndl) 
	return ret 
end function

public function MQTTClient_connect(atom hndl, sequence options=default_connectOptions)
	atom MQTTClient_connectOptions = allocate_data(4*21)

	--TODO: Check for user/password on options and poke as nedded

	poke(MQTTClient_connectOptions,"MQTC")--must be MQTC
	poke4(MQTTClient_connectOptions+4, options)

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

public function MQTTClient_setCallbacks(atom hndl, atom rid_messageArrived = 0,  atom rid_deliveryComplete = 0, atom rid_connectionLost = 0, sequence context = "")
	atom ma = NULL
	atom cl = NULL
	atom dc = NULL
	atom ptr_context
	
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

	if not equal(context, "") then
		ptr_context = allocate_string(context)
	end if

	atom ret = c_func(xMQTTClient_setCallbacks, {hndl, ptr_context, cl, ma, dc})

	return ret
end function

public procedure MQTTClient_freeMessage(atom ptr_msg)
	atom ptr_struct = allocate(4)
	poke4(ptr_struct, ptr_msg)
	c_proc(xMQTTClient_freeMessage, {ptr_struct})
	free(ptr_struct)
end procedure

public procedure MQTTClient_free(atom pointer)
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
	atom ptr_hndl = allocate(4)
	poke4(ptr_hndl, hndl)

	c_proc(xMQTTClient_destroy, {ptr_hndl})
	free(ptr_hndl)
end procedure

public function MQTTClient_strerror(atom code)
	atom ret = c_func(xMQTTClient_strerror, {code})
	
	--Do not free after use
	return peek_string(ret)
end function

public procedure MQTTClient_yield()
	c_proc(xMQTTClient_yield, {})
end procedure

public function MQTTClient_publish(atom hndl, sequence topicName, sequence payload, atom qos, atom retained)
	atom ptr_topicName = allocate_string(topicName)
	atom ptr_payload = allocate_string(payload)
	atom ptr_token = allocate(4)

	atom ret = c_func(xMQTTClient_publish, {hndl, ptr_topicName, length(payload), ptr_payload, qos, retained, ptr_token})
	if ret = MQTTCLIENT_SUCCESS then 
		ret = peek4u(ptr_token)
	end if 

	free(ptr_topicName)
	free(ptr_payload)
	free(ptr_token)

	return ret
end function

public function MQTTClient_waitForCompletion(atom hndl, atom token, atom timeout)
	return c_func(xMQTTClient_waitForCompletion, {hndl, token, timeout})
end function

public function MQTTClient_isConnected(atom hndl)
	return c_func(xMQTTClient_isConnected, {hndl})
end function

public procedure MQTTClient_global_init(atom do_open_ssl = 0)
	atom MQTTClient_init_options = allocate_data(4*3)

	poke(MQTTClient_init_options,"MQTG") --must be MQTG
	poke4(MQTTClient_init_options+4, 0) --must be 0
	poke4(MQTTClient_init_options+8, do_open_ssl)

	c_proc(xMQTTClient_global_init, {MQTTClient_init_options})

	free(MQTTClient_init_options)
end procedure
