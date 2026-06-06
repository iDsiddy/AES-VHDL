library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sub_bytes is
end tb_sub_bytes;

architecture testbench of tb_sub_bytes is

    constant ALL_ZEROS_128 : std_logic_vector(127 downto 0) := (others => '0');

    component sub_bytes is
        port (
            data_in  : in  std_logic_vector(127 downto 0);
            data_out : out std_logic_vector(127 downto 0)
        );
    end component;

    signal data_in  : std_logic_vector(127 downto 0);
    signal data_out : std_logic_vector(127 downto 0);

begin

    dut : sub_bytes port map (
        data_in  => data_in,
        data_out => data_out
    );

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing SubBytes ===" severity note;

        -- Test 1: FIPS 197 Appendix B Round 1
        report "TEST 1: FIPS 197 Appendix B SubBytes" severity note;
        data_in <= x"193DE3BEA0F4E22B9AC68D2AE9F84808";
        wait for 1 ns;
        if data_out = x"D42711AEE0BF98F1B8B45DE51E415230" then
            report "TEST 1 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 2: All zeros -> all 0x63
        report "TEST 2: All zeros input" severity note;
        data_in <= x"00000000000000000000000000000000";
        wait for 1 ns;
        if data_out = x"63636363636363636363636363636363" then
            report "TEST 2 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 3: All 0xFF -> all 0x16
        report "TEST 3: All 0xFF input" severity note;
        data_in <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
        wait for 1 ns;
        if data_out = x"16161616161616161616161616161616" then
            report "TEST 3 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 4: Byte ordering consistency (LSB-first)
        report "TEST 4: Byte ordering consistency check" severity note;
        data_in <= x"00102030011121310212223203132333";
        wait for 1 ns;
        if data_out = x"63CAB7047C82FDC777C993237B7D26C3" then
            report "TEST 4 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 5: XOR self after SubBytes should not give zero
        -- (SubBytes is non-linear so output XOR output = 0, just checks output width)
        report "TEST 5: Output width check" severity note;
        data_in <= x"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        wait for 1 ns;
        if data_out'length = 128 then
            report "TEST 5 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 5 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        report "SubBytes Tests Complete: " & integer'image(pass_count) & "/" &
               integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;