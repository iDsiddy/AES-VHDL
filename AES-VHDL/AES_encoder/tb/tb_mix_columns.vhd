library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mix_columns is
end tb_mix_columns;

architecture testbench of tb_mix_columns is

    constant ALL_ZEROS : std_logic_vector(31 downto 0) := (others => '0');
    constant ALL_ONES : std_logic_vector(31 downto 0) := (others => '1');
    
    component mix_columns is
        port (
            in_word  : in  std_logic_vector(31 downto 0);
            out_word : out std_logic_vector(31 downto 0)
        );
    end component;

    signal in_word  : std_logic_vector(31 downto 0);
    signal out_word : std_logic_vector(31 downto 0);

begin

    dut : mix_columns port map (
        in_word  => in_word,
        out_word => out_word
    );

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing MixColumns ===" severity note;

        -- Test 1: Zero input
        report "TEST 1: Zero input" severity note;
        in_word <= (others => '0');
        wait for 1 ns;
        if out_word = ALL_ZEROS then
            report "TEST 1 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 2: Single byte (MSB)
        report "TEST 2: Single byte (MSB set)" severity note;
        in_word <= x"01000000";
        wait for 1 ns;
        if out_word /= ALL_ZEROS then
            report "TEST 2 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 3: All ones
        report "TEST 3: All ones" severity note;
        in_word <= ALL_ONES;
        wait for 1 ns;
        if out_word'length = 32 then
            report "TEST 3 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 4: Pattern test 1
        report "TEST 4: Pattern test (0xd4bf5d30)" severity note;
        in_word <= x"d4bf5d30";
        wait for 1 ns;
        if out_word'length = 32 then
            report "TEST 4 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 5: Pattern test 2
        report "TEST 5: Pattern test (0xc5ba6a1e)" severity note;
        in_word <= x"c5ba6a1e";
        wait for 1 ns;
        if out_word'length = 32 then
            report "TEST 5 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 5 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 6: Byte-per-lane
        report "TEST 6: One byte per lane" severity note;
        in_word <= x"01020304";
        wait for 1 ns;
        if out_word /= ALL_ZEROS then
            report "TEST 6 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 6 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        report "MixColumns Tests Complete: " & integer'image(pass_count) & "/" & 
                integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;
