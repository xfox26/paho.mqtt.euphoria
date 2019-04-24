include paho-mqtt3c.e
include std/os.e
include std/text.e

atom ret

MQTTClient_global_init()

--on message arrived
function message_arrived_a(sequence topicName, sequence message)
	puts(1, "Message from server A\n")
	puts(1, "topic:    "& topicName &"\n")
	puts(1, "message:  "& message[MA_PAYLOAD] &"\n")
	puts(1, "qos:      "& sprint(message[MA_QOS]) &"\n")
	puts(1, "retained: "& sprint(message[MA_RETAINED]) &"\n")
	puts(1, "\n")

	return 1 --success
end function

function message_arrived_b(sequence topicName, sequence message)
	puts(1, "Message from server B\n")
	puts(1, "topic:    "& topicName &"\n")
	puts(1, "message:  "& message[MA_PAYLOAD] &"\n")
	puts(1, "qos:      "& sprint(message[MA_QOS]) &"\n")
	puts(1, "retained: "& sprint(message[MA_RETAINED]) &"\n")
	puts(1, "\n")

	return 1 --success
end function

--Create handler for server A
atom client_a = MQTTClient_create("tcp://127.0.0.1:1883", "sub12345", 1, 1)
if client_a <= 0 then
	puts(1, "Error creating handler: "&MQTTClient_strerror(client_a)&"\n")
	abort(1)
end if

--Create handler for server B
atom client_b = MQTTClient_create("tcp://192.168.0.2:1883", "sub12345", 1, 1)
if client_a <= 0 then
	puts(1, "Error creating handler: "&MQTTClient_strerror(client_b)&"\n")
	abort(1)
end if

--Set Callbacks for server A
ret = MQTTClient_setCallbacks(client_a, routine_id("message_arrived_a"), 0, 0)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error setting Callbacks: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Set Callbacks for server B
ret = MQTTClient_setCallbacks(client_b, routine_id("message_arrived_b"), 0, 0)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error setting Callbacks: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Set connectOptions for server A
sequence options_a = default_connectOptions
options_a[CO_USERNAME] = "my_user"
options_a[CO_PASSWORD] = "my_pass"

--Set connectOptions for server B
sequence options_b = default_connectOptions
options_b[CO_USERNAME] = "my_user"
options_b[CO_PASSWORD] = "my_pass"

--Connect to server A
ret = MQTTClient_connect(client_a, options_a)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error connecting: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Connect to server B
ret = MQTTClient_connect(client_b, options_b)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error connecting: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if


--Subscribe to server A
ret = MQTTClient_subscribe(client_a, "test", 2)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error subscribing: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Subscribe to server B
ret = MQTTClient_subscribe(client_b, "test", 2)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error subscribing: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Listen
puts(1, "Listening for messages\n")
while 1 do --wait for messages
	atom k = get_key()
	if k = 120 or k = 88 then  -- x or X
		puts(1, "Exiting\n")
		
		exit
	end if

	sleep(1)
end while

MQTTClient_unsubscribe(client_a, "test")
MQTTClient_unsubscribe(client_b, "test")
MQTTClient_disconnect(client_a, 10)
MQTTClient_disconnect(client_b, 10)
MQTTClient_destroy(client_a)
MQTTClient_destroy(client_b)
