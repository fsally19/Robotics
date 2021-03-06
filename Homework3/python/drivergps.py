#!/usr/bin/env python
# -*- coding: utf-8 -*-
# for NBOSI-CT sensor (seabed 125)

import sys
import lcm
import time
import serial
import utm
from struct_gps import gps_t

class gps(object):
    def __init__(self, port_name):
        self.port = serial.Serial(port_name, 4800, timeout=1.)  # 4800-N-8-1
        self.lcm = lcm.LCM("udpm://?ttl=12")
        self.packet = gps_t()
        """while True:
            print 'gps: Initialization'
            line = self.port.readline()
            try:
                vals = [float(x) for x in line.split(' ')]
            except:
                vals = 0
            if len(vals) < 4:
                self.port.write("d33\r")  # toggle on the salinity
                time.sleep(0.2)
                self.port.flush()
            else:
                break"""
	return 

    def readloop(self):
	print "Initializing"	
	while True:
	   info = self.port.readline() #entire GPGGA line
	   values = info.split(",")  #breaks down GPGGA line
	   if '$GPGGA' == values[0]: #when GPGGA values are equal to zero, execute code
		self.packet.timestamp= (int(values[1][0:2])*3600000) + (int(values[1][2:4])*60000) + (int(values[1][4:6])*1000) + (int(values[1][7:10])) 			#converts timestamp to seconds
		self.packet.latitude = float(values[2])
		self.packet.latsign = str(values[3])
		self.packet.longitude = float(values[4])
		self.packet.longsign = str (values[5])
		self.packet.HDOP = float(values[8])
		self.packet.altitude = float(values[9])
		self.packet.altunit = str (values[10])
		self.lcm.publish("gps", self.packet.encode())

		
		if(str(values[3]) == "N"):
			latitude = float(int(values[2][0:2]) + float(values[2][2:9])/60) #if the latitude is North then it remains positive
		elif(str(values[3]) == "S"):
			latitude = -1*(float(int(values[2][0:2]) + float(values[2][2:9])/60)) #if the latitude is South it turns negative
		if(str(values[5]) == "W"):
			longitude = -1*(float(int(values[4][0:3]) + float(values[4][3:10])/60)) #if the latitude is West it turns negative
		elif(str(values[5]) == "E"):
			longitude = float(int(values[4][0:3]) + float(values[4][3:10])/60) #if the latitude is East it remains

		utm_data = utm.from_latlon(float(values[2]), float(values[4])) #converts data
		self.packet.easting = float(utm_data[0])
		self.packet.northing = float(utm_data[1])
		self.packet.zone = int(utm_data[2])
		self.packet.zonelet = str(utm_data[3])
		
 
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Usage: %s <serial_port>\n" % sys.argv[0]
        sys.exit(0)
    GPSname = gps(sys.argv[1])
    GPSname.readloop()
