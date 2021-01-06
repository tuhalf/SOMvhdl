----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.01.2021 04:29:06
-- Design Name: 
-- Module Name: cont_test - Behavioral
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
use work.utils.all;
entity cont_test is
--  Port ( );
generic(
        MapHeight : positive:=300;
        specCount : positive:=3;
        --maxInput : positive:=100;
        rateSensetivity: positive:=1000;
        iterations: positive:=100;
        neighRad : positive:=300
        );
end cont_test;

architecture Behavioral of cont_test is
    signal clk : STD_LOGIC := '0';
    signal rst :  STD_LOGIC := '0';
    signal allDone :  STD_LOGIC;
    signal ValueCur:  STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal mapReady : STD_LOGIC;
    signal xPos :  natural;
    signal yPos :  natural;
    signal XPos_O :  natural;
    signal YPos_O :  natural;
    signal outReady :  STD_LOGIC;
    signal getOut :  STD_LOGIC;
    signal trainInput :  STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal LNRate :  unsigned(n_bits(rateSensetivity)-1 downto 0);
    signal train :  STD_LOGIC;
    signal inputRead :  STD_LOGIC;
    signal inputReady :  STD_LOGIC;
    signal input :  STD_LOGIC_VECTOR (7 downto 0);
    signal bmuX:  natural;
    signal bmuY:  natural;
    signal FindBMU:  std_logic;
    signal bmuReady:  std_logic;
    signal RandReady: std_logic;
    signal RandByte:  STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal dataT :  STD_LOGIC_VECTOR(7 downto 0);
    signal TransmitAvalible :  std_logic;
    signal TransmitData :  std_logic;
    constant half_period : time := 5 ns;
COMPONENT controller
        Port ( 
            clk : in STD_LOGIC ;
            rst : in STD_LOGIC;

            allDone : out STD_LOGIC;

            ValueCur: in STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
            mapReady : in STD_LOGIC;
            xPos : out natural;
            yPos : out natural;
            XPos_O : out natural;
            YPos_O : out natural;
            outReady : in STD_LOGIC;
            getOut : out STD_LOGIC;
            trainInput : out STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
            LNRate : out unsigned(n_bits(rateSensetivity)-1 downto 0);
            train : out STD_LOGIC;

            inputRead : out STD_LOGIC;
            inputReady : in STD_LOGIC;
            input : in STD_LOGIC_VECTOR (7 downto 0);
            
            bmuX: in natural;
            bmuY: in natural;
            FindBMU: out std_logic;
            bmuReady: in std_logic;

            RandReady:in std_logic;
            RandByte: in STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);

            dataT : out STD_LOGIC_VECTOR(7 downto 0);
            TransmitAvalible : in std_logic;
            TransmitData : out std_logic
    
               );
    end COMPONENT;
begin
    controller_T: controller
        port map( 
            clk => clk,
            rst => rst,
            allDone => allDone,
            mapReady => mapReady,
            xPos => xPos,
            yPos => yPos,
            ValueCur    =>  ValueCur,
            trainInput => trainInput,
            TransmitAvalible => TransmitAvalible ,
            LNRate => LNRate,
            train => train,
            inputRead => inputRead,
            inputReady => inputReady,
            input => input,
            bmuX => bmuX,
            bmuY => bmuY,
            FindBMU => FindBMU,
            bmuReady => bmuReady,
            RandReady => RandReady,
            RandByte => RandByte,
            dataT   => dataT,
            TransmitData    => TransmitData,
            XPos_O  => XPos_O,
            YPos_O  => YPos_O,
            getOut  =>  getOut,
            outReady => outReady
        );

        clk <= not clk after half_period;

    mainP: process
    begin
        rst<='1';
        wait for half_period*2;
        rst<='0';
        input <= "00000101";
        wait for half_period*2;
        inputReady<='1';
        wait for half_period*2;
        inputReady<='1';
        wait for half_period*2;
        inputReady<='0';
        wait until rst='1';
    end process mainP;
end Behavioral;
