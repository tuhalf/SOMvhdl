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
        rateSensetivity: natural:=1000;
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
           LNRate: in unsigned(n_bits(rateSensetivity)-1 downto 0);   --Learning and neighbourhood rate multiplied by 1000 to not mess with float 1000 = 0.1 1 =0.0001 
           train: in std_logic;                                      --signal for training

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
    type bestVariables is array(3 downto 0) of natural;--x,y,dist,cycleCount
    type bestOfCoresT is array(coresCount-1 downto 0) of bestVariables;
    signal bestOfCores: bestOfCoresT;
    constant cycleCount: natural := ((MapHeight*MapHeight)/coresCount);
    signal coresDone: std_logic_vector(coresCount-1 downto 0);
    --constant j: integer := 0;
    signal init: STD_LOGIC;

    type toStates is (readyy,set,go);
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
   
--------output-------


ValueCur <= outputT;

----------Init--------------
InitP: process(clk, rst)
--variable x,y:std_logic_vector(n_bits(MapHeight-1)-1 downto 0);
--variable comb: std_logic_vector((n_bits(MapHeight-1)*2)-1 downto 0);
variable comb: natural;
variable kmapTemp: std_logic_vector(17 downto 0);
variable kmapT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
variable distance: natural;
begin
    if rst = '1' then
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
        outReady <= '0';
        addrb <= (others => '0'); 

        kmapPReady<= '0';
        kmapP<= (others => '0');

        bestOfCores(coresCount-1)<= (others => 0);
        coresDone(coresCount-1)<='0';
        trainDRVFlag <= '0';
    elsif rising_edge(clk) then
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
            comb:= (xCP*MapHeight)+(yCP);
            if kmapPReady='0' then
                wea(0) <= '0';

                case readTO is
                    when readyy =>
                    addrb <= std_logic_vector(to_unsigned(comb,14));
                    readTO <= set;
                    kmapPReady<='0';
                    when set =>
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
                for k in 0 to specCount-1 loop
                    kmapTemp:= std_logic_vector(unsigned(kmapP ((7+(k*8)) downto (0+(k*8)))) + ((LNRate*(unsigned(input((7+(k*8)) downto (0+(k*8)))) - unsigned(kmapP((7+(k*8)) downto (0+(k*8))))))/to_unsigned(rateSensetivity,n_bits(rateSensetivity))));
                    kmapT((7+(k*8)) downto (0+(k*8))) := kmapTemp(17 downto 10);
                end loop;
                wea(0) <= '1';
                addra<= std_logic_vector(to_unsigned(comb,14));
                dina <= kmapT;
                kmapPReady<='0';
                if train = '0' then
                    trainDRVFlag<= '0';
                end if;
            end if;    
        elsif getOut ='1' then
            wea(0) <= '0';
            --x:= std_logic_vector(to_unsigned(XPos_O,n_bits(MapHeight-1)));
            --y:= std_logic_vector(to_unsigned(YPos_O,n_bits(MapHeight-1)));
            --comb:= x&y;
            case readTO is
                when readyy =>
                outReady<= '0';
                comb:= (XPos_O*MapHeight)+(YPos_O);
                addrb <= std_logic_vector(to_unsigned(comb,14));
                readTO <= set;
                when set =>
                readTO <= go;
                outReady<= '0';
                when go =>
                outReady<= '1';
                outputT <= doutb;
                readTO <= readyy;
                when others =>
                readTO<=readyy;
            end case;
        elsif bmuReadyDRV = '1' then
            wea(0) <= '0';
            bmuReadyDRV <= '0';
            coresDone(coresCount-1)<= '0';
            bestOfCores(coresCount-1)<= (others => 0);
        elsif FindBMU ='1'then
            wea(0) <= '0';

            if bestOfCores(coresCount-1)(3)<cycleCount and coresDone(coresCount-1) = '0' then
                distance:= 0;
                comb:= ((bestOfCores(coresCount-1)(3)/MapHeight)*MapHeight)+((bestOfCores(coresCount-1)(3) rem MapHeight));
                if kmapPReady='0' then
                    case readTO is
                        when readyy =>
                        addrb <= std_logic_vector(to_unsigned(comb,14));
                        readTO <= set;
                        kmapPReady<='0';
                        when set =>
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
                        bestOfCores(coresCount-1)(1) <= (bestOfCores(coresCount-1)(3)/MapHeight);
                        bestOfCores(coresCount-1)(0) <= (bestOfCores(coresCount-1)(3) rem MapHeight);
                    end if;
                    bestOfCores(coresCount-1)(3) <= bestOfCores(coresCount-1)(3) +1;
                    kmapPReady<='0';
                    readTO<=readyy;
                end if;
            else
                coresDone(coresCount-1)<='1';
            end if;

        else
            wea(0) <= '0';
            readTO<=readyy;
        end if;
    end if;
end process InitP;
ready<=readyDRV;

    
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

    mestO: process(clk, rst)
    variable bestX,bestY,bestDist: natural;
    begin
        if rst = '1' then
            bestX := 0;
            bestY := 0;
            bestDist := 0;
            bmuX<= 0;
            bmuY<= 0;
        elsif rising_edge(clk) then
            if signed(coresDone) = to_signed(-1, coresDone'length) and FindBMU ='1' and train='0' and init = '0' then
                bestX := 0;
                bestY := 0;
                bestDist := 0;
                for o in 0 to coresCount-1 loop
                    if bestOfCores(o)(2) <= bestDist then
                        bestX:=bestOfCores(o)(0);
                        bestY:=bestOfCores(o)(1);
                        bestDist:=bestOfCores(o)(2);
                    end if;
                end loop;
                bmuX<=bestX;
                bmuY<=bestY;
                bmuReadyDRV<='1';
            end if;
        end if;
    end process mestO;
    bmuReady<=bmuReadyDRV;
end Behavioral;
