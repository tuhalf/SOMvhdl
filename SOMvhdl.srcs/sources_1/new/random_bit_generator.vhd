----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.12.2020 15:31:29
-- Design Name: 
-- Module Name: random_bit_generator - Behavioral
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

entity random_bit_generator is
    generic(specCount : integer :=3);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           RandInput: in STD_LOGIC_VECTOR(5 downto 0);
           RandByte: out STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0);
           RandReady:out std_logic
           );
end random_bit_generator;

architecture Behavioral of random_bit_generator is
type sr is array(specCount-1 downto 0) of std_logic_vector (7 DOWNTO 0);
SIGNAL Currstate, Nextstate: sr;
SIGNAL feedback: std_logic_vector(specCount-1 downto 0);
signal init,countReady: std_logic;
signal initCount: integer;
signal count: std_logic_vector(7 downto 0);
type countStates is(first,second);
signal countState:countStates;
signal rndPrev: std_logic_vector(5 downto 0);
signal randUsedCount: natural;
constant maxRandUse: natural := 20;
begin
  --------------------------State Registers ----------------------
--StateReg: PROCESS (Clk,Rst)
--  BEGIN
--    IF (Rst = '1') THEN
--      RandReady<='0';
--    ELSIF (Clk = '1' AND Clk'EVENT) THEN
--      if init = '1' then
--        Currstate <= Nextstate;
--        RandReady<='1';
--      end if;
--    END IF;
--  END PROCESS;
---------------------- Init SRs ---------------------------
--------------------- Prepare random 8 bits -----------------------
  countPRP: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        countReady <= '0';
        count<= (OTHERS => '0');
        countState <= first;
        rndPrev<=(OTHERS => '0');
        initCount <= 0;
        init <= '0';
        RandReady<='0';
        Currstate<= (others => (others => '0'));
        randUsedCount<= 0;
      else
        if init = '0' then
          if countReady = '0' then
            case countState is
              when first =>
                if not(RandInput = rndPrev) then
                  count(5 downto 0)<= RandInput;
                  countState<=second;
                  rndPrev<=RandInput;
                end if;
              when second =>
                if not(RandInput = rndPrev) then
                  count(7 downto 6)<= RandInput(1 downto 0);
                  countState<=first;
                  rndPrev<=RandInput;
                  countReady<='1';
                end if;
              when others =>
                countState<=first;
            end case;
          else
            if initCount = specCount then
              init <= '1';
            else
              Currstate(initCount) <= count;
              initCount<= initCount+1;
              countReady<='0';
            end if;
          end if;
        elsif randUsedCount< maxRandUse then
          randUsedCount <= randUsedCount +1;
          Currstate <= Nextstate;
          RandReady<='1';
        else
          countReady <= '0';
          --count<= (OTHERS => '0');
          countState <= first;
          --rndPrev<=(OTHERS => '0');
          initCount <= 0;
          init <= '0';
          RandReady<='0';
          Currstate<= (others => (others => '0'));
          randUsedCount<= 0;
        end if;
      end if;
    end if;
      
  end process countPRP;

  feedbackG : for j in 0 to specCount-1 generate
    feedback(j) <= Currstate(j)(4) XOR Currstate(j)(3) XOR Currstate(j)(2) XOR Currstate(j)(0);
    Nextstate(j) <= feedback(j) & Currstate(j)(7 DOWNTO 1);
    RandByte((7+(j*8)) downto (0+(j*8))) <= Currstate(j);
  end generate;


end Behavioral;
