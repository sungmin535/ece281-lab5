----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    signal A_s, B_s    : signed(7 downto 0);
    signal R_s         : signed(8 downto 0);
    signal R8          : signed(7 downto 0);
    signal neg_f, zero_f, car_f, ovf_f : std_logic;

begin
    A_s <= signed(i_A);
    B_s <= signed(i_B);

    process(A_s, B_s, i_op)
    begin
        case i_op is
            when "000" =>
                R_s <= resize(A_s, 9) + resize(B_s, 9);
                
            when "001" =>
                R_s <= resize(A_s, 9) - resize(B_s, 9);
                
            when "010" =>
                R_s(7 downto 0) <= A_s and B_s;
                R_s(8) <= '0';
                
            when "011" =>
                R_s(7 downto 0) <= A_s or B_s;
                R_s(8) <= '0';
                
            when others =>
                R_s <= (others => '0');
        end case;
        
        R8 <= R_s(7 downto 0);
        o_result <= std_logic_vector(R8);
        

        neg_f <= R8(7);
        
        if R8 = 0 then
            zero_f <= '1';
        else
            zero_f <= '0';
        end if;
        
        car_f <= R_s(8);
        
        if i_op = "000" then
            if A_s(7) = B_s(7) and R8(7) /= A_s(7) then
                ovf_f <= '1';
            else
                ovf_f <= '0';
            end if;
        elsif i_op = "001" then
            if A_s(7) /= B_s(7) and R8(7) /= A_s(7) then
                ovf_f <= '1';
            else
                ovf_f <= '0';
            end if;
        else
            ovf_f <= '0';
        end if;
        
        o_flags <= neg_f & zero_f & car_f & ovf_f;
    end process;

end Behavioral;