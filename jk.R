library(serial)

con <- serialConnection(name = "testcon",port = "COM9"
                       ,mode = "9600,n,8,1"
                       ,translation = "crlf")
# let's open the serial interface

open(con)

# write some stuff
write.serialConnection(con,"Hello World!")

# read, in case something came in
read.serialConnection(con)

# show summary
summary(con)

# close the connection
close(con)

install.packages("serial")