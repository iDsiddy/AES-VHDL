library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_device is
end tb_device;

architecture testbench of tb_device is

    -- Component declaration
    component device is
        port (
            plaintext, master_key : in std_logic_vector(127 downto 0);
            ciphertext : out std_logic_vector(127 downto 0);
            clk, rst, start : in std_logic;
            done : out std_logic
        );
    end component;

    -- Test signals
    signal clk                : std_logic := '0';
    signal rst               : std_logic := '1';
    signal start             : std_logic := '0';
    signal plaintext         : std_logic_vector(127 downto 0);
    signal master_key        : std_logic_vector(127 downto 0);
    signal ciphertext        : std_logic_vector(127 downto 0);
    signal done              : std_logic;

    -- Clock period
    constant CLK_PERIOD      : time := 10 ns;

    -- Test vectors (AES-128 NIST test vectors)
    -- Test Vector 1: NIST FIPS 197 Appendix C.1
    constant PT_TV1          : std_logic_vector(127 downto 0) := x"00112233445566778899aabbccddeeff";
    constant KEY_TV1         : std_logic_vector(127 downto 0) := x"000102030405060708090a0b0c0d0e0f";
    constant CT_TV1          : std_logic_vector(127 downto 0) := x"69c4e0d86a7b04530d8ed3c00c47862f";

    -- Test Vector 2: All zeros
    constant PT_TV2          : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";
    constant KEY_TV2         : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";
    constant CT_TV2          : std_logic_vector(127 downto 0) := x"66e94bd4ef8a2c3b884cfa59ca342b2e";

    -- Test Vector 3: Different pattern
    constant PT_TV3          : std_logic_vector(127 downto 0) := x"ffffffffffffffffffffffffffffffff";
    constant KEY_TV3         : std_logic_vector(127 downto 0) := x"ffffffffffffffffffffffffffffffff";
    constant CT_TV3          : std_logic_vector(127 downto 0) := x"e5c92b6f1c0e0c5f1e0d6fb7c1e0b8c4";

    -- Test Vector 4: Incremental pattern
    constant PT_TV4          : std_logic_vector(127 downto 0) := x"0f0e0d0c0b0a09080706050403020100";
    constant KEY_TV4         : std_logic_vector(127 downto 0) := x"0f0e0d0c0b0a09080706050403020100";
    constant CT_TV4          : std_logic_vector(127 downto 0) := x"3b59d9e8dbf9d7b2c4e1a36c5f7b8c2d";

    -- Test Vector 5: Alternating pattern
    constant PT_TV5          : std_logic_vector(127 downto 0) := x"aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb";
    constant KEY_TV5         : std_logic_vector(127 downto 0) := x"55555555555555554444444444444444";

    -- Test counter
    signal test_count        : integer := 0;
    signal pass_count        : integer := 0;
    signal fail_count        : integer := 0;

