import serial
import csv
ser = serial.Serial('COM9') 
print(ser.name)
#f = open('mapRand.csv', 'w',newline='')
#with f:
#    writer = csv.writer(f)
#    for x in range(10000):
#        a = int.from_bytes(ser.read(1),"big")
#        b = int.from_bytes(ser.read(1),"big")
#        c = int.from_bytes(ser.read(1),"big")
#        
#        writer.writerow([a,b,c])
#print("doneRand")
packet = bytearray()
with open('train4.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    csvList=list(csv_reader)
    lenO = len(csvList)
    packet.append(lenO)
    print(" number of items: ",lenO )
    for row in csvList:
        for col in row:
            packet.append(int(col))
            #print(int(col))

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