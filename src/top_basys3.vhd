--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnL    :   in std_logic; -- asynchronous reset for clock divider
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
    -- Component declarations
    
    component clock_divider is
        generic (
            constant k_DIV : natural := 2
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            o_clk    : out std_logic
        );
    end component clock_divider;
    
    component controller_fsm is
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_btnC   : in std_logic;
            o_cycle  : out std_logic_vector(3 downto 0)
        );
    end component controller_fsm;
    
    component ALU is
        port (
            i_A      : in std_logic_vector(7 downto 0);
            i_B      : in std_logic_vector(7 downto 0);
            i_op     : in std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags  : out std_logic_vector(3 downto 0)
        );
    end component ALU;
    
    component twos_comp is
        port (
            i_bin    : in std_logic_vector(7 downto 0);
            o_sign   : out std_logic;
            o_hund   : out std_logic_vector(3 downto 0);
            o_tens   : out std_logic_vector(3 downto 0);
            o_ones   : out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    component TDM4 is
        generic (
            constant k_WIDTH : natural := 4
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_D3     : in std_logic_vector(k_WIDTH-1 downto 0);
            i_D2     : in std_logic_vector(k_WIDTH-1 downto 0);
            i_D1     : in std_logic_vector(k_WIDTH-1 downto 0);
            i_D0     : in std_logic_vector(k_WIDTH-1 downto 0);
            o_data   : out std_logic_vector(k_WIDTH-1 downto 0);
            o_sel    : out std_logic_vector(3 downto 0)
        );
    end component TDM4;
    
    
    signal w_clk_div    : std_logic;
    signal w_cycle      : std_logic_vector(3 downto 0);
    
    -- ALU signals
    signal f_A, f_B     : std_logic_vector(7 downto 0);
    signal w_result     : std_logic_vector(7 downto 0);
    signal w_flags      : std_logic_vector(3 downto 0); 
    
    -- Display signals
    signal w_sign       : std_logic;
    signal w_hund       : std_logic_vector(3 downto 0);
    signal w_tens       : std_logic_vector(3 downto 0);
    signal w_ones       : std_logic_vector(3 downto 0);
    signal c_conv_in    : std_logic_vector(7 downto 0);
    signal w_data4      : std_logic_vector(3 downto 0); 
    signal w_sign_digit : std_logic_vector(3 downto 0);
    
begin
    -- PORT MAPS ----------------------------------------
    
    clk_div_inst: clock_divider 
        generic map (
            k_DIV => 50000  -- Adjust for proper debouncing
        )
        port map (
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => w_clk_div
        );
    
    fsm_inst: controller_fsm
        port map (
            i_clk   => w_clk_div,
            i_reset => btnU,
            i_btnC  => btnC,
            o_cycle => w_cycle
        );
    
    alu_inst: ALU
        port map (
            i_A      => f_A,
            i_B      => f_B,
            i_op     => sw(2 downto 0),
            o_result => w_result,
            o_flags  => w_flags
        );
    
    twos_comp_inst: twos_comp
        port map (
            i_bin   => c_conv_in,
            o_sign  => w_sign,
            o_hund  => w_hund,
            o_tens  => w_tens,
            o_ones  => w_ones
        );
    
    w_sign_digit <= w_sign & "000";
    
    tdm_inst: TDM4
        generic map (
            k_WIDTH => 4
        )
        port map (
            i_clk   => w_clk_div,
            i_reset => btnU,
            i_D0    => w_ones,
            i_D1    => w_tens,
            i_D2    => w_hund,
            i_D3    => w_sign_digit,
            o_data  => w_data4,
            o_sel   => an
        );
    
    -- CONCURRENT STATEMENTS ----------------------------
    
    c_conv_in <= 
        f_A when w_cycle = "0010" else
        f_B when w_cycle = "0100" else
        w_result when w_cycle = "1000" else
        (others => '0');
    
    -- Register A/B process
    process(w_clk_div)
    begin
        if rising_edge(w_clk_div) then
            if btnU = '1' then
                f_A <= (others => '0');
                f_B <= (others => '0');
            else
                
                if w_cycle = "0010" then
                    f_A <= sw(7 downto 0);
                elsif w_cycle = "0100" then
                    f_B <= sw(7 downto 0);
                end if;
            end if;
        end if;
    end process;
    
process(w_data4, w_cycle)
begin
    if w_cycle = "0001" and w_data4(3) = '0' then
        seg <= "1111111"; 
    else
        case w_data4 is
            when "0000" => seg <= "1000000";  -- 0
            when "0001" => seg <= "1111001";  -- 1
            when "0010" => seg <= "0100100";  -- 2
            when "0011" => seg <= "0110000";  -- 3
            when "0100" => seg <= "0011001";  -- 4
            when "0101" => seg <= "0010010";  -- 5
            when "0110" => seg <= "0000010";  -- 6
            when "0111" => seg <= "1111000";  -- 7
            when "1000" => seg <= "0000000";  -- 8 
            when "1001" => seg <= "0011000";  -- 9
            when others => seg <= "1111111";  
        end case;
    end if;
end process;

    led(3 downto 0) <= w_cycle; 
    led(15 downto 12) <= w_flags;
    led(11 downto 4) <= (others => '0');
    
end top_basys3_arch;