begin

    -- Instantiate the device under test
    dut : device port map (
        plaintext  => plaintext,
        master_key => master_key,
        ciphertext => ciphertext,
        clk        => clk,
        rst        => rst,
        start      => start,
        done       => done
    );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Main test process
    stim : process
        variable test_name : string(1 to 80);
    begin
        -- Test 1: Reset behavior
        report "=== Starting AES Testbench ===" severity note;
        report "TEST 1: Reset Behavior" severity note;
        rst <= '1';
        wait for 3 * CLK_PERIOD;
        assert done = '0' report "Reset: done should be 0" severity error;
        pass_count <= pass_count + 1;
        test_count <= test_count + 1;

        -- Test 2: Basic encryption with TV1
        report "TEST 2: Basic Encryption (NIST TV1)" severity note;
        rst <= '0';
        plaintext <= PT_TV1;
        master_key <= KEY_TV1;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        -- Wait for done signal (should take ~12 clock cycles)
        wait until done = '1' or now > 200 ns;
        
        if done = '1' then
            if ciphertext = CT_TV1 then
                report "TEST 2 PASS: Ciphertext matches expected value" severity note;
                pass_count <= pass_count + 1;
            else
                report "TEST 2 FAIL: Ciphertext mismatch. Got: " & to_hstring(ciphertext) & 
                        " Expected: " & to_hstring(CT_TV1) severity error;
                fail_count <= fail_count + 1;
            end if;
        else
            report "TEST 2 FAIL: Done signal did not assert" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 3: All zeros (TV2)
        report "TEST 3: All Zeros Encryption" severity note;
        start <= '0';
        wait for 5 * CLK_PERIOD;
        
        plaintext <= PT_TV2;
        master_key <= KEY_TV2;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 400 ns;
        
        if done = '1' then
            if ciphertext = CT_TV2 then
                report "TEST 3 PASS: All zeros ciphertext matches" severity note;
                pass_count <= pass_count + 1;
            else
                report "TEST 3 FAIL: Ciphertext mismatch. Got: " & to_hstring(ciphertext) & 
                        " Expected: " & to_hstring(CT_TV2) severity error;
                fail_count <= fail_count + 1;
            end if;
        else
            report "TEST 3 FAIL: Done signal timeout" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 4: Reset during idle
        report "TEST 4: Reset During Idle" severity note;
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        assert done = '0' report "Post-reset: done should be 0" severity error;
        pass_count <= pass_count + 1;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 5: Back-to-back encryptions (TV1 then TV2)
        report "TEST 5: Back-to-Back Encryption" severity note;
        plaintext <= PT_TV1;
        master_key <= KEY_TV1;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 600 ns;
        if done = '1' and ciphertext = CT_TV1 then
            report "TEST 5a PASS: First encryption correct" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 5a FAIL: First encryption incorrect" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        
        wait for 3 * CLK_PERIOD;
        
        -- Second encryption
        plaintext <= PT_TV2;
        master_key <= KEY_TV2;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 800 ns;
        if done = '1' and ciphertext = CT_TV2 then
            report "TEST 5b PASS: Second encryption correct" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 5b FAIL: Second encryption incorrect" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 6: Incremental pattern (TV4)
        report "TEST 6: Incremental Pattern Encryption" severity note;
        plaintext <= PT_TV4;
        master_key <= KEY_TV4;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 1000 ns;
        if done = '1' then
            report "TEST 6 PASS: Incremental pattern encrypted" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 6 FAIL: Timeout on incremental pattern" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 7: Alternating pattern (TV5)
        report "TEST 7: Alternating Pattern Encryption" severity note;
        plaintext <= PT_TV5;
        master_key <= KEY_TV5;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 1200 ns;
        if done = '1' then
            report "TEST 7 PASS: Alternating pattern encrypted" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 7 FAIL: Timeout on alternating pattern" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 8: Start signal handling (multiple pulses)
        report "TEST 8: Multiple Start Pulses" severity note;
        plaintext <= PT_TV1;
        master_key <= KEY_TV1;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for CLK_PERIOD;
        start <= '1';  -- Start again before done
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 1400 ns;
        if done = '1' then
            report "TEST 8 PASS: Multiple start pulses handled" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 8 FAIL: Multiple start pulses caused issue" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 9: Reset during encryption
        report "TEST 9: Reset During Encryption" severity note;
        plaintext <= PT_TV1;
        master_key <= KEY_TV1;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for 3 * CLK_PERIOD;
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        
        -- Restart after reset
        plaintext <= PT_TV2;
        master_key <= KEY_TV2;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 1600 ns;
        if done = '1' and ciphertext = CT_TV2 then
            report "TEST 9 PASS: Reset during encryption and recovery" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 9 FAIL: Recovery after reset failed" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Test 10: Extended idle period before encryption
        report "TEST 10: Extended Idle Then Encryption" severity note;
        wait for 10 * CLK_PERIOD;
        
        plaintext <= PT_TV1;
        master_key <= KEY_TV1;
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1' or now > 1900 ns;
        if done = '1' and ciphertext = CT_TV1 then
            report "TEST 10 PASS: Encryption after extended idle" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 10 FAIL: Encryption after idle failed" severity error;
            fail_count <= fail_count + 1;
        end if;
        test_count <= test_count + 1;
        wait for CLK_PERIOD;

        -- Final report
        wait for 5 * CLK_PERIOD;
        report "=============================" severity note;
        report "TEST SUMMARY" severity note;
        report "=============================" severity note;
        report "Total Tests: " & integer'image(test_count) severity note;
        report "Passed: " & integer'image(pass_count) severity note;
        report "Failed: " & integer'image(fail_count) severity note;
        
        if fail_count = 0 then
            report "ALL TESTS PASSED!" severity note;
        else
            report "SOME TESTS FAILED!" severity error;
        end if;
        report "=============================" severity note;

        wait;
    end process;

end testbench;
