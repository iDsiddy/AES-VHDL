library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity sub_bytes is 
    port (
        data_in : in std_logic_vector(127 downto 0);
        data_out : out std_logic_vector(127 downto 0)
    );
end entity;

architecture Behavioral of sub_bytes is
begin	

	gen : for i in 0 to 15 generate
		sbox_inst : entity work.Sbox
			port map(
				in_byte  => data_in((i + 1)*8 - 1 downto i*8),
				out_byte => data_out((i + 1)*8 - 1 downto i*8)
			);		
	end generate gen;

end architecture;