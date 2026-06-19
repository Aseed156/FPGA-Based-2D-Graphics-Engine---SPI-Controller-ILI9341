library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_components.all;
 
entity Graphics_Accelerator is
    port (
        clk       : in  std_logic;
		  reset     : in  std_logic;
        lcd_sdo   : in  std_logic;
        lcd_sck   : out std_logic;
        lcd_sdi   : out std_logic;
        lcd_dc    : out std_logic;
        lcd_reset : out std_logic;
        lcd_cs    : out std_logic;
		  switches  : in  std_logic_vector(1 downto 0);
		  user_in   : in std_logic;
        leds      : out std_logic_vector(3 downto 0)
    );
end Graphics_Accelerator;
 
architecture RTL of Graphics_Accelerator is

--RGB565 Colors
    constant BLACK   : std_logic_vector(15 downto 0) := x"0000";
    constant WHITE   : std_logic_vector(15 downto 0) := x"FFFF";
    constant RED     : std_logic_vector(15 downto 0) := x"F800";
    constant GREEN   : std_logic_vector(15 downto 0) := x"07E0";
    constant BLUE    : std_logic_vector(15 downto 0) := x"001F";
    constant YELLOW  : std_logic_vector(15 downto 0) := x"FFE0";
    constant CYAN    : std_logic_vector(15 downto 0) := x"07FF";
    constant MAGENTA : std_logic_vector(15 downto 0) := x"F81F";
    constant ORANGE  : std_logic_vector(15 downto 0) := x"FD20";
    constant PURPLE  : std_logic_vector(15 downto 0) := x"8010";
 
    -- Clock domain signals produced by the PLL.
    -- lcd_clk  : ~100 MHz — drives the TFT SPI module.
    -- clk_10khz: ~10 kHz  — feeds the game-clock divider.
    signal lcd_clk   : std_logic;
    signal clk_10khz : std_logic;
    signal gameClk   : std_logic;
 
    -- Framebuffer address and clock from the LCD driver.
    signal fbClk : std_logic;
 
    --Count Pixel bounds
    signal x : unsigned(8 downto 0) := (others => '0');  -- 0..319
    signal y : unsigned(7 downto 0) := (others => '0');  -- 0..239
 
    -- Ball hit-test outputs.
    signal b1, b2, b3, b4 : std_logic;
	 
	 --Rectangle hit test Outputs
	 signal rec_1, rec_2, rec_3, rec_4 : std_logic;
 
    -- Text overlay hit signal
    signal text_hit : std_logic;
	 
	 --Pong Signals
	 signal pg_b, pg_left, pg_right : std_logic;
 
    -- Composed RGB565 pixel value.
    signal currentPixel : std_logic_vector(15 downto 0);
 
    -- ALTPLL exposes a 5-wide clock output bus; we use index 0 and 1.
      --PLL signals
    signal pll_clk   : std_logic_vector(4 downto 0);
    signal pll_inclk : std_logic_vector(1 downto 0);

 
   
 
