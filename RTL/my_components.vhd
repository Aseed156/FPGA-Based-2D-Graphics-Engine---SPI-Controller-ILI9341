library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package my_components is

   -- ALTPLL megafunction
    --   Parameters below configure:
    --   inclk0 = 50 MHz  (period = 20000 ps)
    --   c0     = 100 MHz (M=2, N=1, C0_div=1)  → TFT SPI clock
    --   c1     = 10 kHz  (M=2, N=1, C1_div=10000) → game-clock source
    component altpll
        generic (
            bandwidth_type          : string  := "AUTO";
            clk0_divide_by          : natural := 1;
            clk0_duty_cycle         : natural := 50;
            clk0_multiply_by        : natural := 2;
            clk0_phase_shift        : string  := "0";
            clk1_divide_by          : natural := 10000;
            clk1_duty_cycle         : natural := 50;
            clk1_multiply_by        : natural := 2;
            clk1_phase_shift        : string  := "0";
            compensate_clock        : string  := "CLK0";
            inclk0_input_frequency  : natural := 20000;
            intended_device_family  : string  := "Cyclone V";
            lpm_hint                : string  := "CBX_MODULE_PREFIX=pll";
            lpm_type                : string  := "altpll";
            operation_mode          : string  := "NORMAL";
            pll_type                : string  := "AUTO";
            port_activeclock        : string  := "PORT_UNUSED";
            port_areset             : string  := "PORT_UNUSED";
            port_clkbad0            : string  := "PORT_UNUSED";
            port_clkbad1            : string  := "PORT_UNUSED";
            port_clkloss            : string  := "PORT_UNUSED";
            port_clkswitch          : string  := "PORT_UNUSED";
            port_configupdate       : string  := "PORT_UNUSED";
            port_fbin               : string  := "PORT_UNUSED";
            port_inclk1             : string  := "PORT_UNUSED";
            port_locked             : string  := "PORT_UNUSED";
            port_pfdena             : string  := "PORT_UNUSED";
            port_phasecounterselect : string  := "PORT_UNUSED";
            port_phasedone          : string  := "PORT_UNUSED";
            port_phasestep          : string  := "PORT_UNUSED";
            port_phaseupdown        : string  := "PORT_UNUSED";
            port_pllena             : string  := "PORT_UNUSED";
            port_scanaclr           : string  := "PORT_UNUSED";
            port_scanclk            : string  := "PORT_UNUSED";
            port_scanclkena         : string  := "PORT_UNUSED";
            port_scandata           : string  := "PORT_UNUSED";
            port_scandataout        : string  := "PORT_UNUSED";
            port_scandone           : string  := "PORT_UNUSED";
            port_scanread           : string  := "PORT_UNUSED";
            port_scanwrite          : string  := "PORT_UNUSED";
            port_clk0               : string  := "PORT_USED";
            port_clk1               : string  := "PORT_USED";
            port_clk2               : string  := "PORT_UNUSED";
            port_clk3               : string  := "PORT_UNUSED";
            port_clk4               : string  := "PORT_UNUSED";
            port_clk5               : string  := "PORT_UNUSED";
            port_clkena0            : string  := "PORT_UNUSED";
            port_clkena1            : string  := "PORT_UNUSED";
            port_clkena2            : string  := "PORT_UNUSED";
            port_clkena3            : string  := "PORT_UNUSED";
            port_clkena4            : string  := "PORT_UNUSED";
            port_clkena5            : string  := "PORT_UNUSED";
            self_reset_on_loss_lock : string  := "OFF";
            width_clock             : natural := 5
        );
        port (
            inclk : in  std_logic_vector(1 downto 0);
            clk   : out std_logic_vector(4 downto 0)
        );
    end component;
  component text_overlay
        port (
            checkX : in  unsigned(8 downto 0);
            checkY : in  unsigned(7 downto 0);
            isSet  : out std_logic
        );
    end component;
 
    component clk_div
        generic (
            div     : integer;
            bitSize : integer
        );
        port (
            clk_in  : in  std_logic;
            clk_out : out std_logic
        );
    end component;
 
    component ball
        generic (
            X      : integer;
            Y      : integer;
            VX     : integer;
            RADIUS : integer
        );
        port (
            checkX     : in  unsigned(8 downto 0);
            checkY     : in  unsigned(7 downto 0);
            isSet      : out std_logic;
            physicsClk : in  std_logic;
				reset      : in  std_logic
        );
    end component;
	 
	 component rectangle
     generic (
        X       : integer := 80;
        Y       : integer := 40;
        VX      : integer := 1;
        WIDTH_R   : integer := 64;
        HEIGHT_R  : integer := 32
    );
    port (
        checkX     : in  unsigned(8 downto 0);
        checkY     : in  unsigned(7 downto 0);
        isSet      : out std_logic;
        physicsClk : in  std_logic;
		  reset      : in std_logic
    );
    end component;	
	component pong 
    port (
        checkX     : in  unsigned(8 downto 0);
        checkY     : in  unsigned(7 downto 0);
        ball_isSet      : out std_logic;
        physicsClk : in  std_logic;
		  reset      : in std_logic;
		  user_input : in std_logic;
		  lp_isSet  : out std_logic;
		  rp_isSet : out std_logic
		  
		);
    end component;
	     
    component LCD_Controller
       generic (
       INPUT_CLK_MHZ : integer := 100
	    );
	
       port (
       clk : in std_logic;
		 reset : in std_logic;
       --Frame Buffer
       framebuffer_data : in std_logic_vector(15 downto 0);
       framebuffer_clk  : out std_logic;  
  
       --LCD Pins
       lcd_sdi : out std_logic;   --MOSI
       lcd_sdo : in  std_logic;   --MISO
       lcd_sck : out std_logic;
       lcd_cs  : out std_logic;
		 lcd_dc  : out std_logic;
       lcd_reset : out std_logic
       );
     end component;
	  
	  
end package;	  
