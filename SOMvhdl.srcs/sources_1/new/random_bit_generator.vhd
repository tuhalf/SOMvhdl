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
           RandByte: out STD_LOGIC_VECTOR((7*specCount)+(specCount-1) downto 0)
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
begin
  --------------------------State Registers ----------------------
StateReg: PROCESS (Clk,Rst)
  BEGIN
    IF (Rst = '1') THEN
      initCount <= 0;
      init <= '1';
    ELSIF (Clk = '1' AND Clk'EVENT) THEN
      if init = '0' then
        for k in 0 to specCount-1 loop
          Currstate(k) <= Nextstate(k);
        end loop;
      end if;
    END IF;
  END PROCESS;
---------------------- Init SRs ---------------------------
  initP: PROCESS (CLK)
    BEGIN
      if (Clk = '1' AND Clk'EVENT) then
        if initCount = specCount then
          init <= '0';
          initCount <=0;
        elsif(init = '1' and countReady = '1') then
          Currstate(initCount) <= count;
          initCount<= initCount+1;
          countReady<='0';
        end if;
    end if;
  end process;
--------------------- Prepare random 8 bits -----------------------
  countPRP: process(clk, rst)
  begin
    if rst = '1' then
      countReady <= '0';
      count<= (OTHERS => '0');
      countState <= first;
      rndPrev<=(OTHERS => '0');
    elsif (Clk = '1' AND Clk'EVENT) then
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
          
      
      end case;
    end if;
  end process countPRP;

  feedbackG : for j in 0 to specCount-1 generate
    feedback(j) <= Currstate(j)(4) XOR Currstate(j)(3) XOR Currstate(j)(2) XOR Currstate(j)(0);
    Nextstate(j) <= feedback(j) & Currstate(j)(7 DOWNTO 1);
    RandByte((7+(j*8)) downto (0+(j*8))) <= Currstate(j);
  end generate;



end Behavioral;
