include paho-mqtt3c.e
include std/os.e
include std/text.e
include std/io.e

MQTTClient_setTraceLevel(MQTTCLIENT_TRACE_MAXIMUM)
MQTTClient_setTraceCallback(routine_id("trace_callback"))

atom trace_fn = open("trace.txt", "w")

procedure trace_callback(atom level, sequence message)
	puts(trace_fn, sprint(level) &": "& message &"\n")
	flush(trace_fn)
end procedure

atom ret

MQTTClient_global_init()

--on message arrived
function message_arrived(sequence topicName, sequence message, sequence context)
	puts(1, "topic:    "& topicName &"\n")
	puts(1, "message:  "& message[MA_PAYLOAD] &"\n")
	puts(1, "qos:      "& sprint(message[MA_QOS]) &"\n")
	puts(1, "retained: "& sprint(message[MA_RETAINED]) &"\n")
	puts(1, "context:  "& context &"\n")
	puts(1, "\n")

	return 1 --success
end function

--Create handler
atom client = MQTTClient_create("tcp://127.0.0.1:1883", "sub12345", 1, 1)
if client <= 0 then
	puts(1, "Error creating handler: "&MQTTClient_strerror(client)&"\n")
	abort(1)
end if

--Set Callbacks
ret = MQTTClient_setCallbacks(client, routine_id("message_arrived"), 0, 0, "Some optional context")
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error setting Callbacks: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Set connectOptions
sequence options = default_connectOptions
options[CO_USERNAME] = "my_user"
options[CO_PASSWORD] = "my_pass"

--Connect
ret = MQTTClient_connect(client, options)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error connecting: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

--Subscribe
ret = MQTTClient_subscribe(client, "test", 2)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error subscribing: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

puts(1, "Listening for messages\n")
while 1 do --wait for messages
	atom k = get_key()
	if k = 120 or k = 88 then  -- x or X
		puts(1, "Exiting\n")
		exit
	end if

	sleep(1)
end while

MQTTClient_unsubscribe(client, "test")
MQTTClient_disconnect(client, 10)
MQTTClient_destroy(client)

close(trace_fn)
