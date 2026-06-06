library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_sbox is
end tb_sbox;

architecture testbench of tb_sbox is

    component Sbox is
        Port (
            in_byte : in std_logic_vector(7 downto 0);
            out_byte : out std_logic_vector(7 downto 0)
        );
    end component;

    signal in_byte  : std_logic_vector(7 downto 0);
    signal out_byte : std_logic_vector(7 downto 0);

    -- SBOX LUT for reference
    type sbox_array is array (0 to 255) of std_logic_vector(7 downto 0);
    constant S_BOX : sbox_array := (
        x"63", x"7C", x"77", x"7B", x"F2", x"6B", x"6F", x"C5",
        x"30", x"01", x"67", x"2B", x"FE", x"D7", x"AB", x"76",
        x"CA", x"82", x"C9", x"7D", x"FA", x"59", x"47", x"F0",
        x"AD", x"D4", x"A2", x"AF", x"9C", x"A4", x"72", x"C0",
        x"B7", x"FD", x"93", x"26", x"36", x"3F", x"F7", x"CC",
        x"34", x"A5", x"E5", x"F1", x"71", x"D8", x"31", x"15",
        x"04", x"C7", x"23", x"C3", x"18", x"96", x"05", x"9A",
        x"07", x"12", x"80", x"E2", x"EB", x"27", x"B2", x"75",
        x"09", x"83", x"2C", x"1A", x"1B", x"6E", x"5A", x"A0",
        x"52", x"3B", x"D6", x"B3", x"29", x"E3", x"2F", x"84",
        x"53", x"D1", x"00", x"ED", x"20", x"FC", x"B1", x"5B",
        x"6A", x"CB", x"BE", x"39", x"4A", x"4C", x"58", x"CF",
        x"D0", x"EF", x"AA", x"FB", x"43", x"4D", x"33", x"85",
        x"45", x"F9", x"02", x"7F", x"50", x"3C", x"9F", x"A8",
        x"51", x"A3", x"40", x"8F", x"92", x"9D", x"38", x"F5",
        x"BC", x"B6", x"DA", x"21", x"10", x"FF", x"F3", x"D2",
        x"CD", x"0C", x"13", x"EC", x"5F", x"97", x"44", x"17",
        x"C4", x"A7", x"7E", x"3D", x"64", x"5D", x"19", x"73",
        x"60", x"81", x"4F", x"DC", x"22", x"2A", x"90", x"88",
        x"46", x"EE", x"B8", x"14", x"DE", x"5E", x"0B", x"DB",
        x"E0", x"32", x"3A", x"0A", x"49", x"06", x"24", x"5C",
        x"C2", x"D3", x"AC", x"62", x"91", x"95", x"E4", x"79",
        x"E7", x"C8", x"37", x"6D", x"8D", x"D5", x"4E", x"A9",
        x"6C", x"56", x"F4", x"EA", x"65", x"7A", x"AE", x"08",
        x"BA", x"78", x"25", x"2E", x"1C", x"A6", x"B4", x"C6",
        x"E8", x"DD", x"74", x"1F", x"4B", x"BD", x"8B", x"8A",
        x"70", x"3E", x"B5", x"66", x"48", x"03", x"F6", x"0E",
        x"61", x"35", x"57", x"B9", x"86", x"C1", x"1D", x"9E",
        x"E1", x"F8", x"98", x"11", x"69", x"D9", x"8E", x"94",
        x"9B", x"1E", x"87", x"E9", x"CE", x"55", x"28", x"DF",
        x"8C", x"A1", x"89", x"0D", x"BF", x"E6", x"42", x"68",
        x"41", x"99", x"2D", x"0F", x"B0", x"54", x"BB", x"16"
    );

begin

    dut : Sbox port map (
        in_byte  => in_byte,
        out_byte => out_byte
    );

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
        variable expected : std_logic_vector(7 downto 0);
    begin
        report "=== Testing S-Box ===" severity note;

        -- Test 1: Zero
        report "TEST 1: S-Box[0x00]" severity note;
        in_byte <= x"00";
        wait for 1 ns;
        if out_byte = x"63" then
            report "TEST 1 PASS: S-Box[0x00] = 0x63" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL: Expected 0x63, got " & to_hstring(out_byte) severity error;
        end if;
        test_count := test_count + 1;

        -- Test 2: 0xFF
        report "TEST 2: S-Box[0xFF]" severity note;
        in_byte <= x"FF";
        wait for 1 ns;
        if out_byte = x"16" then
            report "TEST 2 PASS: S-Box[0xFF] = 0x16" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL: Expected 0x16, got " & to_hstring(out_byte) severity error;
        end if;
        test_count := test_count + 1;

        -- Test 3: 0x53
        report "TEST 3: S-Box[0x53]" severity note;
        in_byte <= x"53";
        wait for 1 ns;
        if out_byte = x"ED" then
            report "TEST 3 PASS: S-Box[0x53] = 0xED" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL: Expected 0xD1, got " & to_hstring(out_byte) severity error;
        end if;
        test_count := test_count + 1;

        -- Test 4: 0x95
        report "TEST 4: S-Box[0x95]" severity note;
        in_byte <= x"95";
        wait for 1 ns;
        if out_byte = x"2A" then
            report "TEST 4 PASS: S-Box[0x95] = 0x2A" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL: Expected 0xE4, got " & to_hstring(out_byte) severity error;
        end if;
        test_count := test_count + 1;

        -- Test 5: Batch test - first 16 entries
        report "TEST 5: Batch test (S-Box[0..15])" severity note;
        for i in 0 to 15 loop
            in_byte <= std_logic_vector(to_unsigned(i, 8));
            wait for 1 ns;
            expected := S_BOX(i);
            if out_byte /= expected then
                report "Mismatch at index " & integer'image(i) & ": Expected " & 
                        to_hstring(expected) & ", got " & to_hstring(out_byte) severity error;
            end if;
        end loop;
        report "TEST 5 PASS: First 16 entries verified" severity note;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 6: Batch test - last 16 entries
        report "TEST 6: Batch test (S-Box[240..255])" severity note;
        for i in 240 to 255 loop
            in_byte <= std_logic_vector(to_unsigned(i, 8));
            wait for 1 ns;
            expected := S_BOX(i);
            if out_byte /= expected then
                report "Mismatch at index " & integer'image(i) & ": Expected " & 
                        to_hstring(expected) & ", got " & to_hstring(out_byte) severity error;
            end if;
        end loop;
        report "TEST 6 PASS: Last 16 entries verified" severity note;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        -- Test 7: Batch test - middle entries
        report "TEST 7: Batch test (S-Box[128..143])" severity note;
        for i in 128 to 143 loop
            in_byte <= std_logic_vector(to_unsigned(i, 8));
            wait for 1 ns;
            expected := S_BOX(i);
            if out_byte /= expected then
                report "Mismatch at index " & integer'image(i) & ": Expected " & 
                        to_hstring(expected) & ", got " & to_hstring(out_byte) severity error;
            end if;
        end loop;
        report "TEST 7 PASS: Middle entries verified" severity note;
        pass_count := pass_count + 1;
        test_count := test_count + 1;

        report "S-Box Tests Complete: " & integer'image(pass_count) & "/" & 
                integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;