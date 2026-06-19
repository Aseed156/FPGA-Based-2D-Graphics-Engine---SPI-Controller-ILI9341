library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity spi_controller is
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
end spi_controller;


architecture rtl of spi_controller is

--Counts the total bits being transfered  (MSB first)
signal counter : unsigned(2 downto 0) :=(others=>'0');	
	
signal internaldata : std_logic_vector(8 downto 0):= (others=>'0');
signal cs_reg : std_logic:='0';
signal idle_reg : std_logic:='1';
signal internal_sclk : std_logic:='1';


begin

--sclk is gated when idle
sclk<= internal_sclk and cs_reg;
  
--cs is active low on physical pins
cs<=not cs_reg;
idle<=idle_reg;
  
  
process(spiclk)
begin
    if rising_edge(spiclk) then
       if data_avalible='1' and idle_reg='1' then
	       internaldata<=data;
			 idle_reg<='0';
		 elsif idle_reg='0' then
          internal_sclk<= not internal_sclk;
	       
	       --Data is shifted on falling edge of sclk 
	       if internal_sclk='1' then
	          dc<=internaldata(8);
		       sdo<=internaldata(7- to_integer(counter)); --MSB first
		       cs_reg<='1';
				 
				 if counter=x"7" then
				    counter<=(others=>'0');
					 idle_reg<='1';
				 else
				    counter<=counter+1;
				 end if;
			 end if;
		 else
	      --Idle
	      internal_sclk<='1';
			if internal_sclk='1' then
	         cs_reg<='0';
			end if;	
	    end if;
	end if;
end process;

end rtl;
	
				     
		
        		
  






		 
