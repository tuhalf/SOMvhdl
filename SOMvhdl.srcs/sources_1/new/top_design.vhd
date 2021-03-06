----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.12.2020 21:39:47
-- Design Name: 
-- Module Name: top_design - Behavioral
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
use work.utils.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_design is
    generic(
        MapHeight : positive:=100;
        specCount : positive:=3;
        --maxInput : positive:=100;
        rateSensetivity: positive:=1000;
        iterations: positive:=100;
        neighRad : positive:=100
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           tx : out STD_LOGIC;
           rx : in STD_LOGIC;
           leds : out STD_LOGIC_VECTOR (6 downto 0);
           btn1 : in std_logic;
           random : in STD_LOGIC_VECTOR (5 downto 0));
end top_design;

architecture Behavioral of top_design is

    

    signal RandByte:  STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal RandReady: std_logic;

    signal ready :  STD_LOGIC;
    signal ValueCur:  STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal bmuX:  natural;
    signal bmuY:  natural;
    signal bmuReady:  std_logic ;

    signal allDone :  STD_LOGIC;
    signal xPos :  positive;
    signal yPos :  positive;
    signal trainInput :  STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal LNRate :  unsigned(n_bits(rateSensetivity)-1 downto 0);
    signal train :  STD_LOGIC;
    signal inputRead :  STD_LOGIC;
    signal FindBMU:  std_logic;

    signal dataR :  STD_LOGIC_VECTOR(7 downto 0);
    signal DataAvalible :  std_logic;
    signal TransmitAvalible :  std_logic;
    
    signal dataT : std_logic_vector(7 downto 0);
    signal TransmitData : std_logic;

    signal XPos_O : natural;
    signal YPos_O : natural;

    signal getOut : STD_LOGIC;
    signal outReady : STD_LOGIC;
    signal trainDoneM: std_logic;

begin

    leds(6)<=DataAvalible;
    leds(5)<=FindBMU;
    leds(4)<=train;
    leds(3)<=allDone;
    leds(2)<=bmuReady;
    leds(1)<=ready;
    leds(0)<=RandReady;

    serial_T: entity work.serial
        port map( 
            clk => clk ,
            rst => rst ,
            dataT =>  dataT,
            dataR => dataR ,
            RX =>  rx,
            TX =>  tx,
            DataAvalible => DataAvalible ,
            TransmitAvalible => TransmitAvalible ,
            TransmitData =>  TransmitData,
            ReadData => inputRead 
        );

    controller_T: entity work.controller
        port map( 
            clk => clk,
            rst => rst,
            allDone => allDone,
            mapReady => ready,
            xPos => xPos,
            yPos => yPos,
            ValueCur    =>  ValueCur,
            trainInput => trainInput,
            TransmitAvalible => TransmitAvalible ,
            LNRate => LNRate,
            train => train,
            inputRead => inputRead,
            inputReady => DataAvalible,
            input => dataR,
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
            outReady => outReady,
            trainDoneM => trainDoneM,
            btn1    => btn1
        );

    kmap_T: entity work.kmap
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
            input   =>  trainInput,
            LNRate  =>  LNRate,
            train   =>  train,
            bmuX    =>  bmuX,
            bmuY    =>  bmuY,
            FindBMU =>  FindBMU,
            trainDoneM => trainDoneM,
            bmuReady    => bmuReady  
        );
    random_T: entity work.random_bit_generator
        port map( 
            clk =>  clk,
            rst =>  rst,
            RandInput   =>  random,
            RandByte    =>  RandByte,
            RandReady   =>  RandReady
        );





end Behavioral;
