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
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity kmap is
    generic(
        MapHeight : integer:=100;
        specCount : integer:=3;
        rateSensetivity: natural:=100;
        coresCount: integer:= 1
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           ready : out STD_LOGIC;
           XPos : in natural;
           XPos_O : in natural;
           YPos : in natural;
           YPos_O : in natural;
           getOut : in STD_LOGIC;
           outReady : out STD_LOGIC;
           ValueCur: out STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
           RandByte: in STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
           RandReady:in std_logic;

           input: in STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);    --input vector
           LNRate: in unsigned(n_bits(rateSensetivity*10)-1 downto 0);   --Learning and neighbourhood rate multiplied by 1000 to not mess with float 1000 = 0.1 1 =0.0001 
           train: in std_logic;                                      --signal for training
           trainDoneM: out std_logic;

           bmuX: out natural;
           bmuY: out natural;
           FindBMU: in std_logic;
           bmuReady: out std_logic
           );
end kmap;

architecture Behavioral of kmap is
    signal outputT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal readyDRV: STD_LOGIC;
    signal bmuReadyDRV: STD_LOGIC;
    signal xCP,yCP : natural; 
    type bestVariables is array(5 downto 0) of natural;--x,y,dist,cycleCount,x,y
    signal bestOfCores: bestVariables;
    constant cycleCount: natural := ((MapHeight*MapHeight)/coresCount);
    signal coresDone: std_logic;
    signal init: STD_LOGIC;

    type toStates is (readyy,set,sure,go);
    signal readTO : toStates;
    signal writeTO : toStates;
    
    signal wea: std_logic_vector(0 downto 0);
    signal addra : STD_LOGIC_VECTOR(13 DOWNTO 0);
    signal dina : STD_LOGIC_VECTOR(23 DOWNTO 0);

    signal addrb : STD_LOGIC_VECTOR(13 DOWNTO 0);
    signal doutb : STD_LOGIC_VECTOR(23 DOWNTO 0);

    signal kmapP: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal kmapPReady: std_logic;

    signal trainDRVFlag: std_logic;

    signal outReadyDRV : STD_LOGIC;

    signal kmapTemp1: unsigned(34 downto 0);
    signal kmapTemp2: unsigned(34 downto 0);
    signal kmapTemp3: unsigned(34 downto 0);
    signal trainInputTemp1: unsigned(17 downto 0);
    signal trainInputTemp2: unsigned(17 downto 0);
    signal trainInputTemp3: unsigned(17 downto 0);

    signal trainMultiTemp1: unsigned(7 downto 0);
    signal trainMultiTemp2: unsigned(7 downto 0);
    signal trainMultiTemp3: unsigned(7 downto 0);

    type trainSt is (prep,prep2,finalize1,done);
    signal trainStates : trainSt;

    type pipeStates is (setP,setP2,oneP,twoP,threeP,fourP);
    signal multiplierST : pipeStates;

    signal multiA1: std_logic_vector(9 downto 0);
    signal multiB1: std_logic_vector(7 downto 0);
    signal multiP1: std_logic_vector(17 downto 0);

    signal multiA2: std_logic_vector(9 downto 0);
    signal multiB2: std_logic_vector(7 downto 0);
    signal multiP2: std_logic_vector(17 downto 0);

    signal multiA3: std_logic_vector(9 downto 0);
    signal multiB3: std_logic_vector(7 downto 0);
    signal multiP3: std_logic_vector(17 downto 0);

    constant dividerConst: unsigned(16 downto 0) := to_unsigned(137,17);

    signal isNegative1: std_logic;
    signal isNegative2: std_logic;
    signal isNegative3: std_logic;

    type bmuSteps is (setD,calcD,outD);
    signal bmuStep : bmuSteps;
    signal distanceIn: natural;


    
    
    COMPONENT blk_mem_gen_0
    PORT (
        clka : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        clkb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT mult_gen_0
    PORT (
        CLK : IN STD_LOGIC;
        A : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        B : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        P : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
    );
END COMPONENT;
    
begin

    rammm: blk_mem_gen_0
    PORT MAP (
    clka => clk,
    wea => wea,
    addra => addra,
    dina => dina,
    clkb => clk,
    addrb => addrb,
    doutb => doutb
    );

    multi1 : mult_gen_0
    PORT MAP (
        CLK => CLK,
        A => multiA1,
        B => multiB1,
        P => multiP1
    );
    multi2 : mult_gen_0
    PORT MAP (
        CLK => CLK,
        A => multiA2,
        B => multiB2,
        P => multiP2
    );
    multi3 : mult_gen_0
    PORT MAP (
        CLK => CLK,
        A => multiA3,
        B => multiB3,
        P => multiP3
    );
   
--------output-------


ValueCur <= outputT;

----------Init--------------
InitP: process(clk)
variable comb: natural;
variable inpTemp: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
variable kmapTemp: std_logic_vector(17 downto 0);
variable kmapT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
variable distance: natural;

begin
    if rising_edge(clk) then
        if rst = '1' then
            bmuX<= 0;
            bmuY<= 0;
            bmuReadyDRV<='0';
    
            readyDRV<='0';
            xCP<= 0;
            yCP<= 0;
            init <= '1';
    
            wea <= (others => '0');
            addra <= (others => '0');
            dina  <= (others => '0');
    
            outputT <= (others => '0');
            readTO <= readyy;
            outReadyDRV <= '0';
            addrb <= (others => '0'); 
    
            kmapPReady<= '0';
            kmapP<= (others => '0');
    
            bestOfCores<= (others => 0);
            coresDone<='0';
            trainDRVFlag <= '0';
            trainStates<= prep;
            kmapTemp1   <= (others => '0');
            kmapTemp2   <= (others => '0');
            kmapTemp3   <= (others => '0');
            trainInputTemp1  <= (others => '0');
            trainInputTemp2  <= (others => '0');
            trainInputTemp3  <= (others => '0');

            trainMultiTemp1  <= (others => '0');
            trainMultiTemp2  <= (others => '0');
            trainMultiTemp3  <= (others => '0');

            multiplierST<= setP;
            multiA1 <= (others => '0'); 
            multiB1 <= (others => '0');

            multiA2 <= (others => '0'); 
            multiB2 <= (others => '0');

            multiA3 <= (others => '0'); 
            multiB3 <= (others => '0');

            trainDoneM<= '0';

            isNegative1<= '0';
            isNegative2<= '0';
            isNegative3<= '0';

            bmuStep<= setD;
            distanceIn<=0;

        else
            if readyDRV = '0' then
                init <= '1';
            else
                init <= '0';
            end if;

            if train = '1' and trainDRVFlag ='0' then
                trainDRVFlag<= '1';
            end if;

            if bmuReadyDRV= '1' then
                bmuReadyDRV<= '0';
            end if;

            if init = '1' and RandReady = '1' then
                if not(yCP = MapHeight-1) then
                    --set
                        comb:= (xCP*MapHeight)+(yCP);
                        wea(0) <= '1';
                        addra<= std_logic_vector(to_unsigned(comb,14));
                        dina  <= RandByte;
                    --inc
                    yCP <= yCP + 1;
                elsif ycp = MapHeight-1 and not(xCP = MapHeight-1) then
                    --set
                        
                        comb:= (xCP*MapHeight)+(yCP);
                        wea(0) <= '1';
                        addra<= std_logic_vector(to_unsigned(comb,14));
                        dina  <= RandByte;
                    --inc
                    xCP <= xCP+1;
                    yCP <= 0;
                elsif ycp = MapHeight-1 and xCP = MapHeight-1 then
                    --sth
                        
                        comb:= (xCP*MapHeight)+(yCP);
                        wea(0) <= '1';
                        addra<= std_logic_vector(to_unsigned(comb,14));
                        dina  <= RandByte;
                    readyDRV<='1';
                else
                    wea(0) <= '0';
                end if;
            elsif trainDRVFlag = '1' then
                comb:= (XPos*MapHeight)+(YPos);
                inpTemp :=input;
                if kmapPReady='0' then
                    wea(0) <= '0';

                    case readTO is
                        when readyy =>
                        addrb <= std_logic_vector(to_unsigned(comb,14));
                        readTO <= set;
                        kmapPReady<='0';
                        when set =>
                        readTO <= sure;
                        kmapPReady<='0';
                        when sure =>
                        readTO <= go;
                        kmapPReady<='0';
                        when go =>
                        kmapP <= doutb;
                        readTO <= readyy;
                        kmapPReady<='1';
                        trainStates<=prep;
                        when others =>
                        readTO<=readyy;
                    end case;
                
                else
                    case trainStates is
                        when prep =>
                            trainDoneM <= '0';
                            case multiplierST is
                                when setP =>
                                    if unsigned(inpTemp(7 downto 0))  >unsigned(kmapP(7 downto 0)) then
                                        isNegative1<= '0';
                                    else 
                                        isNegative1<= '1';
                                    end if;
                                    if unsigned(inpTemp(15 downto 8)) >unsigned(kmapP(15 downto 8)) then
                                        isNegative2<= '0';
                                    else 
                                        isNegative2<= '1';
                                    end if;
                                    if unsigned(inpTemp(23 downto 16))>unsigned(kmapP(23 downto 16)) then
                                        isNegative3<= '0';
                                    else 
                                        isNegative3<= '1';
                                    end if;
                                    trainMultiTemp1<= to_unsigned(abs(to_integer(unsigned(inpTemp(7 downto 0))  ) - to_integer(unsigned(kmapP(7 downto 0)))),8);
                                    trainMultiTemp2<= to_unsigned(abs(to_integer(unsigned(inpTemp(15 downto 8)) ) - to_integer(unsigned(kmapP(15 downto 8)))),8);
                                    trainMultiTemp3<= to_unsigned(abs(to_integer(unsigned(inpTemp(23 downto 16))) - to_integer(unsigned(kmapP(23 downto 16)))),8);
                                    multiplierST<=setP2;
                                when setP2 =>
                                    multiA1 <= std_logic_vector(LNRate);
                                    multiB1 <= std_logic_vector(trainMultiTemp1);

                                    multiA2 <= std_logic_vector(LNRate);
                                    multiB2 <= std_logic_vector(trainMultiTemp2);

                                    multiA3 <= std_logic_vector(LNRate);
                                    multiB3 <= std_logic_vector(trainMultiTemp3);
                                    multiplierST<=oneP;
                                when oneP =>
                                    multiplierST<=twoP;
                                when twoP =>
                                    multiplierST<=threeP;
                                when threeP =>
                                    multiplierST<=fourP;
                                when fourP =>
                                    trainInputTemp1 <= unsigned(multiP1);
                                    trainInputTemp2 <= unsigned(multiP2);
                                    trainInputTemp3 <= unsigned(multiP3);
                                    trainStates<=prep2;
                                    multiplierST<=setP;
                                when others =>
                                    multiplierST<=setP;
                            end case;
                        when prep2 =>
                            trainDoneM <= '0';
                            kmapTemp1<= (trainInputTemp1*dividerConst);
                            kmapTemp2<= (trainInputTemp2*dividerConst);
                            kmapTemp3<= (trainInputTemp3*dividerConst);
                            trainStates<=finalize1;
                        when finalize1=>
                            trainDoneM <= '0';
                            if isNegative1 = '1' then
                                kmapT(7 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(kmapP(7 downto 0))) - to_integer(unsigned(kmapTemp1(34 downto 17))),8));
                            else
                                kmapT(7 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(kmapP(7 downto 0))) + to_integer(unsigned(kmapTemp1(34 downto 17))),8));
                            end if;
                            if isNegative2 = '1' then
                                kmapT(15 downto 8) := std_logic_vector(to_unsigned(to_integer(unsigned(kmapP(15 downto 8))) - to_integer(unsigned(kmapTemp2(34 downto 17))),8));
                            else
                                kmapT(15 downto 8) := std_logic_vector(to_unsigned(to_integer(unsigned(kmapP(15 downto 8))) + to_integer(unsigned(kmapTemp2(34 downto 17))),8));
                            end if;
                            if isNegative3 = '1' then
                                kmapT(23 downto 16) := std_logic_vector(to_unsigned(to_integer(unsigned(kmapP(23 downto 16))) - to_integer(unsigned(kmapTemp3(34 downto 17))),8));
                            else
                                kmapT(23 downto 16) := std_logic_vector(to_unsigned(to_integer(unsigned(kmapP(23 downto 16))) + to_integer(unsigned(kmapTemp3(34 downto 17))),8));
                            end if;
                            wea(0) <= '1';
                            addra<= std_logic_vector(to_unsigned(comb,14));
                            dina <= kmapT;
                            trainStates<=done;
                        when done =>
                            kmapPReady<='0';
                            wea(0) <= '0';
                            trainDoneM <= '1';
                            trainDRVFlag<= '0';
                            trainStates<=prep;
                        when others =>
                            trainStates<=prep;
                    
                    end case;
                end if;    
            elsif getOut ='1' and outReadyDRV = '0' then
                trainDoneM <= '0';
                wea(0) <= '0';
                case readTO is
                    when readyy =>
                    outReadyDRV<= '0';
                    comb:= (XPos_O*MapHeight)+(YPos_O);
                    addrb <= std_logic_vector(to_unsigned(comb,14));
                    readTO <= set;
                    when set =>
                    readTO <= sure;
                    outReadyDRV<= '0';
                    when sure =>
                    readTO <= go;
                    outReadyDRV<= '0';
                    when go =>
                    outReadyDRV<= '1';
                    outputT <= doutb;
                    readTO <= readyy;
                    when others =>
                    readTO<=readyy;
                end case;
            elsif outReadyDRV = '1' and getOut = '0' then
                trainDoneM <= '0';
                readTO<=readyy;
                outReadyDRV<= '0';
            elsif coresDone = '1' and FindBMU ='0' then
                trainDoneM <= '0';
                wea(0) <= '0';
                coresDone<= '0';
                bestOfCores(1)<= 0;
                bestOfCores(2)<= 800;
                bestOfCores(3)<= 0;
                bestOfCores(4)<= 0;
                bestOfCores(5)<= 0;
                bestOfCores(0)<= 0;
                kmapPReady<='0';
                readTO<=readyy;
            elsif FindBMU ='1'  and coresDone = '0'then
                trainDoneM <= '0';
                wea(0) <= '0';
                distance:= 0;
                if kmapPReady='0' then
                    case readTO is
                        when readyy =>
                        addrb <= std_logic_vector(to_unsigned(bestOfCores(3),14));
                        readTO <= set;
                        kmapPReady<='0';
                        when set =>
                        readTO <= go;
                        kmapPReady<='0';
                        when sure =>
                        readTO <= go;
                        kmapPReady<='0';
                        when go =>
                        kmapP <= doutb;
                        readTO <= readyy;
                        kmapPReady<='1';
                        bmuStep<=setD;
                        when others =>
                        readTO<=readyy;
                    end case;
                
                else
                    case bmuStep is
                        when setD =>
                            distance:= 0;
                            for cs in 0 to specCount-1 loop
                                distance := distance + abs(to_integer(unsigned(input((7+(cs*8)) downto (0+(cs*8))))) - to_integer(unsigned(kmapP((7+(cs*8)) downto (0+(cs*8))))));
                            end loop;
                            distanceIn<=distance;
                            bmuStep<= calcD;
                        when calcD =>
                            if distanceIn<bestOfCores(2) then
                                bestOfCores(2) <= distanceIn;
                                bestOfCores(1) <= bestOfCores(4);
                                bestOfCores(0) <= bestOfCores(5);
                            end if;
                            bmuStep<= outD;
                        when outD =>
                            bestOfCores(3) <= bestOfCores(3) +1;
                            if bestOfCores(5)<MapHeight-1 then
                                bestOfCores(5) <= bestOfCores(5) +1;
                            elsif bestOfCores(5)=MapHeight-1 and bestOfCores(4)<MapHeight-1 then
                                bestOfCores(4) <= bestOfCores(4) +1;
                                bestOfCores(5) <= 0;
                            elsif bestOfCores(5)=MapHeight-1 and bestOfCores(4)=MapHeight-1 then
                                trainDoneM <= '0';
                                wea(0) <= '0';
                                coresDone<='1';
                                bmuX<=bestOfCores(1);
                                bmuY<=bestOfCores(0);
                                bmuReadyDRV<='1';
                            end if;
                            bmuStep<= setD;
                            kmapPReady<= '0';
                            readTO <= readyy;

                        when others =>
                            bmuStep<= setD;
                            
                    
                    end case;
                    
                end if;
            else
                trainDoneM<='0';
                wea(0) <= '0';
            end if;
        end if;
    end if;
end process InitP;
ready<=readyDRV;
outReady <= outReadyDRV;
bmuReady<=bmuReadyDRV;
    
end Behavioral;
