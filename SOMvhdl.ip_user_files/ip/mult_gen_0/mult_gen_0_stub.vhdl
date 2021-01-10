-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
-- Date        : Sun Jan 10 17:13:55 2021
-- Host        : LAPTOP-50F2E74H running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/4ever/Documents/GitHub/SOMvhdl/SOMvhdl.srcs/sources_1/ip/mult_gen_0/mult_gen_0_stub.vhdl
-- Design      : mult_gen_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35ticsg324-1L
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mult_gen_0 is
  Port ( 
    CLK : in STD_LOGIC;
    A : in STD_LOGIC_VECTOR ( 9 downto 0 );
    B : in STD_LOGIC_VECTOR ( 7 downto 0 );
    P : out STD_LOGIC_VECTOR ( 17 downto 0 )
  );

end mult_gen_0;

architecture stub of mult_gen_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "CLK,A[9:0],B[7:0],P[17:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "mult_gen_v12_0_16,Vivado 2020.1.1_AR75516";
begin
end;
