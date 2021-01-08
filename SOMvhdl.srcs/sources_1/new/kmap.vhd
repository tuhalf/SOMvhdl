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
    --type Specs is array(specCount-1 downto 0) of std_logic_vector (7 DOWNTO 0);
    --type KMapT is array(0 to (MapHeight*MapHeight)) of STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0); --(n_bits(MapHeight-1)*2)-1
    --signal KMap : KMapT;
    --attribute ram_style: string;
    --attribute ram_style of KMap : signal is "block";
    signal outputT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal readyDRV: STD_LOGIC;
    signal bmuReadyDRV: STD_LOGIC;
    signal xCP,yCP : natural; 
    type bestVariables is array(5 downto 0) of natural;--x,y,dist,cycleCount,x,y
    type bestOfCoresT is array(coresCount-1 downto 0) of bestVariables;
    signal bestOfCores: bestOfCoresT;
    constant cycleCount: natural := ((MapHeight*MapHeight)/coresCount);
    signal coresDone: std_logic_vector(coresCount-1 downto 0);
    --constant j: integer := 0;
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

    signal kmapTemp1: unsigned(31 downto 0);
    signal kmapTemp2: unsigned(31 downto 0);
    signal kmapTemp3: unsigned(31 downto 0);
    signal trainInputTemp1: unsigned(17 downto 0);
    signal trainInputTemp2: unsigned(17 downto 0);
    signal trainInputTemp3: unsigned(17 downto 0);

    type trainSt is (prep,prep2,finalize1,done);
    signal trainStates : trainSt;

    type pipeStates is (setP,oneP,twoP,threeP,fourP);
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

    constant dividerConst: unsigned(13 downto 0) := to_unsigned(163,14);
    
    
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
--variable x,y:std_logic_vector(n_bits(MapHeight-1)-1 downto 0);
--variable comb: std_logic_vector((n_bits(MapHeight-1)*2)-1 downto 0);
--variable bestX,bestY,bestDist: natural;
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
            --kmap<= (others=>(others=>(others=>(others=>'0'))));
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
    
            bestOfCores(coresCount-1)<= (others => 0);
            coresDone(coresCount-1)<='0';
            trainDRVFlag <= '0';
            trainStates<= prep;
            kmapTemp1   <= (others => '0');
            kmapTemp2   <= (others => '0');
            kmapTemp3   <= (others => '0');
            trainInputTemp1  <= (others => '0');
            trainInputTemp2  <= (others => '0');
            trainInputTemp3  <= (others => '0');

            multiplierST<= setP;
            multiA1 <= (others => '0'); 
            multiB1 <= (others => '0');

            multiA2 <= (others => '0'); 
            multiB2 <= (others => '0');

            multiA3 <= (others => '0'); 
            multiB3 <= (others => '0');

            trainDoneM<= '0';

        else
            if readyDRV = '0' then
                init <= '1';
            else
                init <= '0';
            end if;

            if train = '1' and trainDRVFlag ='0' then
                trainDRVFlag<= '1';
            end if;

            if init = '1' and RandReady = '1' then
                if not(yCP = MapHeight-1) then
                    --set   
                        --x:= std_logic_vector(to_unsigned(xCP,n_bits(MapHeight-1)));
                        --y:= std_logic_vector(to_unsigned(yCP,n_bits(MapHeight-1)));
                        --comb:= x&y;
                        comb:= (xCP*MapHeight)+(yCP);
                        wea(0) <= '1';
                        addra<= std_logic_vector(to_unsigned(comb,14));
                        dina  <= RandByte;
                    --inc
                    yCP <= yCP + 1;
                elsif ycp = MapHeight-1 and not(xCP = MapHeight-1) then
                    --set
                        --x:= std_logic_vector(to_unsigned(xCP,n_bits(MapHeight-1)));
                        --y:= std_logic_vector(to_unsigned(yCP,n_bits(MapHeight-1)));
                        --comb:= x&y;
                        comb:= (xCP*MapHeight)+(yCP);
                        wea(0) <= '1';
                        addra<= std_logic_vector(to_unsigned(comb,14));
                        dina  <= RandByte;
                    --inc
                    xCP <= xCP+1;
                    yCP <= 0;
                elsif ycp = MapHeight-1 and xCP = MapHeight-1 then
                    --sth
                        --x:= std_logic_vector(to_unsigned(xCP,n_bits(MapHeight-1)));
                        --y:= std_logic_vector(to_unsigned(yCP,n_bits(MapHeight-1)));
                        --comb:= x&y;
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
                            case multiplierST is
                                when setP =>
                                    multiA1 <= std_logic_vector(LNRate);
                                    multiB1 <= inpTemp(7 downto 0);

                                    multiA2 <= std_logic_vector(LNRate);
                                    multiB2 <= inpTemp(15 downto 8);

                                    multiA3 <= std_logic_vector(LNRate);
                                    multiB3 <= inpTemp(23 downto 16);

                                    multiplierST<=oneP;
                                when oneP =>
                                    multiplierST<=twoP;
                                when twoP =>
                                    multiplierST<=threeP;
                                when threeP =>
                                    multiplierST<=fourP;
                                when fourP =>
                                    inpTemp :=input;
                                    trainInputTemp1<= unsigned(multiP1) - unsigned(kmapP(7 downto 0));
                                    trainInputTemp2<= unsigned(multiP2) - unsigned(kmapP(15 downto 8));
                                    trainInputTemp3<= unsigned(multiP3) - unsigned(kmapP(23 downto 16));
                                    trainStates<=prep2;
                                    multiplierST<=setP;
                                when others =>
                                    multiplierST<=setP;
                            end case;
                        when prep2 =>
                            kmapTemp1<= (trainInputTemp1*dividerConst);
                            kmapTemp2<= (trainInputTemp2*dividerConst);
                            kmapTemp3<= (trainInputTemp3*dividerConst);
                            trainStates<=finalize1;
                        when finalize1=>
                            kmapT(7 downto 0) := std_logic_vector(unsigned(kmapP(7 downto 0)) + unsigned(kmapTemp1(31 downto 24)));--5);--
                            kmapT(15 downto 8) := std_logic_vector(unsigned(kmapP(15 downto 8)) + unsigned(kmapTemp2(31 downto 24)));--5);--
                            kmapT(23 downto 16) := std_logic_vector(unsigned(kmapP(23 downto 16)) + unsigned(kmapTemp3(31 downto 24)));--5);--
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
                wea(0) <= '0';
                --x:= std_logic_vector(to_unsigned(XPos_O,n_bits(MapHeight-1)));
                --y:= std_logic_vector(to_unsigned(YPos_O,n_bits(MapHeight-1)));
                --comb:= x&y;
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
                readTO<=readyy;
                outReadyDRV<= '0';
            elsif bmuReadyDRV = '1' then
                wea(0) <= '0';
                bmuReadyDRV <= '0';
                coresDone(coresCount-1)<= '0';
                bestOfCores(coresCount-1)<= (others => 0);
            elsif FindBMU ='1' and bestOfCores(coresCount-1)(3)<cycleCount and coresDone(coresCount-1) = '0'then
                wea(0) <= '0';
                distance:= 0;
                if kmapPReady='0' then
                    case readTO is
                        when readyy =>
                        addrb <= std_logic_vector(to_unsigned(bestOfCores(coresCount-1)(3),14));
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
                        when others =>
                        readTO<=readyy;
                    end case;
                
                else
                    for cs in 0 to specCount-1 loop
                        --x:= std_logic_vector(to_unsigned((bestOfCores(j)(3)/MapHeight),n_bits(MapHeight-1)));
                        --y:= std_logic_vector(to_unsigned((bestOfCores(j)(3) rem MapHeight),n_bits(MapHeight-1)));
                        --comb:= x&y;
                        distance := distance + abs(to_integer(unsigned(input((7+(cs*8)) downto (0+(cs*8))))) - to_integer(unsigned(kmapP((7+(cs*8)) downto (0+(cs*8))))));
                    end loop;
                    if distance<bestOfCores(coresCount-1)(2) or bestOfCores(coresCount-1)(3)=0 then
                        bestOfCores(coresCount-1)(2) <= distance;
                        bestOfCores(coresCount-1)(1) <= bestOfCores(coresCount-1)(4);
                        bestOfCores(coresCount-1)(0) <= bestOfCores(coresCount-1)(5);
                    end if;
                    bestOfCores(coresCount-1)(3) <= bestOfCores(coresCount-1)(3) +1;
                    if bestOfCores(coresCount-1)(5)<MapHeight then
                        bestOfCores(coresCount-1)(5) <= bestOfCores(coresCount-1)(5) +1;
                    else
                        bestOfCores(coresCount-1)(4) <= bestOfCores(coresCount-1)(4) +1;
                        bestOfCores(coresCount-1)(5) <= 0;
                    end if;
                    kmapPReady<='0';
                    readTO<=readyy;
                end if;
            elsif FindBMU ='1' and bestOfCores(coresCount-1)(3)>=cycleCount and coresDone(coresCount-1) = '0' then
                wea(0) <= '0';
                coresDone(coresCount-1)<='1';
            elsif coresDone(coresCount-1) = '1' and FindBMU ='1' then
                wea(0) <= '0';
                --for o in 0 to coresCount-1 loop
                --    if bestOfCores(o)(2) <= bestDist then
                --        bestX:=bestOfCores(o)(0);
                --        bestY:=bestOfCores(o)(1);
                --        bestDist:=bestOfCores(o)(2);
                --    end if;
                --end loop;
                bmuX<=bestOfCores(coresCount-1)(0);
                bmuY<=bestOfCores(coresCount-1)(1);
                bmuReadyDRV<='1';
            else
                trainDoneM<='0';
                wea(0) <= '0';
                readTO<=readyy;
            end if;
        end if;
    end if;
