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
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;
use work.expConsts.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller is
    generic(
        MapHeight : positive:=300;
        specCount : positive:=3;
        --maxInput : positive:=100;
        rateSensetivity: positive:=1000;
        iterations: positive:=100;
        neighRad : positive:=300
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;

           allDone : out STD_LOGIC;

           ValueCur: in STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
           mapReady : in STD_LOGIC;
           xPos : out natural;
           yPos : out natural;
           XPos_O : out natural;
           YPos_O : out natural;
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
end controller;

architecture Behavioral of controller is
    signal inputCount: unsigned(7 downto 0);
    type inputTable is array (254 downto 0) of STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal inputs : inputTable;

    signal currentInputReading : unsigned(7 downto 0);
    signal currentPosReading : unsigned(n_bits(specCount)-1 downto 0);
    signal inputMapDone : std_logic;

    type trainSteps is (waitS,bmu_wS,train_wS,bmuS,trainS);
    signal trainStep: trainSteps;
    signal curTX,curTY,endTX,endTY: natural;
    signal choosenInp: STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal curIters : natural;
    signal curRad : natural;
    signal startY : natural;

    signal trainDone: std_logic;

    signal outdone: std_logic;
    signal outX: natural;
    signal outY: natural;
    signal outS: natural;
    attribute ram_style: string;
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
            if inputReady = '1' and inputMapDone = '0' then
                if inputCount = 0 then
                    inputCount <= unsigned(input);
                    inputRead <= '1';
                elsif currentInputReading = 0 then
                    inputRead <= '1';
                    currentInputReading <= to_unsigned(1,8);
                elsif not(currentInputReading = inputCount) and not(currentPosReading = specCount-1) then
                    inputRead <= '1';
                    inputs(to_integer(currentInputReading)-1)((7+(to_integer(currentPosReading)*8)) downto (0+(to_integer(currentPosReading)*8))) <= std_logic_vector(unsigned(input));
                    currentPosReading <= currentPosReading + 1;
                elsif not(currentInputReading = inputCount) and currentPosReading = specCount-1 then
                    inputRead <= '1';
                    inputs(to_integer(currentInputReading)-1)((7+(to_integer(currentPosReading)*8)) downto (0+(to_integer(currentPosReading)*8))) <= std_logic_vector(unsigned(input));
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
    variable LNRateT: unsigned(n_bits(rateSensetivity)-1 downto 0);
    begin
        if rst = '1' then
            trainStep <= waitS;
            choosenInp<= (others => '0');
            trainInput<= (others => '0');
            curIters <= 0;
            curRad<=MapHeight;
            FindBMU<= '0';
            trainDone<='0';
            train   <= '0';
            xPos    <= 0;
            yPos    <= 0;
        elsif rising_edge(clk) then
            if inputMapDone = '1' and trainDone= '0' then
                case trainStep is
                    when waitS =>
                        if curIters<iterations and mapReady = '1' then
                            choosenInp<= inputs( to_integer(unsigned(RandByte)) mod to_integer(inputCount));
                            if curIters = 0 then
                                curRad<= MapHeight; 
                            else
                                curRad<= curRad - (MapHeight/iterations);
                            end if;  
                            trainStep <= bmu_wS;
                        else 
                            trainDone<='1';
                        end if;
                    when bmuS =>
                        -------
                        if (bmuX-curRad)>0 then
                            curTX<= bmuX-curRad;
                        else
                            curTX<= 0;
                        end if;

                        if (bmuY-curRad)>0 then
                            curTY<= bmuY-curRad;
                            startY<= bmuY-curRad;
                        else
                            curTY<= 0;
                            startY<= 0;
                        end if;

                        if (bmuX+curRad)<(MapHeight-1) then
                            endTX<= bmuX+curRad;
                        else
                            endTX<= MapHeight-1;
                        end if;
                        if (bmuY+curRad)<(MapHeight-1) then
                            endTY<= bmuY+curRad;
                        else
                            endTY<= MapHeight-1;
                        end if;
                        trainStep <= train_wS;
                    when bmu_wS =>
                        if bmuReady='1' then
                            trainStep <= bmuS;
                            FindBMU<= '0';
                        else
                            trainInput<= choosenInp;
                            FindBMU<= '1';
                        end if;
                    when trainS =>
                        train   <= '0';
                        if curTY < endTY then
                            curTY <= curTY +1;
                            trainStep <= train_wS;
                        elsif curTY = endTY then
                            if curTX < endTX then
                                curTX <= curTX +1;
                                curTY <= startY;
                                trainStep <= train_wS;
                            else
                                curIters <= curIters + 1;
                                trainStep <= waitS;
                            end if;
                        end if;
                    when train_wS =>
                        LNRateT := to_unsigned(lnRateLut((curIters+(dLut((abs(bmuX-curTX)+(abs(bmuY-curTY)*100))-1)*100))-1),n_bits(rateSensetivity));
                        LNRate  <= LNRateT;
                        train   <= '1';
                        xPos    <= curTX;
                        yPos    <= curTY;
                        trainInput <= choosenInp;
                        trainStep <= trainS;
                end case;
            else 
                trainStep <= waitS;
            end if;
        end if;
    end process trainP;

    allDone<=trainDone;

    ----------output data-------
    out_P: process(clk, rst)
    begin
        if rst = '1' then
            outX <= 0;
            outY <= 0;
            outS <= 0;
            XPos_O    <= 0;
            YPos_O    <= 0;
            outdone <= '0';
        elsif rising_edge(clk) then
            if trainDone = '1' and outdone <= '0' then
                if outS < specCount then
                    
                    if outS = 0 then
                        XPos_O<= outX;
                        YPos_O<= outY;
                        TransmitData<='0';
                        outS <= outS +1;
                    elsif TransmitAvalible = '1' then
                        dataT<= ValueCur((7+((outS-1)*8)) downto (0+((outS-1)*8)));
                        TransmitData<='1';
                    else
                        TransmitData<='0';
                    end if;
                else
                    TransmitData<='0';
                    if outY < MapHeight-1 then
                        outY <= outY + 1;
                        outS <= 0;
                    else
                        if outX < MapHeight-1 then
                            outX <= outX+1;
                            outS <= 0;
                        else
                            outdone <= '1';
                        end if;
                    end if;
                end if;
                XPos_O    <= 0;
                YPos_O    <= 0;
            end if;
        end if;
    end process out_P;
end Behavioral;
