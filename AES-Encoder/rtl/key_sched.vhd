library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity key_schedule is
    port (
        round_key_in  : in  std_logic_vector(127 downto 0);
        rnd_no        : in  std_logic_vector(3 downto 0);
        round_key_out : out std_logic_vector(127 downto 0)
    );
end key_schedule;

architecture Behavioral of key_sched is
    -- Input round key words
    signal w0, w1, w2, w3 : std_logic_vector(31 downto 0);
    
    -- RotWord and SubWord outputs
    signal rot_out, sub_out : std_logic_vector(31 downto 0);

    -- Rcon output and g() output
    signal rcon_val, g_val : std_logic_vector(31 downto 0);

    --New words
    signal nw0, nw1, nw2, nw3 : std_logic_vector(31 downto 0);

    -- S-box component declaration
    component Sbox
        port (
            in_byte  : in  std_logic_vector(7 downto 0);
            out_byte : out std_logic_vector(7 downto 0)
        );
    end component;

begin
    
    -- Split input round key into 4 words
    w0 <= round_key_in(127 downto 96);
    w1 <= round_key_in(95  downto 64);
    w2 <= round_key_in(63  downto 32);
    w3 <= round_key_in(31  downto  0);
    
    -- RotWord: rotate w3 left by one byte
    -- [b0, b1, b2, b3] -> [b1, b2, b3, b0]
    rot_out <= w3(23 downto 0) & w3(31 downto 24);

    -- SubWord: apply Sbox to each byte of rot_out
    sb0 : entity work.Sbox port map (
        in_byte  => rot_out(31 downto 24),
        out_byte => sub_out(31 downto 24)
    );
    sb1 : entity work.Sbox port map (
        in_byte  => rot_out(23 downto 16),
        out_byte => sub_out(23 downto 16)
    );
    sb2 : entity work.Sbox port map (
        in_byte  => rot_out(15 downto 8),
        out_byte => sub_out(15 downto 8)
    );
    sb3 : entity work.Sbox port map (
        in_byte  => rot_out(7 downto 0),
        out_byte => sub_out(7 downto 0)
    );

    -- Rcon lookup (rounds 1-10 for AES-128)
    rcon_proc : process(rnd_no)
    begin
        case rnd_no is
            when x"1"  => rcon_val <= x"01000000";
            when x"2"  => rcon_val <= x"02000000";
            when x"3"  => rcon_val <= x"04000000";
            when x"4"  => rcon_val <= x"08000000";
            when x"5"  => rcon_val <= x"10000000";
            when x"6"  => rcon_val <= x"20000000";
            when x"7"  => rcon_val <= x"40000000";
            when x"8"  => rcon_val <= x"80000000";
            when x"9"  => rcon_val <= x"1B000000";
            when x"A"  => rcon_val <= x"36000000";
            when others => rcon_val <= x"00000000";
        end case;
    end process;

    -- g() function: SubWord XOR Rcon
    g_out <= sub_out xor rcon_val;

    -- Key expansion XOR chain
    nw0 <= w0 xor g_out;
    nw1 <= w1 xor nw0;
    nw2 <= w2 xor nw1;
    nw3 <= w3 xor nw2;

    -- Reassemble output round key
    round_key_out <= nw0 & nw1 & nw2 & nw3;
    
end architecture Behavioral;