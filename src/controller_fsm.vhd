library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    constant state_clear : std_logic_vector(3 downto 0) := "0001";
    constant state_oper1: std_logic_vector(3 downto 0) := "0010";
    constant state_oper2 : std_logic_vector(3 downto 0) := "0100";
    constant state_results : std_logic_vector(3 downto 0) := "1000";
    signal current_state : std_logic_vector(3 downto 0) := state_clear;
begin
    process(i_reset,i_adv)
    begin
        if i_reset = '1' then current_state <= state_clear;
        elsif rising_edge(i_adv) then
            case current_state is
                when state_clear =>current_state <= state_oper1;
                when state_oper1 =>current_state <= state_oper2;
                when state_oper2 =>current_state <= state_results;
                when state_results =>current_state <= state_clear;
                when others =>current_state <= state_clear;
            end case;
        end if;
    end process;
    o_cycle <= current_state;
    
end FSM;