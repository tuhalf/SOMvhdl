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
        MapHeight : positive:=100;
        specCount : positive:=3;
        --maxInput : positive:=100;
        rateSensetivity: positive:=1000;
        iterations: positive:=100;
        neighRad : positive:=100
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
           outReady : in STD_LOGIC;
           getOut : out STD_LOGIC;
           trainInput : out STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
           LNRate : out unsigned(n_bits(rateSensetivity)-1 downto 0);
           train : out STD_LOGIC;
           trainDoneM: in std_logic;

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
           TransmitData : out std_logic;

           btn1 : in std_logic
           );
end controller;

architecture Behavioral of controller is
    signal inputCount: natural;--unsigned(7 downto 0);
    type inputTable is array (254 downto 0) of STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal inputs : inputTable;

    signal currentInputReading : natural;--unsigned(7 downto 0);
    signal currentPosReading : natural;--unsigned(n_bits(specCount)-1 downto 0);
    signal inputMapDone : std_logic;

    type trainSteps is (waitS,bmu_wS,train_wS,bmuS,trainS,train_wS2,train_wS3);
    signal trainStep: trainSteps;
    signal curTX,curTY: natural;
    signal choosenInp: STD_LOGIC_VECTOR ((7*specCount)+(specCount-1) downto 0);
    signal curIters : natural;
    signal curRad : natural;

    signal trainDone: std_logic;

    signal outdone: std_logic;
    signal outX: natural;
    signal outY: natural;
    signal outS: natural;
    attribute ram_style: string;
    signal outGetFlag : std_logic;

    signal trainTo: natural;

    signal dataTDRV: std_logic_vector(7 downto 0);

    signal bmuXIn: natural;
    signal bmuYIn: natural;
    signal dTableO: natural;
    signal distTemp: natural;
    
    signal xMultiTemp:natural;
    signal yABSTemp:natural;

    signal ValueCurTmp: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);

    signal TransmitDataDRV: std_logic;

    signal outdrv: std_logic;
    signal indrv: std_logic;