end process InitP;
ready<=readyDRV;
outReady <= outReadyDRV;
bmuReady<=bmuReadyDRV;
    
---------Train---------
--trainP: process(clk)
--    variable kmapTemp: std_logic_vector(17 downto 0);
--    variable kmapT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
--    variable kmapP: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
--    variable x,y:std_logic_vector(n_bits(MapHeight-1)-1 downto 0);
--    variable comb: std_logic_vector((n_bits(MapHeight-1)*2)-1 downto 0);
--begin
--    if rising_edge(clk) then
--        if train = '1' and init = '0' and FindBMU ='0'then
--            kmapP:= KMap(to_integer(unsigned(comb)));
--            for k in 0 to specCount-1 loop
--                x:= std_logic_vector(to_unsigned(XPos,n_bits(MapHeight-1)));
--                y:= std_logic_vector(to_unsigned(YPos,n_bits(MapHeight-1)));
--                comb:= x&y;
--                kmapTemp:= std_logic_vector(unsigned(kmapP ((7+(k*8)) downto (0+(k*8)))) + ((LNRate*(unsigned(input((7+(k*8)) downto (0+(k*8)))) - unsigned(kmapP((7+(k*8)) downto (0+(k*8))))))/to_unsigned(rateSensetivity,n_bits(rateSensetivity))));
--                kmapT((7+(k*8)) downto (0+(k*8))) := kmapTemp(17 downto 10);
--            end loop;
--                kmap(to_integer(unsigned(comb))) <= kmapT;
--        end if;
--    end if;
--end process trainP;

