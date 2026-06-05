library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mix_columns is
    port (
        in_word  : in  std_logic_vector(31 downto 0);
        out_word : out std_logic_vector(31 downto 0)
    );
end mix_columns;

architecture Behavioral of mix_columns is
    signal s0, s1, s2, s3         : std_logic_vector(7 downto 0);
    signal m20, m21, m22, m23     : std_logic_vector(7 downto 0);  -- xtime (×2)
    signal m30, m31, m32, m33     : std_logic_vector(7 downto 0);  -- ×3 = xtime XOR self
begin

    -- Split input word (MSB first)
    s0 <= in_word(31 downto 24);
    s1 <= in_word(23 downto 16);
    s2 <= in_word(15 downto  8);
    s3 <= in_word( 7 downto  0);

    -- xtime: multiply each byte by 2 in GF(2^8)
    m20 <= (s0(6 downto 0) & '0') xor x"1B" when s0(7) = '1' else (s0(6 downto 0) & '0');
    m21 <= (s1(6 downto 0) & '0') xor x"1B" when s1(7) = '1' else (s1(6 downto 0) & '0');
    m22 <= (s2(6 downto 0) & '0') xor x"1B" when s2(7) = '1' else (s2(6 downto 0) & '0');
    m23 <= (s3(6 downto 0) & '0') xor x"1B" when s3(7) = '1' else (s3(6 downto 0) & '0');

    -- ×3 = xtime XOR self
    m30 <= m20 xor s0;
    m31 <= m21 xor s1;
    m32 <= m22 xor s2;
    m33 <= m23 xor s3;

    -- MixColumns matrix multiplication
    -- | 2 3 1 1 |   | s0 |
    -- | 1 2 3 1 | × | s1 |
    -- | 1 1 2 3 |   | s2 |
    -- | 3 1 1 2 |   | s3 |
    out_word(31 downto 24) <= m20 xor m31 xor s2  xor s3;
    out_word(23 downto 16) <= s0  xor m21 xor m32 xor s3;
    out_word(15 downto  8) <= s0  xor s1  xor m22 xor m33;
    out_word( 7 downto  0) <= m30 xor s1  xor s2  xor m23;

end Behavioral;