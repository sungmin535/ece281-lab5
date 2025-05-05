----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_clk   : in  STD_LOGIC;           -- Clock input
           i_reset : in  STD_LOGIC;           -- Synchronous reset
           i_btnC  : in  STD_LOGIC;           -- Button to advance state
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0)); -- One-hot state output
end controller_fsm;

architecture FSM of controller_fsm is

    signal state     : std_logic_vector(3 downto 0) := "0001";
    
    signal btnC_sync : std_logic_vector(2 downto 0) := (others => '0');
    
begin

    sync_process: process(i_clk)
    begin
        if rising_edge(i_clk) then
            btnC_sync <= btnC_sync(1 downto 0) & i_btnC;
        end if;
    end process sync_process;
    
    state_process: process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            state <= "0001";
        elsif rising_edge(i_clk) then

            if btnC_sync(2 downto 1) = "01" then
                case state is
                    when "0001" =>
                        state <= "0010";
                    when "0010" =>
                        state <= "0100";
                    when "0100" =>
                        state <= "1000";
                    when "1000" =>
                        state <= "0001";
                    when others =>
                        state <= "0001";
                end case;
            end if;
        end if;
    end process state_process;
    
    o_cycle <= state;
    
end FSM;