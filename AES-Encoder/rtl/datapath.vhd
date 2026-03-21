library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.all;

entity datapath is
    port (
        -- Clock & reset
        clk        : in  std_logic;
        rst        : in  std_logic;
        -- Control signals (from controller, thin 1-bit wires)
        state_en   : in  std_logic;
        key_en     : in  std_logic;
        final_rnd  : in  std_logic;
        init       : in  std_logic;  -- selects plaintext on round 0
        -- Data inputs
        plaintext  : in  std_logic_vector(127 downto 0);
        master_key : in  std_logic_vector(127 downto 0);
        next_key   : in  std_logic_vector(127 downto 0);
        -- Outputs
        state_out  : out std_logic_vector(127 downto 0);
        key_out    : out std_logic_vector(127 downto 0)
    );
end datapath;

architecture Behavioral of datapath is

    signal sb_out, sr_out, mc_out, pre_ark  : std_logic_vector(127 downto 0);
    signal sreg_in, sreg_out                : std_logic_vector(127 downto 0);
    signal kreg_out                         : std_logic_vector(127 downto 0);
    signal ark_out                          : std_logic_vector(127 downto 0);

    component sub_bytes
        port (
            data_in  : in  std_logic_vector(127 downto 0);
            data_out : out std_logic_vector(127 downto 0)
        );
    end component;

    component shift_rows
        port (
            input  : in  std_logic_vector(127 downto 0);
            output : out std_logic_vector(127 downto 0)
        );
    end component;

    component mix_columns
        port (
            in_word  : in  std_logic_vector(31 downto 0);
            out_word : out std_logic_vector(31 downto 0)
        );
    end component;

    component add_rndkey
        port (
            in_word : in  std_logic_vector(127 downto 0);
            key     : in  std_logic_vector(127 downto 0);
            output  : out std_logic_vector(127 downto 0)
        );
    end component;

begin

    -- MUX: load plaintext on round 0, feedback on rounds 1-10
    sreg_in <= (plaintext xor master_key) when init = '1' else ark_out;

    -- State register (enabled by controller)
    state_reg : process(clk, rst)
    begin
        if rst = '1' then
            sreg_out <= (others => '0');
        elsif rising_edge(clk) then
            if state_en = '1' then
                sreg_out <= sreg_in;
            end if;
        end if;
    end process;

    -- Key register (enabled by controller)
    key_reg : process(clk, rst)
    begin
        if rst = '1' then
            kreg_out <= (others => '0');
        elsif rising_edge(clk) then
            if key_en = '1' then
                kreg_out <= next_key;
            end if;
        end if;
    end process;

    -- Stage 1: SubBytes
    sb : sub_bytes port map (
        data_in  => sreg_out,
        data_out => sb_out
    );

    -- Stage 2: ShiftRows
    sr : shift_rows port map (
        input  => sb_out,
        output => sr_out
    );

    -- Stage 3: MixColumns (bypassed on final round)
    mc_gen : for i in 0 to 3 generate
        mc_inst : entity work.mix_columns
            port map (
                in_word  => sr_out(32*i + 31 downto 32*i),
                out_word => mc_out(32*i + 31 downto 32*i)
            );
    end generate mc_gen;

    pre_ark <= sr_out when final_rnd = '1' else mc_out;

    -- Stage 4: AddRoundKey
    ark : add_rndkey port map (
        in_word => pre_ark,
        key     => kreg_out,
        output  => ark_out
    );

    -- Drive outputs
    state_out <= sreg_out;
    key_out   <= kreg_out;

end Behavioral;