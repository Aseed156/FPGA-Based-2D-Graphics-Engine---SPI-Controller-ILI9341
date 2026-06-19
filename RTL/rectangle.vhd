library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rectangle is
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
end entity;

architecture RTL of rectangle is

   --Boundary Conditions
   constant HALF_WIDTH : integer := WIDTH_R/2;
	constant HALF_HIGHT : integer := HEIGHT_R/2;
	
	constant MIN_X_C : integer:= HALF_WIDTH*64;
	constant MAX_X_C : integer:= (320- HALF_WIDTH)*64;
	
	constant MIN_Y_C : integer:= (33 + HALF_HIGHT)*64;
	constant MAX_Y_C : integer:= (240- HALF_HIGHT)*64;
	
	--Fixed Point Position
	signal x_sig : signed(15 downto 0) :=to_signed(X*64,16);
	signal y_sig : signed(15 downto 0) :=to_signed(Y*64,16);
	
	
	--Velocity
	signal vx_sig : signed(15 downto 0) :=to_signed(VX*16, 16);
	signal vy_sig : signed(15 downto 0) :=(others=>'0');
	
	
	 -- Rectangle edges
    
   signal leftEdge   : signed(15 downto 0);
   signal rightEdge  : signed(15 downto 0);
   signal topEdge    : signed(15 downto 0);
   signal bottomEdge : signed(15 downto 0);

   signal signedCheckX : signed(15 downto 0);
   signal signedCheckY : signed(15 downto 0);
	signal pixelX : signed(15 downto 0);
	signal pixelY : signed(15 downto 0);
	
begin	
	
--Physics Engine

physics_engine : process(physicsClk, reset)

variable newX : signed(15 downto 0);
variable newY : signed(15 downto 0);

begin
  if reset = '1' then
            x_sig  <= to_signed(X  * 64, 16);
            y_sig  <= to_signed(Y  * 64, 16);
            vx_sig <= to_signed(VX * 16, 16);
            vy_sig <= (others => '0');
  elsif rising_edge(physicsClk) then
     newX:=x_sig + vx_sig;
	  newY:=y_sig - vy_sig;
	 --Y Physics 
	  if newY< to_signed(MIN_Y_C,16) or newY > to_signed(MAX_Y_C,16) then
	     vy_sig<=-vy_sig-1;
	  else
		  y_sig<=newY;
        vy_sig<=vy_sig-1;
	  end if;
	  
	  --X Physics
	  if newX< to_signed(MIN_X_C,16) or newX > to_signed(MAX_X_C, 16) then
	     vx_sig<=-vx_sig;
	  else
        x_sig<=newX;
	  end if;
	  
	end if;
end process;



--Fixed Point -> Integer

pixelX<=shift_right(x_sig,6);
pixelY<=shift_right(y_sig,6);

-- Compute rectangle edges
    
leftEdge   <= pixelX - to_signed(HALF_WIDTH,16);
rightEdge  <= pixelX + to_signed(HALF_WIDTH,16);

topEdge    <= pixelY - to_signed(HALF_HIGHT,16);
bottomEdge <= pixelY + to_signed(HALF_HIGHT,16);
	
signedCheckX<=signed(resize(checkX,16));
signedCheckY<=signed(resize(checkY,16));

	  
--Rectangle Rasterization

 isSet <= '1' when
              (signedCheckX >= leftEdge) and
              (signedCheckX <= rightEdge) and
              (signedCheckY >= topEdge) and
              (signedCheckY <= bottomEdge)
              else '0';
end rtl;

