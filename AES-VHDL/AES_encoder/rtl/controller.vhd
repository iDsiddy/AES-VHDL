library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
    port (
        clk, rst, start : in  std_logic;
        init, state_en, key_en, final_rnd, done : out std_logic;
        rnd_no : out std_logic_vector(3 downto 0)
    );
end controller;

architecture Behavioral of controller is
    type fsm_state is (IDLE_ST, INIT_ST, ROUND_ST, FINAL_ST, DONE_ST);
    signal current_state, next_state : fsm_state;

    signal rnd_count : unsigned(3 downto 0);
begin

    -- Output round number
    rnd_no <= std_logic_vector(rnd_count);

    seq: process(clk, rst)
    begin
        if rst = '1' then
            current_state <= IDLE_ST;
            rnd_count     <= (others => '0');

        elsif (clk'event and clk = '1') then
            current_state <= next_state;

            -- Increment round counter only during ROUND state
            if current_state = INIT_ST then
                rnd_count <= to_unsigned(1, 4);

            elsif current_state = ROUND_ST then    
                rnd_count <= rnd_count + 1;

            elsif current_state = IDLE_ST then
                rnd_count <= (others => '0'); 

            end if;        
        end if;
    end process;

    next_logic: process(current_state, start, rnd_count)
    begin
        case current_state is
            when IDLE_ST =>
                if start = '1' then
                    next_state <= INIT_ST;
                else
                    next_state <= IDLE_ST;
                end if;

            when INIT_ST =>
            -- Round 0: latch plaintext XOR master_key
                next_state <= ROUND_ST;

            when ROUND_ST =>
                if rnd_count = 9 then
                    next_state <= FINAL_ST;
                else
                    next_state <= ROUND_ST;
                end if;

            when FINAL_ST =>
                next_state <= DONE_ST;

            when DONE_ST =>
                if start = '1' then
                    next_state <= INIT_ST;
                else
                    next_state <= DONE_ST;
                end if;

            when others =>
                next_state <= IDLE_ST;
        end case;
    end process;

    output_logic: process(current_state, rnd_count)
    begin
        -- Default outputs
        init <= '0';
        state_en <= '0';
        key_en <= '0';
        final_rnd <= '0';
        done <= '0';

        case current_state is
            when IDLE_ST =>
                null; -- All outputs remain at default

            when INIT_ST =>
                -- Load plaintext XOR master_key into state reg
                -- key_en asserted here to preload master_key into key reg
                init     <= '1';
                state_en <= '1';
                key_en   <= '1';
                
            when ROUND_ST =>
                state_en <= '1'; -- Enable state updates
                key_en <= '1';   -- Enable round key generation

            when FINAL_ST =>
                state_en  <= '1';
                key_en    <= '1';
                final_rnd <= '1';   -- Signal for final round (no MixColumns)

            when DONE_ST =>
                done <= '1'; -- Indicate encryption is complete

            when others =>
                null; -- All outputs remain at default
        end case;
    end process;

end Behavioral;
