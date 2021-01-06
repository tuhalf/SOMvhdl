onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+fifo_serial -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.fifo_serial xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {fifo_serial.udo}

run -all

endsim

quit -force
