library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity datapath is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        -- Control Signals
        state_en   : in  std_logic;
        key_en     : in  std_logic;
        final_rnd  : in  std_logic;
        init       : in  std_logic;
        -- Inputs 
        plaintext  : in  std_logic_vector(127 downto 0);
        master_key : in  std_logic_vector(127 downto 0);
        next_key   : in  std_logic_vector(127 downto 0);
        -- Outputs
        state_out  : out std_logic_vector(127 downto 0);
        key_out    : out std_logic_vector(127 downto 0)
    );
end datapath;

architecture Behavioral of datapath is

    signal sb_out, sr_out, mc_out, pre_ark : std_logic_vector(127 downto 0);
    signal sreg_in, sreg_out               : std_logic_vector(127 downto 0);
    signal kreg_out                        : std_logic_vector(127 downto 0);
    signal ark_out                         : std_logic_vector(127 downto 0);
    signal ark_key                         : std_logic_vector(127 downto 0);

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

    -- State MUX: plaintext XOR master_key on init, round feedback otherwise
    sreg_in <= (plaintext xor master_key) when init = '1' else ark_out;

    -- State register
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

    -- Key register: holds previous round key for key schedule to expand from
    -- On init: load master_key so key schedule can produce round key 1
    -- On rounds: load next_key (round key just produced) for next expansion
    key_reg : process(clk, rst)
    begin
        if rst = '1' then
            kreg_out <= (others => '0');
        elsif rising_edge(clk) then
            if key_en = '1' then
                if init = '1' then
                    kreg_out <= master_key;
                else
                    kreg_out <= next_key;
                end if;
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

    -- AddRoundKey uses next_key on rounds 1-10 (freshly computed this cycle)
    -- On init cycle the state is loaded directly so ark_out is not used
    ark_key <= master_key when init = '1' else next_key;

    -- Stage 4: AddRoundKey
    ark : add_rndkey port map (
        in_word => pre_ark,
        key     => ark_key,
        output  => ark_out
    );

    -- key_out feeds back into key_schedule as prev_key
    key_out   <= kreg_out;
    state_out <= sreg_out;

end Behavioral;