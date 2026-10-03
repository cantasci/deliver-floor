You are working in the Traccar GPS tracking server repository (Java, package org.traccar.protocol).
Implement support for a new text-based tracker protocol called "R16H". Produce three Java files:
1. R16hProtocol.java - registers a UDP (datagram) server for the protocol (frames are delimited by '$').
2. R16hProtocolDecoder.java - decodes messages into position objects.
3. R16hProtocolDecoderTest.java - a unit test.

Protocol details:
- Login message: "@LINK,<imei>"  -> identifies the device; carries no position.
- Position message: "@GPSD,<imei>,<R|S>,<yyyymmdd>,<hhmmss>,<lat>,<N|S>,<lon>,<E|W>,<speed_kph>,<course>,<altitude_m>,<battery_percent>,<L|R>,<alarm_flag>"
  * R = real-time, S = stored/history record
  * lat/lon are decimal degrees with hemisphere letter, e.g. "01.34587,N" and "103.71993,E"
  * speed is km/h; altitude is a signed integer in metres; battery is percent; L/R is strap lock status; alarm flag is a short text code (may be empty)
Sample messages:
  @LINK,356823031235028
  @GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,

Be compact: no license headers, no explanatory comments, no prose. Create the three files in the repository.
