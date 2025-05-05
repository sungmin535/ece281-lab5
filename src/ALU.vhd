library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0)); -- NZCV
end ALU;

architecture Behavioral of ALU is
    constant add : std_logic_vector(2 downto 0) := "000";
    constant subtract : std_logic_vector(2 downto 0) := "001";
    constant and_oper : std_logic_vector(2 downto 0) := "010";
    constant or_oper  : std_logic_vector(2 downto 0) := "011";
    
    signal adding_results : std_logic_vector(8 downto 0);
    signal subtracting_results : std_logic_vector(8 downto 0);
    signal and_results : std_logic_vector(7 downto 0);
    signal or_results  : std_logic_vector(7 downto 0);
    signal output_results : std_logic_vector(7 downto 0);
    signal flagN : std_logic;
    signal flagZ : std_logic;
    signal flagC : std_logic;
    signal flagV : std_logic;
    
begin
    adding_results <= std_logic_vector('0' & unsigned(i_A)+unsigned(i_B));
    subtracting_results <= std_logic_vector('0' & unsigned(i_A)-unsigned(i_B));        
    and_results <= i_A and i_B;
    or_results <= i_A or i_B;
    
    process(i_op,adding_results,subtracting_results,and_results,or_results)
    begin
        case i_op is
            when add =>
                output_results <= adding_results(7 downto 0);
                flagC <= adding_results(8);
                flagV <= (i_A(7) and i_B(7) and not adding_results(7)) or (not i_A(7) and not i_B(7) and adding_results(7));
            when subtract =>
                output_results <= subtracting_results(7 downto 0);
                flagC <= not subtracting_results(8);
                flagV <= (i_A(7) and not i_B(7) and not subtracting_results(7)) or (not i_A(7) and i_B(7) and subtracting_results(7));
            when and_oper =>
                output_results <= and_results;
                flagC <= '0';
                flagV <= '0';
            when or_oper =>
                output_results <= or_results;
                flagC <= '0';
                flagV <= '0';
            when others =>
                output_results <= adding_results(7 downto 0);
                flagC <= '0';
                flagV <= '0';
        end case;
    end process;
    flagN <= output_results(7);
    flagZ <= '1' when output_results = "00000000" else '0';
    o_result <= output_results;
    o_flags <= flagN & flagZ & flagC & flagV;
end Behavioral;