include paho-mqtt3c.e

atom ret

MQTTClient_global_init()

--Create handler to server A
atom client_a = MQTTClient_create("tcp://127.0.0.1:1883", "pub12345", 1, 1)
if client_a <= 0 then
	puts(1, "Error creating handler: "&MQTTClient_strerror(client_a)&"\n")
	abort(1)
end if

--Create handler to server B
atom client_b = MQTTClient_create("tcp://192.168.0.2:1883", "pub12345", 1, 1)
if client_b <= 0 then
	puts(1, "Error creating handler: "&MQTTClient_strerror(client_b)&"\n")
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

--Publish to server A
atom token_a = MQTTClient_publish(client_a, "test", "Test Message", 2, 0)
if token_a <= 0 then
	puts(1, "Error publishing: "&MQTTClient_strerror(token_a)&"\n")
	abort(1)
else
	--Wait
	ret = MQTTClient_waitForCompletion(client_a, token_a, 10)
	if ret != MQTTCLIENT_SUCCESS then
		puts(1, "Error waiting: "&MQTTClient_strerror(ret)&"\n")
	end if
end if

--Publish to server B
atom token_b = MQTTClient_publish(client_b, "test", "Test Message", 2, 0)
if token_b <= 0 then
	puts(1, "Error publishing: "&MQTTClient_strerror(token_b)&"\n")
	abort(1)
else
	--Wait
	ret = MQTTClient_waitForCompletion(client_b, token_b, 10)
	if ret != MQTTCLIENT_SUCCESS then
		puts(1, "Error waiting: "&MQTTClient_strerror(ret)&"\n")
	end if
end if


MQTTClient_disconnect(client_a, 10)
MQTTClient_disconnect(client_b, 10)
MQTTClient_destroy(client_a)
MQTTClient_destroy(client_b)
