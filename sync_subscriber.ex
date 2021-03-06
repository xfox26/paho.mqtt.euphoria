include paho-mqtt3c.e
include std/os.e
include std/text.e

atom ret

MQTTClient_global_init()

--Create handler
atom client = MQTTClient_create("tcp://127.0.0.1:1883", "sub12345", 1, 1)

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

--Subscribe
ret = MQTTClient_subscribe(client, "test", 2)
if ret != MQTTCLIENT_SUCCESS then
	puts(1, "Error subscribing: "&MQTTClient_strerror(ret)&"\n")
	abort(1)
end if

puts(1, "Listening for messages\n")
while 1 do --wait for messages

	object received = MQTTClient_receive(client, 10)
	if not atom(received) then
		puts(1, "Topic   : "& received[RE_TOPICNAME] &"\n")
		puts(1, "Message : "& received[RE_MESSAGE] &"\n")
		puts(1, "Qos     : "& sprint(received[RE_QOS]) &"\n")
		puts(1, "Retained: "& sprint(received[RE_RETAINED]) &"\n")
		puts(1, "Dup     : "& sprint(received[RE_DUP]) &"\n")
	else
		if received < 0 then
			puts(1, "Error receiving: "&MQTTClient_strerror(received)&"\n")
		elsif received = 1 then
			puts(1, "Timeout waiting for message...\n")
		end if
	end if

	atom k = get_key()
	if k = 120 or k = 88 then  -- x or X
		puts(1, "Exiting\n")
		
		exit
	end if
end while

MQTTClient_unsubscribe(client, "test")
MQTTClient_disconnect(client, 10)
MQTTClient_destroy(client)
