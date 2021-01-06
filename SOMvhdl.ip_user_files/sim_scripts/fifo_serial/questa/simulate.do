onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fifo_serial_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_serial.udo}

run -all

quit -force
