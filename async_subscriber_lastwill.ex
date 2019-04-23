include paho-mqtt3c.e
include std/os.e

atom ret

MQTTClient_global_init()

--on message arrived
function message_arrived(sequence topicName, sequence message, sequence context, sequence raw_message)
	puts(1, "topic:   "& topicName &"\n")
	puts(1, "message: "& message &"\n")
	puts(1, "context: "& context &"\n")
	puts(1, "\n")

	return 1 --success
end function

--Create handler
atom client = MQTTClient_create("tcp://127.0.0.1:1883", "subwill12345", 1, 1)
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

options[CO_WILL] = default_willOptions
options[CO_WILL][WL_TOPIC] = "will_topic"
options[CO_WILL][WL_MESSAGE] = "This is a last will message"
options[CO_WILL][WL_RETAINED] = 0
options[CO_WILL][WL_QOS] = 2

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
