library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_key_sched is
end tb_key_sched;

architecture testbench of tb_key_sched is

    signal rnd_no   : std_logic_vector(3 downto 0);
    signal prev_key : std_logic_vector(127 downto 0);
    signal next_key : std_logic_vector(127 downto 0);

begin

    uut : entity work.key_schedule
        port map (
            rnd_no   => rnd_no,
            prev_key => prev_key,
            next_key => next_key
        );

    test_process : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing Key Schedule ===" severity note;

        -- FIPS 197 Appendix A.1
        -- master_key = 2B7E151628AED2A6ABF7158809CF4F3C

        -- Test 1: Round 1
        report "TEST 1: Round 1 Key Expansion" severity note;
        prev_key <= x"2B7E151628AED2A6ABF7158809CF4F3C";
        rnd_no   <= x"1";
        wait for 1 ns;
        if next_key = x"A0FAFE1788542CB123A339392A6C7605" then
            report "TEST 1 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 2: Round 2
        report "TEST 2: Round 2 Key Expansion" severity note;
        prev_key <= x"A0FAFE1788542CB123A339392A6C7605";
        rnd_no   <= x"2";
        wait for 1 ns;
        if next_key = x"F2C295F27A96B9435935807A7359F67F" then
            report "TEST 2 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 3: Round 3
        report "TEST 3: Round 3 Key Expansion" severity note;
        prev_key <= x"F2C295F27A96B9435935807A7359F67F";
        rnd_no   <= x"3";
        wait for 1 ns;
        if next_key = x"3D80477D4716FE3E1E237E446D7A883B" then
            report "TEST 3 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 4: Round 4
        report "TEST 4: Round 4 Key Expansion" severity note;
        prev_key <= x"3D80477D4716FE3E1E237E446D7A883B";
        rnd_no   <= x"4";
        wait for 1 ns;
        if next_key = x"EF44A541A8525B7FB671253BDB0BAD00" then
            report "TEST 4 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 5: Round 5
        report "TEST 5: Round 5 Key Expansion" severity note;
        prev_key <= x"EF44A541A8525B7FB671253BDB0BAD00";
        rnd_no   <= x"5";
        wait for 1 ns;
        if next_key = x"D4D1C6F87C839D87CAF2B8BC11F915BC" then
            report "TEST 5 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 5 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 6: Round 6
        report "TEST 6: Round 6 Key Expansion" severity note;
        prev_key <= x"D4D1C6F87C839D87CAF2B8BC11F915BC";
        rnd_no   <= x"6";
        wait for 1 ns;
        if next_key = x"6D88A37A110B3EFDDBF98641CA0093FD" then
            report "TEST 6 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 6 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 7: Round 7
        report "TEST 7: Round 7 Key Expansion" severity note;
        prev_key <= x"6D88A37A110B3EFDDBF98641CA0093FD";
        rnd_no   <= x"7";
        wait for 1 ns;
        if next_key = x"4E54F70E5F5FC9F384A64FB24EA6DC4F" then
            report "TEST 7 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 7 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 8: Round 8
        report "TEST 8: Round 8 Key Expansion" severity note;
        prev_key <= x"4E54F70E5F5FC9F384A64FB24EA6DC4F";
        rnd_no   <= x"8";
        wait for 1 ns;
        if next_key = x"EAD27321B58DBAD2312BF5607F8D292F" then
            report "TEST 8 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 8 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 9: Round 9
        report "TEST 9: Round 9 Key Expansion" severity note;
        prev_key <= x"EAD27321B58DBAD2312BF5607F8D292F";
        rnd_no   <= x"9";
        wait for 1 ns;
        if next_key = x"AC7766F319FADC2128D12941575C006E" then
            report "TEST 9 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 9 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        -- Test 10: Round 10
        report "TEST 10: Round 10 Key Expansion" severity note;
        prev_key <= x"AC7766F319FADC2128D12941575C006E";
        rnd_no   <= x"A";
        wait for 1 ns;
        if next_key = x"D014F9A8C9EE2589E13F0CC8B6630CA6" then
            report "TEST 10 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 10 FAIL" severity error;
        end if;
        test_count := test_count + 1;

        report "Key Schedule Tests Complete: " & integer'image(pass_count) & "/" &
               integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;