begin


    -------- Process to read inputs from serial --------
    readInputsP: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                inputCount <= 0;
                inputRead   <='0';
                inputs  <= (others => (others => '0'));
                currentInputReading <= 0;
                currentPosReading   <= 0;
                inputMapDone        <= '0';
                indrv<= '0';
            else
                if inputReady='1' and indrv = '0' then
                    indrv<= '1';
                else
                    indrv<= '0';
                end if;
                if indrv = '1' and inputMapDone = '0' then
                    if inputCount = 0 then
                        inputCount <= to_integer(unsigned(input));
                        inputRead <= '1';
                        --dataTDRV<= std_logic_vector(to_unsigned(inputCount,8));
                        --TransmitDataDRV<='1';
                    elsif currentInputReading = 0 then
                        inputRead <= '1';
                        currentInputReading <= 1;
                    elsif currentInputReading <= inputCount and currentPosReading < specCount then
                        inputRead <= '1';
                        inputs(currentInputReading-1)((7+(currentPosReading*8)) downto (0+(currentPosReading*8))) <= input;
                        currentPosReading <= currentPosReading + 1;
                    elsif currentInputReading <= inputCount and currentPosReading = specCount then
                        inputRead <= '1';
                        --inputs(currentInputReading-1)((7+(currentPosReading*8)) downto (0+(currentPosReading*8))) <= input;
                        currentPosReading <= 0;
                        currentInputReading <= currentInputReading + 1;
                    elsif currentInputReading > inputCount then
                        inputMapDone <= '1';
                        inputRead <= '1';
                    end if;
                else
                    inputRead <= '0';
                end if;
            end if;
        end if;
    end process readInputsP;
    
    -----------bmu and train ------------
    trainP: process(clk)
    variable LNRateT: unsigned(n_bits(rateSensetivity)-1 downto 0);
    begin
        if rising_edge(clk) then
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
                trainTo <= 0;
                bmuXIn  <= 0;
                bmuYIn  <= 0;
                LNRateT := (others => '0');
                dTableO <= 0;
                distTemp<= 0;
                xMultiTemp<= 0;
                yABSTemp<= 0;
                curTX<= 0;
                curTY<= 0;

            else
                if inputMapDone = '1' and trainDone= '0' then
                    case trainStep is
                        when waitS =>
                            if curIters<iterations and mapReady = '1' then
                                choosenInp<= inputs( to_integer(unsigned(RandByte(1 downto 0))));--to_integer(inputCount));
                                if curIters = 0 then
                                    curRad<= MapHeight; 
                                else
                                    curRad<= curRad - 1;--(MapHeight/iterations);
                                end if;  
                                trainStep <= bmu_wS;
                            elsif curIters=iterations and mapReady = '1' then
                                trainDone<='1';
                            end if;
                        when bmuS =>
                                curTX<= 0;
                                curTY<= 0;
                                --startY<= 0;
                            --end if;

                            --if (bmuXIn+curRad)<(MapHeight-1) then
                            --    endTX<= bmuXIn+curRad;
                            --else
                            --end if;
                            --if (bmuYIn+curRad)<(MapHeight-1) then
                            --    endTY<= bmuYIn+curRad;
                            --else
                            --end if;
                            xMultiTemp<= abs(bmuXIn-0);
                            yABSTemp<=abs(bmuYIn-0);
                            trainStep <= train_wS;
                        when bmu_wS =>
                            if bmuReady='1' then
                                trainStep <= bmuS;
                                bmuXIn  <= bmuX;
                                bmuYIn  <= bmuY;  
                                FindBMU<= '0';
                            else
                                trainInput<= choosenInp;
                                FindBMU<= '1';
                            end if;
                        when trainS =>
                            train   <= '0';
                            if trainDoneM = '1' then
                                if curTY < MapHeight-1 then
                                    curTY <= curTY +1;
                                    xMultiTemp<=abs(bmuXIn-curTX);
                                    yABSTemp<=abs(bmuYIn-curTY+1);
                                    trainStep <= train_wS;
                                else
                                    if curTX < MapHeight-1 then
                                        curTX <= curTX +1;
                                        curTY <= 0;
                                        xMultiTemp<=abs(bmuXIn-(curTX+1));
                                        yABSTemp<=abs(bmuYIn);
                                        trainStep <= train_wS;
                                    else
                                        curIters <= curIters + 1;
                                        curTX<= 0;
                                        curTY<= 0;
                                        trainStep <= waitS;
                                    end if;
                                end if;
                                trainTo <= 0;
                            end if;
                        when train_wS =>
                            distTemp<=((yABSTemp+(xMultiTemp*100))-1);
                            trainStep <= train_wS2;
                        when train_wS2 =>
                            dTableO<= dLut(distTemp)*100;
                            trainStep <= train_wS3;
                        when train_wS3 =>
                            LNRateT := to_unsigned(lnRateLut((curIters+dTableO)-1),n_bits(rateSensetivity));
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
        end if;
    end process trainP;

    allDone<=trainDone;

    ----------output data-------
    out_P: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                outX <= 0;
                outY <= 0;
                outS <= 0;
                XPos_O    <= 0;
                YPos_O    <= 0;
                outdone <= '0';
                getOut<= '0';
                outGetFlag<= '0';
                TransmitDataDRV<='0';
                dataTDRV<= (others => '0');
                ValueCurTmp<=(others => '0');
                outdrv<= '0';
            else
                if btn1 = '1' and outdone = '0' then
                    outdrv<='1';
                elsif outdrv = '1' and outdone = '1' then 
                    outX <= 0;
                    outY <= 0;
                    outS <= 0;
                    XPos_O    <= 0;
                    YPos_O    <= 0;
                    outdone <= '0';
                    getOut<= '0';
                    outGetFlag<= '0';
                    TransmitDataDRV<='0';
                    dataTDRV<= (others => '0');
                    ValueCurTmp<=(others => '0');
                    outdrv<= '0';
                end if;
                if (trainDone = '1' or outdrv='1') and outdone = '0' then --mapReady = '1' and outdone <= '0' then--
                    if outS <= specCount then
                        if outS = 0 and outGetFlag = '0'then
                            XPos_O<= outX;
                            YPos_O<= outY;
                            TransmitDataDRV<='0';
                            getOut<= '1';
                            if outReady = '1' then
                                outGetFlag<= '1';
                                outS <= outS +1;
                                ValueCurTmp<=ValueCur;
                            end if;
                        elsif TransmitAvalible = '1' and TransmitDataDRV = '0' then
                            --dataTDRV<= RandByte((7+((outS-1)*8)) downto (0+((outS-1)*8)));
                            dataTDRV<= ValueCurTmp((7+((outS-1)*8)) downto (0+((outS-1)*8)));

                            --if outS =1 then
                            --    dataTDRV<= std_logic_vector(to_unsigned(outX,8));
                            --elsif outS =2 then
                            --    dataTDRV<= std_logic_vector(to_unsigned(outY,8));
                            --elsif outS =3 then
                            --    dataTDRV<= std_logic_vector(to_unsigned(outS,8));
                            --else 
                            --    dataTDRV<= std_logic_vector(to_unsigned(255,8));
                            --end if;
                            TransmitDataDRV<='1';
                            getOut<= '0';
                            outS <= outS +1;
                        else
                            getOut<= '0';
                            TransmitDataDRV<='0';
                        end if;
                    else
                        outGetFlag<= '0';
                        getOut<= '0';
                        outS <= 0;
                        TransmitDataDRV<='0';
                        if outY < MapHeight-1 then
                            outY <= outY + 1;
                        else
                            if outX < MapHeight-1 then
                                outX <= outX+1;
                                outY <= 0;
                            else
                                outdone <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process out_P;
    dataT <= dataTDRV;
    TransmitData<= TransmitDataDRV;
end Behavioral;
