library ieee;
use ieee.std_logic_1164.all;

entity shift_rows is 
    port (
        input  : in  std_logic_vector(127 downto 0);
        output : out std_logic_vector(127 downto 0)
    );
end entity;

architecture Behavioral of shift_rows is
begin
    -- C0
    output(7 downto 0) <= input(7 downto 0);        -- b0
    output(15 downto 8) <= input(47 downto 40);      -- b5
    output(23 downto 16) <= input(87 downto 80);      -- b10
    output(31 downto 24) <= input(127 downto 120);    -- b15

    -- C1
    output(39 downto 32) <= input(39 downto 32);      -- b4
    output(47 downto 40) <= input(79 downto 72);      -- b9
    output(55 downto 48) <= input(119 downto 112);    -- b14
    output(63 downto 56) <= input(31 downto 24);      -- b3

    -- C2
    output(71 downto 64) <= input(71 downto 64);      -- b8
    output(79 downto 72) <= input(111 downto 104);    -- b13
    output(87 downto 80) <= input(23 downto 16);      -- b2
    output(95 downto 88) <= input(63 downto 56);      -- b7

    -- C3
    output(103 downto 96) <= input(103 downto 96);     -- b12
    output(111 downto 104) <= input(15 downto 8);       -- b1
    output(119 downto 112) <= input(55 downto 48);      -- b6
    output(127 downto 120) <= input(95 downto 88);      -- b11
end architecture;
