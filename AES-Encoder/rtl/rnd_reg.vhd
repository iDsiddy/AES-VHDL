library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rnd_reg is
    port (
        clk, rst: in std_logic;
        d : in std_logic_vector(127 downto 0);  -- previous round intermediate ciphertext
        q : out std_logic_vector(127 downto 0)  -- output that goes to next round process
    );
end rnd_reg;

architecture Behavioral of rnd_reg is
	signal current_state, next_state : std_logic_vector(127 downto 0);
begin 
	next_state <= d;
	
	seq : process(clk, rst) is		
	begin
	    if (rst = '1') then
	       current_state <= (others => '0');
		elsif (clk'event and clk = '1') then
			current_state <= next_state;
		end if;
	end process;
	
	q <= current_state;	
end Behavioral;
