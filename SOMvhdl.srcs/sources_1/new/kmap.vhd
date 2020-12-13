----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.12.2020 15:31:29
-- Design Name: 
-- Module Name: map - Behavioral
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

entity kmap is
    generic(
        MapHeight : integer:=300;
        specCount : integer:=3
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           init: in STD_LOGIC;
           ready : out STD_LOGIC;
           XPos : in integer;
           YPos : in integer;
           ValueCur: out STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
           RandByte: in STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0)
           );
end kmap;

architecture Behavioral of kmap is
    type Specs is array(specCount-1 downto 0) of std_logic_vector (7 DOWNTO 0);
    type KMapT is array(MapHeight,MapHeight) of Specs;
    signal KMap : KMapT;
    outputT: STD_LOGIC_VECTOR((7*cCount)+(specCount-1) downto 0);
    readyDRV: STD_LOGIC;
begin
--------output-------
outputP: process(clk, rst)
begin
    if rst = '1' then
        outputT <= (others => '0');
    elsif rising_edge(clk) then
        for j in j to specCount-1 loop
            outputT((7+(j*8)) downto (0+(j*8))) = KMap(XPos,YPos)(j);
        end loop;
    end if;
end process outputP;

ValueCur <= outputT;

----------Init--------------
InitP: process(clk, rst)
begin
    if rst = '1' then
        readyDRV<='0';
        kmap<= ((others,others)=>(others=> (others=>'0')));
    elsif rising_edge(clk) then
        
    end if;
end process InitP;
ready<=readyDRV;

end Behavioral;
