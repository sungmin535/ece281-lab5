library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnL    :   in std_logic; -- clock divider reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led     :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg     :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an      :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
    component clock_divider is
        generic (constant k_DIV : natural := 2);
        port( 
            i_clk : in std_logic;
            i_reset : in std_logic;
            o_clk: out std_logic
         );
    end component;
    
    component controller_fsm is
        port(
            i_reset : in std_logic;
            i_adv : in std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
         );
    end component;
    
    component ALU is
        port (
            i_A : in std_logic_vector(7 downto 0);
            i_B : in std_logic_vector(7 downto 0);
            i_op : in std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component twos_comp is
        port (
            i_bin : in std_logic_vector(7 downto 0);
            o_sign : out std_logic;
            o_hund : out std_logic_vector(3 downto 0);
            o_tens : out std_logic_vector(3 downto 0);
            o_ones : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component TDM4 is
        generic (constant k_WIDTH : natural := 4);
        port(
            i_clk : in std_logic;
            i_reset : in std_logic;
            i_D3 : in std_logic_vector(k_WIDTH -1 downto 0);
            i_D2 : in std_logic_vector(k_WIDTH -1 downto 0);
            i_D1 : in std_logic_vector(k_WIDTH -1 downto 0);
            i_D0 : in std_logic_vector(k_WIDTH -1 downto 0);
            o_data : out std_logic_vector(k_WIDTH -1 downto 0);
            o_sel : out std_logic_vector(3 downto 0)
         );
    end component;
    
    signal btnC_sync : std_logic := '0';
    signal btnC_sync1 : std_logic := '0';
    signal btnC_debounce : std_logic := '0';
    signal btnC_previous : std_logic := '0';
    signal btnC_edge: std_logic := '0';
    signal slow_clk : std_logic;
    signal tdm_clk : std_logic;
    signal fsm_cycle : std_logic_vector(3 downto 0);
    signal oper_A : std_logic_vector(7 downto 0) := (others => '0');
    signal oper_B : std_logic_vector(7 downto 0) := (others => '0');
    signal alu_results : std_logic_vector(7 downto 0);
    signal alu_flags : std_logic_vector(3 downto 0);
    signal display : std_logic_vector(7 downto 0);
    signal negative: std_logic;
    signal hundreds : std_logic_vector(3 downto 0);
    signal tens : std_logic_vector(3 downto 0);
    signal ones : std_logic_vector(3 downto 0);
    signal sign : std_logic_vector(3 downto 0);
    signal displaying_digit : std_logic_vector(3 downto 0);
    signal allow_display : std_logic;
    signal an_display : std_logic_vector(3 downto 0);
    signal display_an_mod : std_logic_vector(3 downto 0); 
    signal flag_negative: std_logic;
    signal flag_zero : std_logic;
    signal flag_carry : std_logic;
    signal flag_overflow : std_logic;
    signal oper_store : std_logic_vector(2 downto 0) := (others => '0');
    signal delay_btnc : std_logic := '0';
    
    constant state_clear  : std_logic_vector(3 downto 0) := "0001";
    constant state_oper1 : std_logic_vector(3 downto 0) := "0010";
    constant state_oper2 : std_logic_vector(3 downto 0) := "0100";
    constant state_results : std_logic_vector(3 downto 0) := "1000";
    

begin
    -- PORT MAPS ----------------------------------------
    clock_div_inst: clock_divider
        generic map ( k_DIV => 125000 )
        port map (
            i_clk => clk,
            i_reset => btnL,
            o_clk => slow_clk
        );

    tdm_clock_div: clock_divider
        generic map ( k_DIV => 50000 )
        port map (
            i_clk  => clk,
            i_reset => btnL,
            o_clk => tdm_clk
        );
    
    controller_fsm_inst: controller_fsm
        port map (
            i_reset => btnU,
            i_adv => btnC_edge,
            o_cycle => fsm_cycle
        );
    
    alu_inst: ALU
        port map (
            i_A  => oper_A,
            i_B  => oper_B,
            i_op => oper_store,
            o_result => alu_results,
            o_flags => alu_flags
       );
    
    twos_comp_inst: twos_comp
        port map (
            i_bin => display,
            o_sign => negative,
            o_hund => hundreds,
            o_tens => tens,
            o_ones => ones
        );
    
    tdm4_inst: TDM4
        generic map ( k_WIDTH => 4)
        port map (
            i_clk => tdm_clk,
            i_reset => btnU,
            i_D3 => sign,
            i_D2 => hundreds,
            i_D1 => tens,
            i_D0 => ones,
            o_data => displaying_digit,
            o_sel => an_display
          );
    
    sign <= "1111";
    flag_negative <= alu_flags(3);
    flag_zero <= alu_flags(2);
    flag_carry <= alu_flags(1);
    flag_overflow <= alu_flags(0);
        
    led(3 downto 0)<= fsm_cycle;
    led(15) <= flag_negative 
        when fsm_cycle = state_results 
        else '0';
    led(14) <= flag_carry 
        when fsm_cycle = state_results 
        else '0';
    led(13) <= flag_overflow 
        when fsm_cycle = state_results 
        else '0';
    led(12) <= flag_zero 
        when fsm_cycle = state_results 
        else '0';
    led(11 downto 4)<= (others => '0');
    
    allow_display <= '0' 
        when fsm_cycle = state_clear 
        else '1';

    display_an_mod <= an_display 
        when (fsm_cycle = state_results and negative = '1') or an_display /= "0111" 
        else "1111";
                      
    an <= "1111" 
        when (allow_display = '0') 
        else display_an_mod;
    

    process(displaying_digit,an_display, negative,fsm_cycle)
        variable decoded_segments : std_logic_vector(6 downto 0);
    begin        
        case displaying_digit is
            when "0000" => decoded_segments := "1000000"; --0
            when "0001" => decoded_segments := "1111001"; --1
            when "0010" => decoded_segments := "0100100"; --2
            when "0011" => decoded_segments := "0110000"; --3
            when "0100" => decoded_segments := "0011001"; --4
            when "0101" => decoded_segments := "0010010"; --5
            when "0110" => decoded_segments := "0000010"; --6
            when "0111" => decoded_segments := "1111000"; --7
            when "1000" => decoded_segments := "0000000"; --8
            when "1001" => decoded_segments := "0010000"; --9
            when "1010" => decoded_segments := "0001000"; --A
            when "1011" => decoded_segments := "0000011"; --b
            when "1100" => decoded_segments := "1000110"; --C
            when "1101" => decoded_segments := "0100001"; --d
            when "1110" => decoded_segments := "0000110"; --E
            when "1111" => decoded_segments := "0001110"; --F
            when others => decoded_segments := "1111111"; --segments off
        end case;
        
        seg<=decoded_segments;
        
        if an_display = "0111" and fsm_cycle = state_results and negative = '1' then
            seg <= "0111111";
        end if;
    end process;
    
    process(slow_clk, btnU)
    begin
        if btnU = '1' then
            btnC_sync <= '0';
            btnC_sync1 <= '0';
            btnC_debounce <= '0';
            btnC_previous <= '0';
            btnC_edge <= '0';
            delay_btnc <= '0';
        elsif rising_edge(slow_clk) then
            btnC_sync <= btnC;
            btnC_sync1 <= btnC_sync;
            btnC_debounce <= btnC_sync1;
            btnC_previous <= btnC_debounce;        
            delay_btnc <= btnC_edge;
            
            if btnC_debounce = '1' and btnC_previous = '0' then
                btnC_edge <= '1';
            else
                btnC_edge <= '0';
            end if;
        end if;
    end process;
    
    process(slow_clk,btnU)
    begin
        if btnU = '1' then
            oper_A <= (others => '0');
            oper_B <= (others => '0');
            oper_store <= (others => '0');
        elsif rising_edge(slow_clk) then
            if delay_btnc = '1' then
                case fsm_cycle is
                    when state_oper1 =>oper_A <= sw(7 downto 0);
                    when state_oper2 =>oper_B <= sw(7 downto 0);
                    when state_results =>oper_store <= sw(2 downto 0);
                    when others =>null;
                end case;
            end if;
        end if;
    end process;

    process(fsm_cycle,oper_A,oper_B,alu_results)
    begin
        display <= (others => '0');
        case fsm_cycle is
            when state_clear => display <= (others => '0');
            when state_oper1 => display <= oper_A;  
            when state_oper2 => display <= oper_B;
            when state_results => display <= alu_results; 
            when others =>display <= (others => '0');
        end case;
    end process;
        
end top_basys3_arch;