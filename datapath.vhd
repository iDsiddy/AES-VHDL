library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.all;

entity datapath is
    port (
        -- Clock & reset
        clk, rst : in  std_logic;

        -- Control inputs (from controller)
        state_en, key_en, final_rnd : in  std_logic;

        -- External inputs
        plaintext, master_key : in  std_logic_vector(127 downto 0);

        -- Key schedule interface
        next_key : in  std_logic_vector(127 downto 0);

        -- Outputs
        state_out, key_out  : out std_logic_vector(127 downto 0)
    );
end datapath;


architecture Behavioral of datapath is
    type state_type is (idle, start);
    signal kreg_out, kreg_in : std_logic_vector(127 downto 0);
    signal sreg_in, sreg_out : std_logic_vector(127 downto 0);
    
    signal sb_out, sr_out, mc_out, pre_ark : std_logic_vector(127 downto 0);
    
    -- Byte Substitution
    component sub_bytes 
        port ( 
            data_in : in std_logic_vector(127 downto 0); 
            data_out : out std_logic_vector(127 downto 0)
        );
    end component;
    
    -- Shift Rows
    component shift_rows is 
        port (
            input  : in  std_logic_vector(127 downto 0);
            output : out std_logic_vector(127 downto 0)
        );
    end component;
    
    -- Mix Columns
    component mix_columns 
        Port (
            in_word : in std_logic_vector(31 downto 0);
            out_word : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Add (XOR) Round Key
    component add_rndkey is
        port (
            in_word : in std_logic_vector(127 downto 0);
            key : in std_logic_vector(127 downto 0);
            output : out std_logic_vector(127 downto 0)
        );
    end component;
    
    -- Round Register
    component rnd_reg is
        port (
            clk, rst: in std_logic;
            d : in std_logic_vector(127 downto 0);  
            q : out std_logic_vector(127 downto 0)  
        );
    end component;
begin
    
    sb : sub_bytes port map (
        data_in => sreg_out,
        data_out => sb_out
    );
    
    sr : shift_rows port map (
        input => sb_out,
        output => sr_out
    );
    
    -- Bypass for Final Round
    pre_ark <= sr_out when final_rnd = '1' else mc_out;
        
    mc_gen : for i in 0 to 3 generate 
        mc_inst : entity work.mix_columns
            port map (
                in_word => sr_out(32*(i) + 31 downto 32*(i)),
                out_word => mc_out(32*(i) + 31 downto 32*(i))
            );
        end generate mc_gen;
    
    ark : add_rndkey port map (
        in_word => pre_ark,
        key => kreg_out,
        output => sreg_in
    );
    
    state_reg : rnd_reg port map(
        clk => clk,
        rst => rst,
        d   => sreg_in,
        q   => sreg_out
    );
    
    key_reg : rnd_reg port map(
        clk => clk,
        rst => rst,
        d   => kreg_in,
        q   => kreg_out
    );

    
    
    
end Behavioral;