begin
 
   
    leds <= not "1000";
    pll_inclk <= '0' & clk;

 
    
    -- PLL: ALTPLL megafunction (Cyclone V, 50 MHz in)
    --   clk(0) = 100 MHz  → lcd_clk
    --   clk(1) = 10  kHz  → clk_10khz (game clock source)
    -- inclk(1) tied to '0' (only inclk0 used in NORMAL mode).
  
    PLL_INST : altpll
        generic map (
            bandwidth_type          => "AUTO",
            clk0_divide_by          => 1,
            clk0_duty_cycle         => 50,
            clk0_multiply_by        => 2,
            clk0_phase_shift        => "0",
            clk1_divide_by          => 10000,
            clk1_duty_cycle         => 50,
            clk1_multiply_by        => 2,
            clk1_phase_shift        => "0",
            compensate_clock        => "CLK0",
            inclk0_input_frequency  => 20000,
            intended_device_family  => "Cyclone V",
            lpm_hint                => "CBX_MODULE_PREFIX=pll",
            lpm_type                => "altpll",
            operation_mode          => "NORMAL",
            pll_type                => "AUTO",
            port_activeclock        => "PORT_UNUSED",
            port_areset             => "PORT_UNUSED",
            port_clkbad0            => "PORT_UNUSED",
            port_clkbad1            => "PORT_UNUSED",
            port_clkloss            => "PORT_UNUSED",
            port_clkswitch          => "PORT_UNUSED",
            port_configupdate       => "PORT_UNUSED",
            port_fbin               => "PORT_UNUSED",
            port_inclk1             => "PORT_UNUSED",
            port_locked             => "PORT_UNUSED",
            port_pfdena             => "PORT_UNUSED",
            port_phasecounterselect => "PORT_UNUSED",
            port_phasedone          => "PORT_UNUSED",
            port_phasestep          => "PORT_UNUSED",
            port_phaseupdown        => "PORT_UNUSED",
            port_pllena             => "PORT_UNUSED",
            port_scanaclr           => "PORT_UNUSED",
            port_scanclk            => "PORT_UNUSED",
            port_scanclkena         => "PORT_UNUSED",
            port_scandata           => "PORT_UNUSED",
            port_scandataout        => "PORT_UNUSED",
            port_scandone           => "PORT_UNUSED",
            port_scanread           => "PORT_UNUSED",
            port_scanwrite          => "PORT_UNUSED",
            port_clk0               => "PORT_USED",
            port_clk1               => "PORT_USED",
            port_clk2               => "PORT_UNUSED",
            port_clk3               => "PORT_UNUSED",
            port_clk4               => "PORT_UNUSED",
            port_clk5               => "PORT_UNUSED",
            port_clkena0            => "PORT_UNUSED",
            port_clkena1            => "PORT_UNUSED",
            port_clkena2            => "PORT_UNUSED",
            port_clkena3            => "PORT_UNUSED",
            port_clkena4            => "PORT_UNUSED",
            port_clkena5            => "PORT_UNUSED",
            self_reset_on_loss_lock => "OFF",
            width_clock             => 5
        )
        port map (
            inclk => pll_inclk,   -- inclk(1)='0' unused, inclk(0)=board clk
            clk   => pll_clk
        );
 
    lcd_clk   <= pll_clk(0);   -- 100 MHz
    clk_10khz <= pll_clk(1);   -- 10 kHz
 

    -- Game clock: divide clk_10khz by 80  =>  ~125 Hz physics tick
   
    GAME_CLK_DIV : clk_div
        generic map (div => 8000, bitSize => 13)
        port map (clk_in => clk_10khz, clk_out => gameClk);
 

    -- Pixel address counter 
    process(fbClk, reset)
    begin
	     if reset='1' then
		     x<=(others=>'0');
			  y<=(others=>'0');
			  
         elsif rising_edge(fbClk) then
                if x = 319 then
                   x <= (others => '0');
                   if y = 239 then
                      y <= (others => '0');
                   else
                      y <= y + 1;
                   end if;
                else
                   x <= x + 1;
                end if;
         end if;
    end process;
 

    -- Ball instances
 
    BALL1 : ball generic map (X => 240, Y => 200, VX =>  3, RADIUS => 20)
        port map (checkX => x, checkY => y, isSet => b1, physicsClk => gameClk, reset=>reset);
 
    BALL2 : ball generic map (X => 120, Y => 130, VX => -4, RADIUS => 10)
        port map (checkX => x, checkY => y, isSet => b2, physicsClk => gameClk, reset=>reset);

    BALL3 : ball generic map (X => 100, Y => 200, VX =>  5, RADIUS => 40)
        port map (checkX => x, checkY => y, isSet => b3, physicsClk => gameClk, reset=>reset);
 
    BALL4 : ball generic map (X => 300, Y => 130, VX => -2, RADIUS => 30)
        port map (checkX => x, checkY => y, isSet => b4, physicsClk => gameClk, reset=>reset);	  
		  
		  
 
 
	-- Rectangle instances
	RECTANGLE_1 : rectangle generic map(X => 80, Y => 150, VX=>1, WIDTH_R=>20, HEIGHT_R=>20)
	     port map (checkX=>x, checkY=> y, isSet=>rec_1, physicsClk=> gameClk, reset=>reset);
		  
	RECTANGLE_2 : rectangle generic map(X => 180, Y => 100, VX=>2, WIDTH_R=>10, HEIGHT_R=>10)
	     port map (checkX=>x, checkY=> y, isSet=>rec_2, physicsClk=> gameClk, reset=>reset);
		  
	RECTANGLE_3 : rectangle generic map(X => 200, Y => 100, VX=>3, WIDTH_R=>30, HEIGHT_R=>30)
	     port map (checkX=>x, checkY=> y, isSet=>rec_3, physicsClk=> gameClk, reset=>reset);
		  
	RECTANGLE_4 : rectangle generic map(X => 2500, Y => 180, VX=>4, WIDTH_R=>20, HEIGHT_R=>20)
	     port map (checkX=>x, checkY=> y, isSet=>rec_4, physicsClk=> gameClk, reset=>reset);	  
		 	 

    -- Text overlay: "Aseed Faisal  centred on screen
	 --                FA23-BCE-022"      
    TEXT_INST : text_overlay
        port map (checkX => x, checkY => y, isSet => text_hit);
	
    --Pong Instance	
	 MY_PONG  : pong
       port map (checkX => x, checkY=> y, ball_isSet=> pg_b,user_input=> user_in, physicsClk=>gameClk, reset=>reset, lp_isSet=> pg_left, rp_isSet=>pg_right); 	 
 

 process(user_in, pg_b, pg_left, pg_right, switches,text_hit, rec_1, rec_2,rec_3, rec_4, b1, b2,b3,b4,y,x)
