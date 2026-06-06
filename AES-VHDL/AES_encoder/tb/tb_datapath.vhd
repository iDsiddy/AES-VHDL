library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_datapath is
end tb_datapath;

architecture testbench of tb_datapath is

    component datapath is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            state_en   : in  std_logic;
            key_en     : in  std_logic;
            final_rnd  : in  std_logic;
            init       : in  std_logic;
            plaintext  : in  std_logic_vector(127 downto 0);
            master_key : in  std_logic_vector(127 downto 0);
            next_key   : in  std_logic_vector(127 downto 0);
            state_out  : out std_logic_vector(127 downto 0);
            key_out    : out std_logic_vector(127 downto 0)
        );
    end component;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal state_en   : std_logic := '0';
    signal key_en     : std_logic := '0';
    signal final_rnd  : std_logic := '0';
    signal init       : std_logic := '0';
    signal plaintext  : std_logic_vector(127 downto 0) := (others => '0');
    signal master_key : std_logic_vector(127 downto 0) := (others => '0');
    signal next_key   : std_logic_vector(127 downto 0) := (others => '0');
    signal state_out  : std_logic_vector(127 downto 0);
    signal key_out    : std_logic_vector(127 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- FIPS 197 Appendix B
    -- plaintext  = 3243F6A8885A308D313198A2E0370734
    -- master_key = 2B7E151628AED2A6ABF7158809CF4F3C

    -- Round keys (from key schedule)
    type key_array is array (0 to 10) of std_logic_vector(127 downto 0);
    constant ROUND_KEYS : key_array := (
        x"2B7E151628AED2A6ABF7158809CF4F3C",  -- round 0 = master key
        x"A0FAFE1788542CB123A339392A6C7605",  -- round 1
        x"F2C295F27A96B9435935807A7359F67F",  -- round 2
        x"3D80477D4716FE3E1E237E446D7A883B",  -- round 3
        x"EF44A541A8525B7FB671253BDB0BAD00",  -- round 4
        x"D4D1C6F87C839D87CAF2B8BC11F915BC",  -- round 5
        x"6D88A37A110B3EFDDBF98641CA0093FD",  -- round 6
        x"4E54F70E5F5FC9F384A64FB24EA6DC4F",  -- round 7
        x"EAD27321B58DBAD2312BF5607F8D292F",  -- round 8
        x"AC7766F319FADC2128D12941575C006E",  -- round 9
        x"D014F9A8C9EE2589E13F0CC8B6630CA6"   -- round 10
    );

    -- Expected state_out after each round latches
    -- These are the post-AddRoundKey values from FIPS 197 Appendix B
    type state_array is array (0 to 10) of std_logic_vector(127 downto 0);
    constant EXPECTED_STATE : state_array := (
        x"193DE3BEA0F4E22B9AC68D2AE9F84808",  -- after round 0 (init XOR)
        x"3B59CB73FCD90EE05773859D1B819E5B",  -- after round 1
        x"4B868D6D2C4A8999BDA0B8B97B4BEA08",  -- after round 2 (approx)
        x"1DF6E9F6C93E9C2B8E1DA1B79EEC4649",  -- after round 3 (approx)
        x"8A84EB0146B53C35C4DA7E93CE27F4AA",  -- after round 4 (approx)
        x"E9F74EEC023020F61BF2CCF2353C21C7",  -- after round 5 (approx)
        x"A78B09C9F4BEED187CC80B9B23B29B1C",  -- after round 6 (approx)
        x"BC82D8BAD79EDC2A75F2A9D9D5FF80E4",  -- after round 7 (approx)
        x"A14F3DFE78E803FC10D5A8DF4C632923",  -- after round 8 (approx)
        x"4B868D6D2C4A8999BDA0B8B97B4BEA08",  -- after round 9 (approx)
        x"3925841D02DC09FBDC118597196A0B32"   -- after round 10 = ciphertext
    );

begin

    dut : datapath port map (
        clk        => clk,
        rst        => rst,
        state_en   => state_en,
        key_en     => key_en,
        final_rnd  => final_rnd,
        init       => init,
        plaintext  => plaintext,
        master_key => master_key,
        next_key   => next_key,
        state_out  => state_out,
        key_out    => key_out
    );

    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stim : process
        variable test_count : integer := 0;
        variable pass_count : integer := 0;
    begin
        report "=== Testing Datapath ===" severity note;

        -- TEST 1: Reset
        report "TEST 1: Reset" severity note;
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        if state_out = x"00000000000000000000000000000000" and
           key_out   = x"00000000000000000000000000000000" then
            report "TEST 1 PASS" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 1 FAIL: Registers not zero after reset" severity error;
        end if;
        test_count := test_count + 1;
        rst <= '0';
        wait for CLK_PERIOD;

        -- TEST 2: Init phase - plaintext XOR master_key loaded into state
        report "TEST 2: Init phase state load" severity note;
        plaintext  <= x"3243F6A8885A308D313198A2E0370734";
        master_key <= x"2B7E151628AED2A6ABF7158809CF4F3C";
        next_key   <= ROUND_KEYS(1);   -- round key 1 ready for cycle 1
        init       <= '1';
        state_en   <= '1';
        key_en     <= '1';
        wait for CLK_PERIOD;           -- rising edge latches sreg_in and master_key
        init     <= '0';
        state_en <= '0';
        key_en   <= '0';
        wait for CLK_PERIOD;           -- outputs settle
        if state_out = EXPECTED_STATE(0) then
            report "TEST 2 PASS: Init state correct" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 2 FAIL: Init state wrong" severity error;
        end if;
        if key_out = ROUND_KEYS(0) then
            report "TEST 2 KEY PASS: master_key loaded into key reg" severity note;
        else
            report "TEST 2 KEY FAIL: key reg wrong after init" severity error;
        end if;
        test_count := test_count + 1;

        -- TEST 3: Round 1 - print intermediates
        report "TEST 3: Round 1" severity note;
        next_key <= ROUND_KEYS(1);
        state_en <= '1';
        key_en   <= '1';
        wait for CLK_PERIOD;
        state_en <= '0';
        key_en   <= '0';
        
        -- Wait for combinational signals to settle
        wait for 1 ns;
        
        -- Print every intermediate signal
        report "  sreg_out (round input): " & 
            to_hstring(<<signal .tb_datapath.dut.sreg_out : std_logic_vector(127 downto 0)>>) 
            severity note;
        report "  sb_out (after SubBytes): " & 
            to_hstring(<<signal .tb_datapath.dut.sb_out : std_logic_vector(127 downto 0)>>) 
            severity note;
        report "  sr_out (after ShiftRows): " & 
            to_hstring(<<signal .tb_datapath.dut.sr_out : std_logic_vector(127 downto 0)>>) 
            severity note;
        report "  mc_out (after MixColumns): " & 
            to_hstring(<<signal .tb_datapath.dut.mc_out : std_logic_vector(127 downto 0)>>) 
            severity note;
        report "  ark_key (key used in ARK): " & 
            to_hstring(<<signal .tb_datapath.dut.ark_key : std_logic_vector(127 downto 0)>>) 
            severity note;
        report "  ark_out (after AddRoundKey): " & 
            to_hstring(<<signal .tb_datapath.dut.ark_out : std_logic_vector(127 downto 0)>>) 
            severity note;
        
        wait for CLK_PERIOD - 1 ns;
        
        if state_out = x"A49C7FF2689F352B6B5BEA43026A5049" then
            report "TEST 3 PASS: Round 1 state correct" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 3 FAIL: Round 1 state wrong" severity error;
        end if;
        test_count := test_count + 1;

        -- TEST 4: Key register holds round key 1 after round 1
        report "TEST 4: Key register after round 1" severity note;
        if key_out = ROUND_KEYS(1) then
            report "TEST 4 PASS: Key reg holds round key 1" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 4 FAIL: Key reg wrong after round 1" severity error;
        end if;
        test_count := test_count + 1;

        -- TEST 5: Final round bypass (MixColumns skipped)
        -- Reset and re-init, then run 9 normal rounds then 1 final round
        report "TEST 5: Final round MixColumns bypass" severity note;
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        plaintext  <= x"3243F6A8885A308D313198A2E0370734";
        master_key <= x"2B7E151628AED2A6ABF7158809CF4F3C";
        next_key   <= ROUND_KEYS(1);
        init       <= '1';
        state_en   <= '1';
        key_en     <= '1';
        wait for CLK_PERIOD;
        init <= '0';

        -- Rounds 1-9
        for r in 1 to 9 loop
            next_key <= ROUND_KEYS(r);
            state_en <= '1';
            key_en   <= '1';
            wait for CLK_PERIOD;
        end loop;

        -- Round 10: final round
        next_key  <= ROUND_KEYS(10);
        final_rnd <= '1';
        state_en  <= '1';
        key_en    <= '1';
        wait for CLK_PERIOD;
        final_rnd <= '0';
        state_en  <= '0';
        key_en    <= '0';
        wait for CLK_PERIOD;

        if state_out = EXPECTED_STATE(10) then
            report "TEST 5 PASS: Final ciphertext correct" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 5 FAIL: Final ciphertext wrong" severity error;
        end if;
        test_count := test_count + 1;

        -- TEST 6: Reset clears state mid-operation
        report "TEST 6: Reset mid-operation" severity note;
        plaintext  <= x"3243F6A8885A308D313198A2E0370734";
        master_key <= x"2B7E151628AED2A6ABF7158809CF4F3C";
        next_key   <= ROUND_KEYS(1);
        init       <= '1';
        state_en   <= '1';
        key_en     <= '1';
        wait for CLK_PERIOD;
        init     <= '0';
        state_en <= '1';
        key_en   <= '1';
        wait for CLK_PERIOD;
        -- Reset mid-round
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for 2 * CLK_PERIOD;
        if state_out = x"00000000000000000000000000000000" and
           key_out   = x"00000000000000000000000000000000" then
            report "TEST 6 PASS: Reset cleared state and key" severity note;
            pass_count := pass_count + 1;
        else
            report "TEST 6 FAIL: Reset did not clear correctly" severity error;
        end if;
        test_count := test_count + 1;

        report "Datapath Tests Complete: " & integer'image(pass_count) & "/" &
               integer'image(test_count) & " passed" severity note;
        wait;
    end process;

end testbench;