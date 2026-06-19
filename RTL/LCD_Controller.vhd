library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LCD_Controller is
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
  
end LCD_Controller;

architecture rtl of LCD_Controller is
signal spi_data : std_logic_vector(8 downto 0):=(others=>'0');
signal spi_idle : std_logic;

signal spidata_set_reg : std_logic:='0';  --Registered Guard Flag
signal spidata_set : std_logic:='0';   --Output to SPI Module

--framebuffer_nibble= 0-> Sending high byte, 1-> Sending low byte
signal framebuffer_nibble : std_logic:='0';

--Down Counter for interstate Delays
signal remainingDelayTicks : integer:=0;

--Signal to register LCD Reset
signal lcd_reset_reg : std_logic:='1';


--State Machine 
type mystate is (START, HOLD_RESET, WAIT_FOR_POWER_UP, SEND_INIT_SEQ, LOOP_ST);
signal state : mystate;


-- ILI9341 initialisation sequence.
constant INIT_SEQ_LEN : integer := 64;

type init_array_t is array(0 to INIT_SEQ_LEN-1)
    of std_logic_vector(8 downto 0);

constant INIT_SEQ : init_array_t := (

    0  => '0' & x"28",

    1  => '0' & x"CF",
    2  => '1' & x"00",
    3  => '1' & x"83",
    4  => '1' & x"30",

    5  => '0' & x"ED",
    6  => '1' & x"64",
    7  => '1' & x"03",
    8  => '1' & x"12",
    9  => '1' & x"81",

    10 => '0' & x"E8",
    11 => '1' & x"85",
    12 => '1' & x"01",
    13 => '1' & x"79",

    14 => '0' & x"CB",
    15 => '1' & x"39",
    16 => '1' & x"2C",
    17 => '1' & x"00",
    18 => '1' & x"34",
    19 => '1' & x"02",

    20 => '0' & x"F7",
    21 => '1' & x"20",

    22 => '0' & x"EA",
    23 => '1' & x"00",
    24 => '1' & x"00",

    25 => '0' & x"C0",
    26 => '1' & x"26",

    27 => '0' & x"C1",
    28 => '1' & x"11",

    29 => '0' & x"C5",
    30 => '1' & x"35",
    31 => '1' & x"3E",

    32 => '0' & x"C7",
    33 => '1' & x"BE",

    -- MADCTL: landscape (MV=1, MX=1, BGR=1)
    34 => '0' & x"36",
    35 => '1' & x"28",

    -- RGB565
    36 => '0' & x"3A",
    37 => '1' & x"55",

    38 => '0' & x"B1",
    39 => '1' & x"00",
    40 => '1' & x"1B",

    41 => '0' & x"26",
    42 => '1' & x"01",

    43 => '0' & x"51",
    44 => '1' & x"FF",

    45 => '0' & x"B7",
    46 => '1' & x"07",

    47 => '0' & x"B6",
    48 => '1' & x"0A",
    49 => '1' & x"82",
    50 => '1' & x"27",
    51 => '1' & x"00",

    -- Column address: 0 to 319
    52 => '0' & x"2A",
    53 => '1' & x"00",
    54 => '1' & x"00",
    55 => '1' & x"01",
    56 => '1' & x"3F",

    -- Row address: 0 to 239
    57 => '0' & x"2B",
    58 => '1' & x"00",
    59 => '1' & x"00",
    60 => '1' & x"00",
    61 => '1' & x"EF",

    62 => '0' & x"29",   -- Display ON
    63 => '0' & x"2C"    -- Memory write — pixel stream starts here
);
 
signal initSeqCounter : integer range 0 to INIT_SEQ_LEN := 0;

component SPI_Controller is
port (
      spiclk : in std_logic;
      data   : in std_logic_vector(8 downto 0);   --dc(8)  data (7 downto 0)
		data_avalible : in std_logic;  --Tells spi controller about avaliblity of data
		idle   : out std_logic;  -- 1 when ready to accept data  
	--SPI LCD Pins	
	  	sclk   : out std_logic;  --serial spi clock
		sdo    : out  std_logic; --MOSI
		dc     : out std_logic;  --Command=0 / Data=1
		cs     : out std_logic  --Chip Select
        );
end component;


begin
  lcd_reset<=lcd_reset_reg;
  spidata_set<=spidata_set_reg;

--framebuffer_clk<=0 -> lower byte is being sent
--framebuffer_clk<=1 -> higher byte is being sent  
  framebuffer_clk<=not framebuffer_nibble;
  
SPI_INST : SPI_Controller
        port map (
            spiClk        => clk,
            data          => spi_data,
            data_avalible => spidata_set,
            sclk          => lcd_sck,
            sdo           => lcd_sdi,
            dc            => lcd_dc,
            cs            => lcd_cs,
            idle          => spi_idle
        );
		  
		  
FSM : process(clk, reset)
begin

      if reset='1' then
		      state<=START;
			   state                <= START;
            lcd_reset_reg        <= '1';
            spidata_set_reg      <= '0';
            framebuffer_nibble   <= '0';
            remainingDelayTicks  <= 0;
            initSeqCounter       <= 0;
            spi_data             <= (others => '0');
      elsif rising_edge(clk) then
	      --Clear spi data set every cycle	
         spidata_set_reg<='0';
			
			--Count down any mandatory delay
			if remainingDelayTicks>0 then
			   remainingDelayTicks<=remainingDelayTicks-1;
			
		
	      --Advance FSM only when SPI is Idle and we didn't send data last cycle
		 	elsif spi_idle='1' and spidata_set_reg='0' then
			    case state is
					when START=>
					     lcd_reset_reg<='0';
						  remainingDelayTicks<=INPUT_CLK_MHZ * 10; --10 microsecond
						  state<=HOLD_RESET;
						  
					when HOLD_RESET=>
		              lcd_reset_reg<='1';
					     remainingDelayTicks<=INPUT_CLK_MHZ * 120000; --120 milliseconds	  
	      		     state<=WAIT_FOR_POWER_UP;
						  framebuffer_nibble<='0'; --Prime for framebuffer
						  
					when WAIT_FOR_POWER_UP=>
		              spi_data<='0' & x"11";
					     spidata_set_reg<='1';
					     remainingDelayTicks <= INPUT_CLK_MHZ * 5000;
                    state               <= SEND_INIT_SEQ;
                    framebuffer_nibble <= '1';
	  
               when SEND_INIT_SEQ=>
			           if initSeqCounter<INIT_SEQ_LEN then
						     spi_data<=INIT_SEQ(initSeqCounter);
							  spidata_set_reg<='1';
							  framebuffer_nibble<='1';
							  initSeqCounter<=initSeqCounter+1;
						  else
                       state               <= LOOP_ST;
                       remainingDelayTicks <= INPUT_CLK_MHZ * 10000;
							  framebuffer_nibble<='0';
                    end if;  
						 
					when LOOP_ST=>
			           if framebuffer_nibble='0' then
						     spi_data<='1' & framebuffer_data(15 downto 8);
						  else 
						     spi_data<='1' & framebuffer_data(7 downto 0);
						  end if;
						
				        spidata_set_reg<='1';
						  framebuffer_nibble<=not framebuffer_nibble;
						  state<=LOOP_ST;
						  
					when others=> null;
		         end case;
		    end if;
	end if;
end process;

end rtl;	
  


	 
	 
	 


  



















  
    
