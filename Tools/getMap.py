import serial
import csv
ser = serial.Serial('COM9') 
print(ser.name)
f = open('mapRand.csv', 'w',newline='')
with f:
    writer = csv.writer(f)
    for x in range(10000):
        a = int.from_bytes(ser.read(1),"big")
        b = int.from_bytes(ser.read(1),"big")
        c = int.from_bytes(ser.read(1),"big")
        
        writer.writerow([a,b,c])
print("doneRand")
packet = bytearray()
packet.append(0x03)
packet.append(0xdd)
packet.append(0xff)
packet.append(0x00)
packet.append(0x00)
packet.append(0xdd)
packet.append(0x00)
packet.append(0xff)
packet.append(0x00)
packet.append(0xdd)
packet.append(0x00)
packet.append(0x00)
packet.append(0xff)
packet.append(0xdd)
ser.write(packet)

f = open('map.csv', 'w',newline='')
with f:
    writer = csv.writer(f)
    for x in range(10000):
        a = int.from_bytes(ser.read(1),"big")
        b = int.from_bytes(ser.read(1),"big")
        c = int.from_bytes(ser.read(1),"big")
        
        writer.writerow([a,b,c])
print("done")
ser.close()