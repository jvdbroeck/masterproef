library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tristatebuffer is
	port(
		I : in std_logic_vector(7 downto 0);
		databus : out std_logic_vector(7 downto 0);
		enable : in std_logic
	);
end entity tristatebuffer;

architecture behaviour of tristatebuffer is

begin

	process(I, enable)
	begin
		if enable='0' then
			databus <= I;
		else
			databus <= (others => 'Z');
		end if;
	end process;
end behaviour;
