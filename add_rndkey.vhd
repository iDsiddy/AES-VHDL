library ieee;
use ieee.std_logic_1164.all;

entity add_rndkey is
	port (
		in_word : in std_logic_vector(127 downto 0);
		key : in std_logic_vector(127 downto 0);
		output : out std_logic_vector(127 downto 0)
	);
end add_rndkey;

architecture Behavioral of add_rndkey is
begin
	output <= in_word xor key;		
end architecture;