----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.12.2020 15:31:29
-- Design Name: 
-- Module Name: serial - Behavioral
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

--9600 baud, 1 bit=1/9600=0.104 mS

entity serial is
    generic(BaudRate: integer);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           dataT : in STD_LOGIC_VECTOR(7 downto 0);
           dataR : out STD_LOGIC_VECTOR(7 downto 0);
           RX : in STD_LOGIC;
           TX : out std_logic;
           DataAvalible : out std_logic;
           TransmitAvalible : out std_logic;
           TransmitData : in std_logic
           );
end serial;

architecture Behavioral of serial is
constant countMax : integer := (100000/baudrate); 
signal RegisterIn : STD_LOGIC_VECTOR(7 downto 0);
signal RegisterOut : STD_LOGIC_VECTOR(7 downto 0);
signal CountRX : integer range 0 downto countMax;
signal CountTX : integer range 0 downto countMax;
type RTStates is(idle,start,data,stopS);
signal RXState : RTStates :=idle;
signal TXState : RTStates :=idle;
signal RXPos : integer range 0 downto 7;
signal TXPos : integer range 0 downto 7;
begin
    Receive: process(clk, rst)
    begin
        if rst = '1' then
            RegisterIn <= (others=>'0');
            DataAvalible <= '0';
            RXState <= idle;
            RXPos <= 0;
        elsif rising_edge(clk) then
            case RXState is 
                when idle =>
                    if RX = '0' then
                        RXState <= start;
                    end if;
                when start =>
                    if CountRX = (countMax/2) then
                        RegisterIn <= (others=>'0');
                        RXState <= data;
                        CountRX <= 0;
                        RXPos <= 0;
                        DataAvalible <= '0';
                    else
                        CountRX <= CountRX+1;
                    end if;
                when data =>
                    if RXPos = 8 then
                        RXState <= stopS;
                    elsif CountRX = (countMax) then
                        RXState <= data;
                        CountRX <= 0;
                        RegisterIn(RXPos) <= RX;
                        RXPos <= RXPos+1;
                    else
                        CountRX <= CountRX+1;
                    end if;
                when stopS =>
                    if CountRX = (countMax) then
                        RXState <= idle;
                        CountRX <= 0;
                        DataAvalible <= '1';
                    else
                        CountRX <= CountRX+1;
                    end if;
            end case;
        end if;
    end process Receive;

    Transmit: process(clk, rst)
    begin
        if rst = '1' then
            RegisterOut <= (others=>'0');
            TransmitAvalible <= '1';
            TXState <= idle;
            TXPos <= 0;
            TX <= '1';
        elsif rising_edge(clk) then
            case TXState is 
                when idle =>
                    if TransmitData = '1' then
                        TXState <= start;
                        TransmitAvalible <= '0';
                        RegisterOut<= dataT;
                    else 
                        TX <= '1';
                    end if;
                when start =>
                    if CountTX = (countMax) then
                        TXState <= data;
                        CountTX <= 0;
                        TXPos <= 0;
                    else
                        TX <= '0';
                        CountTX <= CountTX+1;
                    end if;
                when data =>
                    if TXPos = 8 then
                        TXState <= stopS;
                    elsif CountTX = (countMax) then
                        TXState <= data;
                        CountTX <= 0;
                        TXPos <= TXPos+1;
                    else
                        CountTX <= CountTX+1;
                        TX <= RegisterOut(TXPos);
                    end if;
                when stopS =>
                    if CountTX = (countMax) then
                        TXState <= idle;
                        CountTX <= 0;
                        TransmitAvalible <= '1';
                    else
                        TX <= '1';
                        CountTX <= CountTX+1;
                    end if;
            end case;
        end if;
    end process Transmit;


end Behavioral;
