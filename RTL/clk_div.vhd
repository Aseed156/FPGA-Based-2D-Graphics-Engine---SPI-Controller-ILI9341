library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity clk_div is

generic(
     div : integer:=4;
	  bitsize : integer:=16
	 ); 
port (
     clk_in : in std_logic;     --Clock input from PLL
	  clk_out : out std_logic    --Clock output to Game
	  );
end clk_div;


architecture rtl of clk_div is

signal counter : unsigned(bitsize-1 downto 0) :=(others=>'0');
signal clk_out_sig : std_logic:='0';

begin
   clk_out<=clk_out_sig;
   process(clk_in) 
   begin
       if rising_edge(clk_in) then
	       if counter >= to_unsigned(div/2 -1 , bitsize) then
		       counter<=(others=>'0');
			    clk_out_sig<=not clk_out_sig;
			 else
		       counter<=counter+1;
			 end if;
		 end if;
	end process;
end rtl;	
		 
		 
