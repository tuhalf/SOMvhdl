----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.01.2021 06:02:59
-- Design Name: 
-- Module Name: serial_test - Behavioral
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

entity serial_test is
--  Port ( );
end serial_test;

architecture Behavioral of serial_test is
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC;
    signal dataT : STD_LOGIC_VECTOR(7 downto 0);
    signal dataR : STD_LOGIC_VECTOR(7 downto 0);
    signal RX : STD_LOGIC;
    signal TX : std_logic;
    signal DataAvalible : std_logic;
    signal TransmitAvalible : std_logic;
    signal TransmitData : std_logic;
    signal ReadData : std_logic;
constant half_period : time := 5 ns;
begin

    asd:entity work.serial
        Port map( 
           clk => clk , 
           rst => rst , 
           dataT => dataT , 
           dataR => dataR , 
           RX => RX , 
           TX => TX , 
           DataAvalible => DataAvalible , 
           TransmitAvalible => TransmitAvalible , 
           TransmitData => TransmitData , 
           ReadData => ReadData 
           );

    clk <= not clk after half_period;
    rx <= tx;
    mainP: process
    begin
        rst<='1';
        wait for half_period*2;
        rst<='0';
        dataT <= "00000101";
        wait for half_period*2;
        TransmitData<='1';
        
        wait until rst='1';
    end process mainP;

end Behavioral;