begin
  case switches is
    when "00" =>
         if text_hit='1' then
            currentPixel <= WHITE;
			else 
			   currentPixel <=BLUE;	
		   end if;
	 when "01" =>	
        if rec_1='1' then
           currentPixel <= ORANGE;
        elsif rec_2='1' then
           currentPixel <= YELLOW;
        elsif b1='1' then
           currentPixel <= RED;
        elsif b2='1' then
           currentPixel <= BLUE;
		  elsif rec_3='1' then
           currentPixel <= CYAN;
        elsif b3='1' then
           currentPixel <= MAGENTA;
        elsif rec_4='1' then
           currentPixel <= BLUE;
		  elsif b4='1' then
	        currentPixel <= PURPLE;	  
        else
        currentPixel <= BLACK;
        end if;
		  
	 when "10" =>
	     if text_hit='1' then
            currentPixel <= WHITE;
		  elsif rec_1='1' then
           currentPixel <= ORANGE;
        elsif rec_2='1' then
           currentPixel <= YELLOW;
        elsif b1='1' then
           currentPixel <= RED;
        elsif b2='1' then
           currentPixel <= BLUE;
        else
        currentPixel <= BLACK;
        end if;
		  
	  when "11" =>
       if pg_b='1' then
          currentPixel<=BLUE;
	    elsif pg_left='1' then
          currentPixel<=RED;
       elsif pg_right='1' then
          currentPixel<=PURPLE;
	    else
          currentPixel<=BLACK;
	    end if;
     when others => null;
  end case;	  
        	 
end process;


    -- LCD Controller driver
    LCD_INST : LCD_Controller
        generic map (INPUT_CLK_MHZ => 100)
        port map (
            clk             => lcd_clk,
				reset           => reset,
            lcd_sdo         => lcd_sdo,
            lcd_sck         => lcd_sck,
            lcd_sdi         => lcd_sdi,
            lcd_dc          => lcd_dc,
            lcd_reset       => lcd_reset,
            lcd_cs          => lcd_cs,
            framebuffer_data => currentPixel,
            framebuffer_clk  => fbClk
        );
 
end architecture;
