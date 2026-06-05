library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ALL;

entity device is 
    port (
        plaintext, master_key : in std_logic_vector(127 downto 0);
        ciphertext : out std_logic_vector(127 downto 0);
        clk, rst, start : in std_logic;
        done : out std_logic
    );
end entity;


architecture Behavioral of device is

    -- Controller outputs / Datapath control
    signal state_en   : std_logic;
    signal key_en     : std_logic;
    signal final_rnd  : std_logic;
    signal init       : std_logic;
    signal rnd_no     : std_logic_vector(3 downto 0);

    -- Datapath signals
    signal state_out, key_out : std_logic_vector(127 downto 0);

    -- Key Schedule output
    signal next_key : std_logic_vector(127 downto 0);

    component controller is
        port (
            clk, rst, start : in std_logic;
            state_en, key_en, final_rnd, init : out std_logic;
            rnd_no : out std_logic_vector(3 downto 0);
            done : out std_logic
        );
    end component;

    component datapath is
        port (
            clk, rst : in std_logic;
            state_en, key_en, final_rnd, init : in std_logic;
            plaintext, master_key : in std_logic_vector(127 downto 0);
            next_key : in std_logic_vector(127 downto 0);
            state_out, key_out : out std_logic_vector(127 downto 0)
        );
    end component;

    component key_schedule is
        port (
            clk, rst : in std_logic;
            key_en : in std_logic;
            rnd_no : in std_logic_vector(3 downto 0);
            prev_key : in std_logic_vector(127 downto 0);
            next_key : out std_logic_vector(127 downto 0)
        );
    end component;
begin

    ctrl : controller
        port map (
            clk => clk,
            rst => rst,
            start => start,
            state_en => state_en,
            key_en => key_en,
            final_rnd => final_rnd,
            init => init,
            rnd_no => rnd_no,
            done => done
        );

    dp : datapath
        port map (
            clk => clk,
            rst => rst,
            state_en => state_en,
            key_en => key_en,
            final_rnd => final_rnd,
            init => init,
            plaintext => plaintext,
            master_key => master_key,
            next_key => next_key,
            state_out => state_out,
            key_out => key_out
        );

    ks : key_schedule
        port map (
            clk => clk,
            rst => rst,
            key_en => key_en,
            rnd_no => rnd_no,
            prev_key => key_out,
            next_key => next_key
        );

     -- Ciphertext is valid when done = '1'
    ciphertext <= state_out;

end architecture Behavioral;