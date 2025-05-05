library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    -- Internal signals
    signal A_s, B_s    : signed(7 downto 0) := (others => '0');
    signal R_s         : signed(8 downto 0) := (others => '0');
    signal R8          : signed(7 downto 0) := (others => '0');
    signal neg_f, zero_f, car_f, ovf_f : std_logic := '0';
begin
    -- Convert inputs to signed
    A_s <= signed(i_A);
    B_s <= signed(i_B);

    process(A_s, B_s, i_op)
    begin
        -- Perform operation based on opcode
        case i_op is
            when "000" =>  -- Addition
                R_s <= resize(A_s, 9) + resize(B_s, 9);
                
            when "001" =>  -- Subtraction
                R_s <= resize(A_s, 9) - resize(B_s, 9);
                
            when "010" =>  -- AND
                R_s(7 downto 0) <= A_s and B_s;
                R_s(8) <= '0';
                
            when "011" =>  -- OR
                R_s(7 downto 0) <= A_s or B_s;
                R_s(8) <= '0';
                
            when others =>  -- Default case
                R_s <= (others => '0');
        end case;
        
        -- Truncate to 8 bits for result
        R8 <= R_s(7 downto 0);
        
        -- Zero flag
        if R8 = 0 then
            zero_f <= '1';
        else
            zero_f <= '0';
        end if;
        
        -- Negative flag
        neg_f <= R8(7);
        
        -- Carry flag
        car_f <= R_s(8);
        
        -- Overflow flag
        if i_op = "000" then  -- Addition
            -- Overflow occurs when adding two numbers with same sign but result has different sign
            if A_s(7) = B_s(7) and R8(7) /= A_s(7) then
                ovf_f <= '1';
            else
                ovf_f <= '0';
            end if;
        elsif i_op = "001" then  -- Subtraction
            -- Overflow for subtraction: operands with different signs and result sign differs from A
            if A_s(7) /= B_s(7) and R8(7) /= A_s(7) then
                ovf_f <= '1';
            else
                ovf_f <= '0';
            end if;
        else  -- Logical operations
            ovf_f <= '0';
        end if;
    end process;
    
    -- Assign outputs outside the process
    o_result <= std_logic_vector(R8);
    o_flags <= neg_f & zero_f & car_f & ovf_f;  -- NZCV format
end Behavioral;