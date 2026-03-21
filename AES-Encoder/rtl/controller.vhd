library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
    port (
        clk, rst, load : in  std_logic;
        init, state_en, key_en, final_rnd, done : out std_logic;
        rnd_no : out std_logic_vector(3 downto 0)
    );
end controller;

architecture Behavioral of controller is
    type fsm_state is (IDLE, INIT, ROUND, FINAL, DONE_ST);
    signal current_state, next_state : fsm_state;

    signal rnd_count : unsigned(3 downto 0);
begin

    -- Output round number
    rnd_no <= std_logic_vector(rnd_count);

    seq: process(clk, rst)
    begin
        if rst = '1' then
            current_state <= IDLE;
            rnd_count     <= (others => '0');

        elsif (clk'event and clk = '1') then
            current_state <= next_state;

            -- Increment round counter only during ROUND state
            if current_state = INIT then
                rnd_count <= to_unsigned(1, 4);

            elsif current_state = ROUND then    
                rnd_count <= rnd_count + 1;

            elsif current_state = IDLE then
                rnd_count <= (others => '0'); 

            end if;        
        end if;
    end process;

    state_en  <= '1' when (rnd_count >= 1 and rnd_count <= 10) else '0';
    key_en    <= '1' when (rnd_count >= 1 and rnd_count <= 10) else '0';
    final_rnd <= '1' when rnd_count = 10 else '0';

end Behavioral;
