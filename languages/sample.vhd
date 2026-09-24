-- VHDL-2008: a parameterised counter with enable and a synchronous reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (WIDTH : positive := 8);
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        en      : in  std_logic;
        count   : out unsigned(WIDTH - 1 downto 0);
        wrapped : out std_logic
    );
end entity counter;

architecture rtl of counter is
    signal q : unsigned(WIDTH - 1 downto 0) := (others => '0');
begin
    count   <= q;
    wrapped <= '1' when q = (q'range => '1') else '0';

    process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                q <= (others => '0');
            elsif en = '1' then
                q <= q + 1;
            end if;
        end if;
    end process;
end architecture rtl;
