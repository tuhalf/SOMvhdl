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
        MapHeight : integer:=300;
        specCount : integer:=3;
        rateSensetivity: natural:=1000;
        coresCount: integer:= 5
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           init: in STD_LOGIC;
           ready : out STD_LOGIC;
           XPos : in natural;
           YPos : in natural;
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
    type Specs is array(specCount-1 downto 0) of std_logic_vector (7 DOWNTO 0);
    type KMapT is array(MapHeight-1 downto 0,MapHeight-1 downto 0) of Specs;
    signal KMap : KMapT;
    signal outputT: STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
    signal readyDRV: STD_LOGIC;
    signal xCP,yCP : natural; 
    type bestVariables is array(3 downto 0) of natural;--x,y,dist,cycleCount
    type bestOfCoresT is array(coresCount-1 downto 0) of bestVariables;
    signal bestOfCores: bestOfCoresT;
    constant cycleCount: natural := ((MapHeight*MapHeight)/coresCount);
    signal coresDone: std_logic_vector(coresCount-1 downto 0);
    constant k: integer := 0;
begin
--------output-------
outputP: process(clk, rst)
begin
    if rst = '1' then
        outputT <= (others => '0');
    elsif rising_edge(clk) then
        for j in 0 to specCount-1 loop
            outputT((7+(j*8)) downto (0+(j*8))) <= KMap(XPos,YPos)(j);
        end loop;
    end if;
end process outputP;

ValueCur <= outputT;

----------Init--------------
InitP: process(clk, rst)
begin
    if rst = '1' then
        readyDRV<='0';
        kmap<= (others=>(others=>(others=>(others=>'0'))));
        xCP<= 0;
        yCP<= 0;
    elsif rising_edge(clk) then
        if init = '1' and readyDRV = '0' and RandReady = '1' then
            if not(yCP = MapHeight-1) then
                --set   
                for k in 0 to specCount-1 loop
                    KMap(xCP,yCP) (k) <= RandByte((7+(k*8)) downto (0+(k*8)));
                end loop;
                --inc
                yCP <= yCP + 1;
            elsif ycp = MapHeight-1 and not(xCP = MapHeight-1) then
                --set
                for k in 0 to specCount-1 loop
                    KMap(xCP,yCP) (k) <= RandByte((7+(k*8)) downto (0+(k*8)));
                end loop;
                --inc
                xCP <= xCP+1;
                yCP <= 0;
            elsif ycp = MapHeight-1 and xCP = MapHeight-1 then
                --sth
                for k in 0 to specCount-1 loop
                    KMap(xCP,yCP) (k) <= RandByte((7+(k*8)) downto (0+(k*8)));
                end loop;
                readyDRV<='1';
            end if;
        end if;
    end if;
end process InitP;
ready<=readyDRV;

---------Train---------
trainP: process(clk)
    variable kmapTemp: std_logic_vector(17 downto 0);
begin
    if rising_edge(clk) then
        if train = '1' then
            for k in 0 to specCount-1 loop
                kmapTemp:= std_logic_vector(unsigned(KMap(xCP,yCP) (k)) + ((LNRate*(unsigned(input((7+(k*8)) downto (0+(k*8)))) - unsigned(KMap(xCP,yCP) (k))))/to_unsigned(rateSensetivity,n_bits(rateSensetivity))));
                KMap(xCP,yCP) (k) <= kmapTemp(17 downto 10);
            end loop;
        end if;
    end if;
end process trainP;

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

--cores: for k in 0 to coresCount-1 generate
    core: process(clk, rst)
    variable distance: natural;
    begin
        if rst = '1' then
            bestOfCores(k)<= (others => 0);
            coresDone(k)<='0';
        elsif rising_edge(clk) then
            if FindBMU ='1' then
                if bestOfCores(k)(3)<cycleCount then
                    distance:= 0;
                    for cs in 0 to specCount-1 loop
                        distance := distance + abs(to_integer(unsigned(input((7+(cs*8)) downto (0+(cs*8))))) - to_integer(unsigned(KMap((bestOfCores(k)(3)/MapHeight),(bestOfCores(k)(3) rem MapHeight)) (cs))));
                    end loop;
                    if distance<bestOfCores(k)(2) then
                        bestOfCores(k)(2) <= distance;
                        bestOfCores(k)(1) <= (bestOfCores(k)(3)/MapHeight);
                        bestOfCores(k)(0) <= (bestOfCores(k)(3) rem MapHeight);
                    end if;
                    bestOfCores(k)(3) <= bestOfCores(k)(3) +1;
                else
                    coresDone(k)<='1';
                end if;
            end if;
        end if;
    end process core;
--end generate cores;

end Behavioral;
