----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2020 12:22:53 PM
-- Design Name: 
-- Module Name: BinaryCounter - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BinaryCounter is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           start : in STD_LOGIC;
           stop : in STD_LOGIC;
           count : out STD_LOGIC_VECTOR (31 downto 0)           
           );
end BinaryCounter;

architecture Behavioral of BinaryCounter is
    signal s_stop: std_logic;
    signal s_start: std_logic;
    signal counter: std_logic_vector(31 downto 0);
begin

	count <= counter;

    process (clk, rst_n) begin
        if (rst_n = '0') then
            counter <= (others => '0');
        elsif (rising_edge(clk)) then
            if (s_stop = '0' and s_start = '1') then
                counter <= counter + 1;
            else
                counter <= counter;
            end if;
        end if;
    
    end process;

    process (clk, rst_n) begin
        if (rst_n = '0') then
            s_start <= '0';
            s_stop <= '0';
        elsif (rising_edge(clk)) then
            if (stop = '1') then
                s_stop <= '1';
            end if;
            if (start = '1') then
                s_start <= '1';
            end if;            
        end if;
    
    end process;

end Behavioral;