------- BMU ------------
--bmuF: process(clk, rst)
--    variable bx,by: natural;
--    variable distance,best_distance: natural;
--    variable inputIn: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
--
--begin
--    if rst = '1' then
--        
--    elsif rising_edge(clk) then
--        if FindBMU ='1' then
--            best_distance := specCount * 255;
--            bx := 0;
--            by := 0;
--            inputIn:= input;
--            for cx in 0 to MapHeight-1 loop
--                for cy in 0 to MapHeight-1 loop
--                    distance:= 0;
--                    for cs in 0 to specCount-1 loop
--                        distance := distance + abs(to_integer(unsigned(inputIn((7+(cs*8)) downto (0+(cs*8))))) - to_integer(unsigned(KMap(cx,cy) (cs))));
--                    end loop;
--                    if distance<best_distance then
--                        best_distance := distance;
--                        bx := cx;
--                        by := cy;
--                    end if;
--                end loop;
--            end loop;
--            bmuX <= bx;
--            bmuY <= by;
--        end if;
--    end if;
--end process bmuF;

--cores: for j in 0 to coresCount-1 generate
--    core: process(clk, rst)
--    --variable x,y:std_logic_vector(n_bits(MapHeight-1)-1 downto 0);
--    variable kmapT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
--    --variable comb: std_logic_vector((n_bits(MapHeight-1)*2)-1 downto 0);
--    variable comb: natural;
--    variable distance: natural;
--    begin
--        if rst = '1' then
--            bestOfCores(j)<= (others => 0);
--            coresDone(j)<='0';
--        elsif rising_edge(clk) then
--            if bmuReadyDRV = '1' then
--                coresDone(j)<= '0';
--                bestOfCores(j)<= (others => 0);
--            elsif FindBMU ='1' and train='0' and init = '0' then
--                if bestOfCores(j)(3)<cycleCount and coresDone(j) = '0' then
--                    distance:= 0;
--                    comb:= ((bestOfCores(j)(3)/MapHeight)*MapHeight)+((bestOfCores(j)(3) rem MapHeight));
--                    kmapT:= KMap(comb);
--                    for cs in 0 to specCount-1 loop
--                        --x:= std_logic_vector(to_unsigned((bestOfCores(j)(3)/MapHeight),n_bits(MapHeight-1)));
--                        --y:= std_logic_vector(to_unsigned((bestOfCores(j)(3) rem MapHeight),n_bits(MapHeight-1)));
--                        --comb:= x&y;
--                        distance := distance + abs(to_integer(unsigned(input((7+(cs*8)) downto (0+(cs*8))))) - to_integer(unsigned(kmapT((7+(cs*8)) downto (0+(cs*8))))));
--                    end loop;
--                    if distance<bestOfCores(j)(2) or bestOfCores(j)(3)=0 then
--                        bestOfCores(j)(2) <= distance;
--                        bestOfCores(j)(1) <= (bestOfCores(j)(3)/MapHeight);
--                        bestOfCores(j)(0) <= (bestOfCores(j)(3) rem MapHeight);
--                    end if;
--                    bestOfCores(j)(3) <= bestOfCores(j)(3) +1;
--                else
--                    coresDone(j)<='1';
--                end if;
--            end if;
--        end if;
--    end process core;
--end generate cores;
--
--    mestO: process(clk, rst)
--    variable bestX,bestY,bestDist: natural;
--    begin
--        if rst = '1' then
--            bestX := 0;
--            bestY := 0;
--            bestDist := 0;
--            bmuX<= 0;
--            bmuY<= 0;
--        elsif rising_edge(clk) then
--            if signed(coresDone) = to_signed(-1, coresDone'length) and FindBMU ='1' and train='0' and init = '0' then
--                bestX := 0;
--                bestY := 0;
--                bestDist := 0;
--                for o in 0 to coresCount-1 loop
--                    if bestOfCores(o)(2) <= bestDist then
--                        bestX:=bestOfCores(o)(0);
--                        bestY:=bestOfCores(o)(1);
--                        bestDist:=bestOfCores(o)(2);
--                    end if;
--                end loop;
--                bmuX<=bestX;
--                bmuY<=bestY;
--                bmuReadyDRV<='1';
--            end if;
--        end if;
--    end process mestO;
    
end Behavioral;
