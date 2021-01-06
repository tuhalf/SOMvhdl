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
    generic(BaudRate: integer := 9600);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           dataT : in STD_LOGIC_VECTOR(7 downto 0);
           dataR : out STD_LOGIC_VECTOR(7 downto 0);
           RX : in STD_LOGIC;
           TX : out std_logic;
           DataAvalible : out std_logic;
           TransmitAvalible : out std_logic;
           TransmitData : in std_logic;
           ReadData : in std_logic
           );
end serial;

architecture Behavioral of serial is
constant countMax : natural := (100000000/baudrate); 
signal RegisterIn : STD_LOGIC_VECTOR(7 downto 0);
signal RegisterOut : STD_LOGIC_VECTOR(7 downto 0);
signal CountRX : natural;
signal CountTX : natural;
type RTStates is(idle,start,data,stopS);
signal RXState : RTStates :=idle;
signal TXState : RTStates :=idle;
signal RXPos : natural;
signal TXPos : natural;

signal dataAvDRV: std_logic;

signal writeFifo : std_logic;
signal readFifo : std_logic;
signal dataIn : std_logic;
signal fifoEmpty : std_logic;
signal fifoFull : std_logic;
--signal FifoIN : STD_LOGIC_VECTOR(7 downto 0); registerIn
signal fifoOut : STD_LOGIC_VECTOR(7 downto 0);
COMPONENT fifo_serial
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;
begin

    -------------fifo
    fifo_out: fifo_serial
      PORT MAP (
        clk => clk,
        rst => rst,
        din => RegisterIn,
        wr_en => dataIn,
        rd_en => ReadData,
        dout => dataR,
        full => fifoFull,
        empty => fifoEmpty
      );

    ------------



    DataAvalible <= not(fifoEmpty);


    Receive: process(clk, rst)
    begin
        if rst = '1' then
            RegisterIn <= (others=>'0');
            dataIn <= '0';
            RXState <= idle;
            RXPos <= 0;
        elsif rising_edge(clk) then
            case RXState is 
                when idle =>
                        dataIn <= '0';
                    if RX = '0' then
                        CountRX <= 0;
                        RXState <= start;
                    end if;
                when start =>
                    if CountRX = (countMax/2) then
                        RegisterIn <= (others=>'0');
                        RXState <= data;
                        CountRX <= 0;
                        RXPos <= 0;
                        dataIn <= '0';
                    else
                        CountRX <= CountRX+1;
                    end if;
                when data =>
                    if RXPos = 8 then
                        CountRX <= 0;
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
                        dataIn <= '1';
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
                    TX <= '1';
                    if TransmitData = '1' then
                        TXState <= start;
                        CountTX <= 0;
                        TransmitAvalible <= '0';
                        RegisterOut<= dataT;
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
                        CountTX <= 0;
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
