----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.12.2020 23:40:23
-- Design Name: 
-- Module Name: controller - Behavioral
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

entity controller is
    generic(
        MapHeight : positive:=300;
        specCount : positive:=3;
        maxInput : positive:=100;
        rateSensetivity: positive:=1000
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;

           ValueCurr : in STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
           mapReady : in STD_LOGIC;
           xPos : out positive;
           yPos : out positive;

           trainInput : out STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
           LNRate : out unsigned(rateSensetivity'length-1 downto 0);
           train : out STD_LOGIC;

           inputRead : out STD_LOGIC;
           inputReady : in STD_LOGIC;
           input : in STD_LOGIC_VECTOR (7 downto 0)
           
           
           );
end controller;

architecture Behavioral of controller is
    signal inputCount: unsigned(7 downto 0);
    type inputTable is array (254 downto 0) of STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal inputs : inputTable;
    signal currentInputReading : unsigned(7 downto 0);
    signal currentPosReading : unsigned(specCount'length-1 downto 0);
    signal inputMapDone : std_logic;
begin

    -------- Process to read inputs from serial --------
    readInputsP: process(clk, rst)
    begin
        if rst = '1' then
            inputCount <= (others => '0');
            inputRead   <='0';
            inputs  <= (others => (others => '0'));
            currentInputReading <= (others => '0');
            currentPosReading   <= (others => '0');
            inputMapDone        <= '0';
        elsif rising_edge(clk) then
            if inputReady = '1' then
                if inputCount = 0 then
                    inputCount <= unsigned(input);
                    inputRead <= '1';
                elsif currentInputReading = 0 then
                    inputRead <= '1';
                    currentInputReading <= to_unsigned(1,8);
                elsif not(currentInputReading = inputCount) and not(currentPosReading = specCount-1) then
                    inputRead <= '1';
                    inputs(currentInputReading-1)((7+(currentPosReading*8)) downto (0+(currentPosReading*8))) <= std_logic_vector(unsigned(input));
                    currentPosReading <= currentPosReading + 1;
                elsif not(currentInputReading = inputCount) and currentPosReading = specCount-1 then
                    inputRead <= '1';
                    inputs(currentInputReading-1)((7+(currentPosReading*8)) downto (0+(currentPosReading*8))) <= std_logic_vector(unsigned(input));
                    currentPosReading <= (others => '0');
                    currentInputReading <= currentInputReading + 1;
                else
                    inputMapDone <= '1';
                    inputRead <= '0';
                end if;
            else
                inputRead <= '0';
            end if;
        end if;
    end process readInputsP;
    
    -----------bmu and train ------------
    trainP: process(clk, rst)
    begin
        if rst = '1' then
            
        elsif rising_edge(clk) then
            
        end if;
    end process trainP;

end Behavioral;
