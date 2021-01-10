
![](https://img.shields.io/github/stars/tuhalf/SOMvhdl.svg) ![](https://img.shields.io/github/forks/tuhalf/SOMvhdl.svg)![](https://img.shields.io/github/release/tuhalf/SOMvhdl.svg) ![](https://img.shields.io/github/issues/tuhalf/SOMvhdl.svg)
# SOMVhdl - Self Organizing Map Implementation On FPGA

A simple and scaleable Self Organizing Map implementation written in VHDL. Tested on ARTYA7-35T board.

## Tests
#### Test with 10 color inputs
![](https://raw.githubusercontent.com/tuhalf/SOMvhdl/main/Docs/ScreenShots/TenColorsTest.png)
#### Test with 50 color inputs
![](https://raw.githubusercontent.com/tuhalf/SOMvhdl/main/Docs/ScreenShots/50ColorsTest.png)

## Features
- Any number of data entries via serial interface. (Limit is set to 254 but can be changed)
- Results output via serial interface.
- Flexible iteration and specification counts and map sizes.
- Non-repetitive psudo random map generation with Attiny85 extention.
- Test button to get output before training.

## How To Use
#### Installation
You can use Pre-Generated Bitstreams, which are avalible in releases or can generate from source. 
##### ! To generate random map to start, you have to connect a 6 bit random bit generator to JA pins. You can use an Attiny85 or an Arduino for this. The necesary codes are in /Tools/RandomInit_attiny85 folder.
To make sure random map generation works fine, uncomment the commented lines on getMap.py and press BTN1 while running the code. Random output looks something like that:
![](https://raw.githubusercontent.com/tuhalf/SOMvhdl/main/Docs/ScreenShots/RandomMap.png)

#### Training 
To train inputs from CSV files, you can use the Python code in /Tools/getMap.py It reads the output from Train.csv and writes outputs to map.csv. 
#### Visualization 
For visualization, I used the idea from [Isidroc SOMcpp Project][1] Using his R script, you can easily visualize the generated map. You can find the script in /Tools/PlotColorMartix.R 
![](https://raw.githubusercontent.com/tuhalf/SOMvhdl/main/Docs/ScreenShots/R.png)

## Implementation Summary
#### Timing
                    
WNS  | WHS
------------- | -------------
0,21  | 0,04
#### Place Design
| LUT  | FF | BRAM  | DSP | I/O  | BUFG |
| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |
| 19,36  | 18,14  | 34,00  | 6,67  | 8,57  | 3,13  |
## To do
- Divide map into smaller parts to do parallel processing.

### End
[1]: https://github.com/isidroc/SOMcpp "Isidroc's SOMcpp project"
