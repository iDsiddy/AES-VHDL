library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mix_columns is
    Port (
        in_word : in std_logic_vector(31 downto 0);
        out_word : out std_logic_vector(31 downto 0)
    );
end mix_columns;

architecture Behavioral of mix_columns is
    signal s0, s1, s2, s3 : std_logic_vector(7 downto 0);
    signal m20, m21, m22, m23 : std_logic_vector(7 downto 0);
    signal m30, m31, m32, m33 : std_logic_vector(7 downto 0); 
begin

s0 <= in_word(31 downto 24);
s1 <= in_word(23 downto 16);
s2 <= in_word(15 downto 8);
s3 <= in_word(7 downto 0);

m20 <= std_logic_vector(unsigned(s0) sll 1) xor x"1B" when (s0(7) = '1') else std_logic_vector(unsigned(s0) sll 1);
m21 <= std_logic_vector(unsigned(s1) sll 1) xor x"1B" when (s1(7) = '1') else std_logic_vector(unsigned(s1) sll 1);
m22 <= std_logic_vector(unsigned(s2) sll 1) xor x"1B" when (s2(7) = '1') else std_logic_vector(unsigned(s2) sll 1);   
m23 <= std_logic_vector(unsigned(s3) sll 1) xor x"1B" when (s3(7) = '1') else std_logic_vector(unsigned(s3) sll 1);
        
m30 <= m20 xor s0;
m31 <= m21 xor s1;
m32 <= m22 xor s2;
m33 <= m23 xor s3;
        
out_word(7 downto 0) <= m20 xor m31 xor s2 xor s3;
out_word(15 downto 8) <= s0 xor m21 xor m32 xor s3;
out_word(23 downto 16) <= s0 xor s1 xor m22 xor m33;
out_word(31 downto 24) <= m30 xor s1 xor s2 xor m23;

end Behavioral;
