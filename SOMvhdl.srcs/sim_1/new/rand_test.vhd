----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.01.2021 23:29:11
-- Design Name: 
-- Module Name: rand_test - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rand_test is
--  Port ( );
end rand_test;

architecture Behavioral of rand_test is
    signal clk :  STD_LOGIC := '0';
    signal rst :  STD_LOGIC := '0';
    signal RandInput:  STD_LOGIC_VECTOR(5 downto 0);
    signal RandByte:  STD_LOGIC_VECTOR((7*3)+(3-1) downto 0);
    signal RandReady: std_logic;
constant half_period : time := 5 ns;
begin
    random_T: entity work.random_bit_generator
    port map( 
        clk =>  clk,
        rst =>  rst,
        RandInput   =>  RandInput,
        RandByte    =>  RandByte,
        RandReady   =>  RandReady
    );

    clk <= not clk after half_period;
    
    mainP: process
        
    begin
        rst<='1';
        wait for half_period*2;
        rst<='0';
        RandInput<="101100";
        wait for half_period*2;
        RandInput<="101001";
        wait for half_period*2;
        RandInput<="111011";
        wait for half_period*2;
        RandInput<="010010";
        wait for half_period*2;
        RandInput<="101001";
        wait for half_period*2;
        RandInput<="111011";
        wait for half_period*2;
        RandInput<="010010";
        wait for half_period*2;
        RandInput<="101001";
        wait for half_period*2;
        RandInput<="111011";
        wait for half_period*2;
        RandInput<="010010";
        wait until rst='1';
    end process mainP;

end Behavioral;
