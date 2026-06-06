library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_controller is
end tb_controller;

architecture testbench of tb_controller is

    component controller is
        port (
            clk, rst, start : in  std_logic;
            init, state_en, key_en, final_rnd, done : out std_logic;
            rnd_no : out std_logic_vector(3 downto 0)
        );
    end component;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal start     : std_logic := '0';
    signal init      : std_logic;
    signal state_en  : std_logic;
    signal key_en    : std_logic;
    signal final_rnd : std_logic;
    signal done      : std_logic;
    signal rnd_no    : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    dut : controller port map (
        clk      => clk,
        rst      => rst,
        start    => start,
        init     => init,
        state_en => state_en,
        key_en   => key_en,
        final_rnd => final_rnd,
        done     => done,
        rnd_no   => rnd_no
    );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing Controller ===" severity note;

        -- Test 1: Reset state
        report "TEST 1: Reset state" severity note;
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        assert done = '0' report "Reset: done should be 0" severity error;
        assert init = '0' report "Reset: init should be 0" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 2: IDLE state (no start)
        report "TEST 2: IDLE state - no start signal" severity note;
        rst <= '0';
        start <= '0';
        wait for 2 * CLK_PERIOD;
        assert done = '0' report "IDLE: done should be 0" severity error;
        assert init = '0' report "IDLE: init should be 0" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 3: Start encryption
        report "TEST 3: Start encryption (INIT state)" severity note;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for CLK_PERIOD;
        assert init = '1' report "INIT: init should be 1" severity error;
        assert state_en = '1' report "INIT: state_en should be 1" severity error;
        assert key_en = '1' report "INIT: key_en should be 1" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 4: ROUND state progression
        report "TEST 4: ROUND state progression" severity note;
        wait for CLK_PERIOD;
        -- Should be in ROUND state now
        assert state_en = '1' report "ROUND: state_en should be 1" severity error;
        assert key_en = '1' report "ROUND: key_en should be 1" severity error;
        assert final_rnd = '0' report "ROUND: final_rnd should be 0" severity error;
        assert done = '0' report "ROUND: done should be 0" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 5: Round counter increments
        report "TEST 5: Round counter increments" severity note;
        for i in 2 to 8 loop
            wait for CLK_PERIOD;
            assert rnd_no = std_logic_vector(to_unsigned(i, 4)) 
                report "ROUND " & integer'image(i) & ": rnd_no mismatch" severity error;
        end loop;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 6: Transition to FINAL round (round 9)
        report "TEST 6: Transition to FINAL round" severity note;
        wait for CLK_PERIOD;
        assert rnd_no = x"9" report "Should be at round 9" severity error;
        wait for CLK_PERIOD;
        -- Now in FINAL state
        assert final_rnd = '1' report "FINAL: final_rnd should be 1" severity error;
        assert state_en = '1' report "FINAL: state_en should be 1" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 7: DONE state
        report "TEST 7: DONE state" severity note;
        wait for CLK_PERIOD;
        assert done = '1' report "DONE: done should be 1" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 8: Remain in DONE until start
        report "TEST 8: Remain in DONE state" severity note;
        wait for CLK_PERIOD;
        assert done = '1' report "DONE_ST: done should remain 1" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 9: New encryption from DONE state
        report "TEST 9: New encryption from DONE state" severity note;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for CLK_PERIOD;
        assert init = '1' report "Restart INIT: init should be 1" severity error;
        assert rnd_no = x"0" report "Restart: rnd_no should reset to 0 or 1" severity error;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 10: Reset during encryption
        report "TEST 10: Reset during encryption" severity note;
        wait for 5 * CLK_PERIOD;
        rst <= '1';
        wait for CLK_PERIOD;
        assert done = '0' report "After reset: done should be 0" severity error;
        assert rnd_no = x"0" report "After reset: rnd_no should be 0" severity error;
        rst <= '0';
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 11: Multiple start pulses (start reasserted during encryption)
        report "TEST 11: Multiple start pulses" severity note;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for 3 * CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        -- Should continue from current state
        wait for 2 * CLK_PERIOD;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        report "Controller Tests Complete: " & integer'image(pass_count) & "/" & 
                integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;
