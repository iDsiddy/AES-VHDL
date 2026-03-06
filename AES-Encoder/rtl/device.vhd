library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_BIT.ALL;
use work.ALL;


-- 128-bit key based block cipher
entity AES_block is 
    port (
        plaintext, master_key : in std_logic_vector(127 downto 0);
        ciphertext : out std_logic_vector(127 downto 0);
        clk, rst, start : in std_logic;
        done : out std_logic
    );
end entity;


architecture Behavioral of AES_block is
begin


end architecture;