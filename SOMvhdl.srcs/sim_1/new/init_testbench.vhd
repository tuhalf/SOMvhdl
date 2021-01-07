----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.12.2020 15:19:31
-- Design Name: 
-- Module Name: init_testbench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use work.utils.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity init_testbench is
--  Port ( );
end init_testbench;

architecture Behavioral of init_testbench is
    signal clk :  STD_LOGIC := '0';
    signal rst :  STD_LOGIC := '0';
    signal ready : STD_LOGIC:= '0';
    signal outReady : STD_LOGIC:= '0';
    signal XPos :  natural := 0;
    signal XPos_O :  natural := 0;
    signal YPos :  natural := 0;
    signal YPos_O :  natural := 0;
    signal ValueCur: STD_LOGIC_VECTOR((7*3)+(3-1) downto 0) := (others => '0');
    signal RandByte:  STD_LOGIC_VECTOR((7*3)+(3-1) downto 0)    := (others => '0');
    signal RandReady:std_logic  := '0';
    constant half_period : time := 5 ns;
    signal input:  STD_LOGIC_VECTOR((7*3)+(3-1) downto 0);    --input vector
    signal LNRate: unsigned(n_bits(1000)-1 downto 0);   --Learning and neighbourhood rate multiplied by 1000 to not mess with float 1000 = 0.1 1 =0.0001 
    signal train: std_logic;                                      --signal for  
    signal bmuX: natural;
    signal bmuY: natural;
    signal FindBMU: std_logic;
    signal bmuReady: std_logic;
    signal getOut: std_logic;
begin
    map_t: entity WORK.kmap 
    port map( 
        clk =>  clk,
        rst =>  rst,
        ready   => ready,
        XPos    =>  xPos,
        YPos    =>  yPos,
        XPos_O  => XPos_O,
        YPos_O  => YPos_O,
        getOut  =>  getOut,
        outReady => outReady,
        ValueCur    =>  ValueCur,
        RandByte    =>  RandByte,
        RandReady   =>  RandReady,
        input   =>  input,
        LNRate  =>  LNRate,
        train   =>  train,
        bmuX    =>  bmuX,
        bmuY    =>  bmuY,
        FindBMU =>  FindBMU,
        bmuReady    => bmuReady  
    );
    getOut <=(ready and not(outReady));

    clk <= not clk after half_period;
    
    mainP: process
        variable seed1, seed2: positive;  -- seed values for random generator
        variable rand: real;              -- random real-number value in range 0 to 1.0
        variable int_rand: integer;       -- random integer value in range 0..4095
        variable stim: STD_LOGIC_VECTOR((7*3)+(3-1) downto 0);  -- random 24-bit stimulus
    begin
        rst<='1';
        wait for half_period*2;
        rst<='0';
        wait for half_period*2;
        RandReady<='1';
        for i in 0 to (300*300) loop
            wait for half_period*2;
            uniform(seed1, seed2, rand);              -- generate random number
            -- rescale to 0..4096, find integer part
            int_rand := integer(trunc(rand*4096.0));
            -- convert to std_logic_vector
            stim := std_logic_vector(to_unsigned(int_rand, stim'length));
            RandByte<=stim;
        end loop;
        wait for half_period*2;
        RandReady<='0';
        wait until rst='1';
    end process mainP;

end Behavioral;
