import serial
import csv
import time

ser = serial.Serial('COM9') 
print(ser.name)
serial_time = 1040000
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
start = time.time_ns()
gettime = False
print("Reading Output")
f = open('map.csv', 'w',newline='')
with f:
    writer = csv.writer(f)
    for x in range(10000):
        a = int.from_bytes(ser.read(1),"big")
        if gettime == False:
            end = time.time_ns()
            gettime = True
        b = int.from_bytes(ser.read(1),"big")
        c = int.from_bytes(ser.read(1),"big")
        
        writer.writerow([a,b,c])
print("Train Done. Time elapsed(s)",(end-start-serial_time)/1000000000)
ser.close()


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