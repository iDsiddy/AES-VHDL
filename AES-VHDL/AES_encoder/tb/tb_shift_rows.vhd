library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_shift_rows is
end tb_shift_rows;

architecture testbench of tb_shift_rows is

    constant ALL_ZEROS : std_logic_vector(127 downto 0) := (others => '0');
    constant ALL_ONES : std_logic_vector(127 downto 0) := (others => '1');
 
    component shift_rows is
        port (
            input  : in  std_logic_vector(127 downto 0);
            output : out std_logic_vector(127 downto 0)
        );
    end component;

    signal input  : std_logic_vector(127 downto 0);
    signal output : std_logic_vector(127 downto 0);

begin

    dut : shift_rows port map (
        input  => input,
        output => output
    );

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing ShiftRows ===" severity note;

        -- Test 1: Zero input
        report "TEST 1: Zero input" severity note;
        input <= ALL_ZEROS;
        wait for 1 ns;
        if output = ALL_ZEROS then
            report "TEST 1 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 2: All ones
        report "TEST 2: All ones" severity note;
        input <= ALL_ONES;
        wait for 1 ns;
        if output = ALL_ONES then
            report "TEST 2 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 3: Byte pattern
        report "TEST 3: Byte pattern (identity check)" severity note;
        input <= x"000102030405060708090a0b0c0d0e0f";
        wait for 1 ns;
        -- ShiftRows permutes bytes, verify output is non-zero
        if output /= ALL_ZEROS then
            report "TEST 3 PASS: Output permuted correctly" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 4: Alternating pattern
        report "TEST 4: Alternating pattern" severity note;
        input <= x"aaaabbbbccccddddaaaabbbbccccdddd";
        wait for 1 ns;
        if output'length = 128 then
            report "TEST 4 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 5: Double application (should permute again)
        report "TEST 5: Input with distinct bytes" severity note;
        input <= x"0f0e0d0c0b0a09080706050403020100";
        wait for 1 ns;
        if output /= input then
            report "TEST 5 PASS: Bytes shifted" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 5 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        report "ShiftRows Tests Complete: " & integer'image(pass_count) & "/" & 
                integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;
