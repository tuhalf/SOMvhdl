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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity init_testbench is
--  Port ( );
end init_testbench;

architecture Behavioral of init_testbench is
    signal clk :  STD_LOGIC;
    signal rst :  STD_LOGIC;
    signal init:  STD_LOGIC;
    signal ready : STD_LOGIC;
    signal XPos :  integer;
    signal YPos :  integer;
    signal ValueCur: STD_LOGIC_VECTOR((7*3)+(3-1) downto 0);
    signal RandByte:  STD_LOGIC_VECTOR((7*3)+(3-1) downto 0);
    signal RandReady:std_logic;
    constant half_period : time := 5 ns;
begin
    map_t: entity work.kmap 
        generic map(
            MapHeight => 300,
            specCount => 3
            );
        Port map( 
               clk      => clk,
               rst      => rst,
               init     => init,
               ready    => ready,
               XPos     => XPos,
               YPos     => YPos,
               ValueCur => ValueCur,
               RandByte => RandByte,
               RandReady=> RandReady
               );
    end entity work.kmap;

    clk <= not clk after half_period;

end Behavioral;
