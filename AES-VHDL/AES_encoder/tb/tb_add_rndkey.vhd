library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_add_rndkey is
end tb_add_rndkey;

architecture testbench of tb_add_rndkey is

    -- ADD THESE CONSTANTS HERE (This fixes the compiler ambiguity)
    constant ALL_ZEROS : std_logic_vector(127 downto 0) := (others => '0');
    constant ALL_ONES  : std_logic_vector(127 downto 0) := (others => '1');

    component add_rndkey is
        port (
            in_word : in  std_logic_vector(127 downto 0);
            key     : in  std_logic_vector(127 downto 0);
            output  : out std_logic_vector(127 downto 0)
        );
    end component;

    signal in_word : std_logic_vector(127 downto 0);
    signal key     : std_logic_vector(127 downto 0);
    signal output  : std_logic_vector(127 downto 0);

begin

    dut : add_rndkey port map (
        in_word => in_word,
        key     => key,
        output  => output
    );

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing AddRoundKey ===" severity note;

        -- Test 1: Zero XOR Zero
        report "TEST 1: Zero XOR Zero" severity note;
        in_word <= (others => '0');
        key <= (others => '0');
        wait for 1 ns;
        if output = ALL_ZEROS then
            report "TEST 1 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 2: Ones XOR Ones
        report "TEST 2: Ones XOR Ones" severity note;
        in_word <= (others => '1');
        key <= (others => '1');
        wait for 1 ns;
        if output = ALL_ZEROS then
            report "TEST 2 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 3: Ones XOR Zeros
        report "TEST 3: Ones XOR Zeros" severity note;
        in_word <= (others => '1');
        key <= (others => '0');
        wait for 1 ns;
        if output = ALL_ONES then
            report "TEST 3 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 4: Pattern XOR Pattern
        report "TEST 4: Pattern XOR Pattern (same)" severity note;
        in_word <= x"00112233445566778899aabbccddeeff";
        key <= x"00112233445566778899aabbccddeeff";
        wait for 1 ns;
        if output = ALL_ZEROS then
            report "TEST 4 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 5: Pattern XOR Inverted
        report "TEST 5: Pattern XOR Inverted" severity note;
        in_word <= x"00112233445566778899aabbccddeeff";
        key <= x"ffeeddccbbaa99887766554433221100";
        wait for 1 ns;
        if output = ALL_ONES then
            report "TEST 5 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 5 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 6: Alternating XOR
        report "TEST 6: Alternating pattern XOR" severity note;
        in_word <= x"aaaabbbbccccddddaaaabbbbccccdddd";
        key <= x"55554444333322225555444433332222";
        wait for 1 ns;
        if output'length = 128 then
            report "TEST 6 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 6 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        report "AddRoundKey Tests Complete: " & integer'image(pass_count) & "/" & 
                integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;
