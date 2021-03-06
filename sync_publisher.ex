include paho-mqtt3c.e

atom ret

MQTTClient_global_init()

--Create handler
atom client = MQTTClient_create("tcp://127.0.0.1:1883", "pub12345", 1, 1)
if client <= 0 then
	puts(1, "Error creating handler: "&MQTTClient_strerror(client)&"\n")
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

--Publish
atom token = MQTTClient_publish(client, "test", "Test Message", 2, 0)
if token <= 0 then
	puts(1, "Error publishing: "&MQTTClient_strerror(token)&"\n")
	abort(1)
else
	--Wait
	ret = MQTTClient_waitForCompletion(client, token, 10)
	if ret != MQTTCLIENT_SUCCESS then
		puts(1, "Error waiting: "&MQTTClient_strerror(ret)&"\n")
	end if
end if

MQTTClient_disconnect(client, 10)
MQTTClient_destroy(client)
