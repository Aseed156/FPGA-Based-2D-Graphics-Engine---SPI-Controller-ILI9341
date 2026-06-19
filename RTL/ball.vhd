library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity ball is
    generic (
        X      : integer := 30;
        Y      : integer := 30;
        VX     : integer := 1;
        RADIUS : integer := 32
    );
    port (
        checkX     : in  unsigned(8 downto 0);
        checkY     : in  unsigned(7 downto 0);
        isSet      : out std_logic;
        physicsClk : in  std_logic;
		  reset      : in std_logic
    );
end entity;
 
architecture RTL of ball is
 
    -- Boundary constants including the RADIUS/6 margin (integer division)
   
    constant MIN_Y_C : integer := (31  + RADIUS / 6) * 64;
    constant MAX_Y_C : integer := (240 - RADIUS / 6) * 64;
    constant MIN_X_C : integer := (0   + RADIUS / 6) * 64;
    constant MAX_X_C : integer := (320 - RADIUS / 6) * 64;
 
    -- Fixed-point position (Q10.6, stored *64 so pixel = value >> 6).
    -- Velocity stored *16 for sub-pixel precision.
    signal x_sig  : signed(15 downto 0) := to_signed(X * 64,  16);
    signal y_sig  : signed(15 downto 0) := to_signed(Y * 64,  16);
    signal vx_sig : signed(15 downto 0) := to_signed(VX * 16, 16);
    signal vy_sig : signed(15 downto 0) := (others => '0');
 
    -- Rendering intermediates (combinational).
    signal pixelX       : signed(15 downto 0);
    signal pixelY       : signed(15 downto 0);
    signal signedCheckX : signed(15 downto 0);
    signal signedCheckY : signed(15 downto 0);
    signal dx           : signed(15 downto 0);
    signal dy           : signed(15 downto 0);
 
    -- dx and dy are 16-bit, so each product is 32-bit, and the sum is 33-bit
    -- (one guard bit for the addition carry).  Use 64-bit to hold both
    -- products and their sum without truncation or manual resizing.
    signal squaredDist  : signed(63 downto 0);
 
begin
 

    -- Physics process
    process(physicsClk, reset)
        variable newX : signed(15 downto 0);
        variable newY : signed(15 downto 0);
    begin
	 
	   if reset='1' then
		      x_sig  <= to_signed(X * 64,  16);
            y_sig  <= to_signed(Y * 64,  16);
            vx_sig <= to_signed(VX * 16, 16);
            vy_sig <= (others => '0');
        elsif rising_edge(physicsClk) then
 
            -- Compute proposed next positions combinationally within the process.
            newX := x_sig + vx_sig;
            newY := y_sig - vy_sig;   
 
            -- Y-axis: bounce off top/bottom walls; apply gravity every tick.
            if newY < MIN_Y_C or newY > MAX_Y_C then
                vy_sig <= -vy_sig - 1;          -- reverse velocity and apply gravity
            else
                y_sig  <= newY;
                vy_sig <= vy_sig - 1;           -- gravity accumulates downward
            end if;
 
            -- X-axis: bounce off side walls.
            if newX < MIN_X_C or newX > MAX_X_C then
                vx_sig <= -vx_sig;
            else
                x_sig <= newX;
            end if;
 
        end if;
    end process;
 
  
    pixelX <= shift_right(x_sig, 6);
    pixelY <= shift_right(y_sig, 6);
 
    -- Zero-extend unsigned port inputs to signed 16-bit for subtraction.
    signedCheckX <= signed(resize(checkX, 16));
    signedCheckY <= signed(resize(checkY, 16));
 
    dx <= pixelX - signedCheckX;
    dy <= pixelY - signedCheckY;
 
    -- dx * dx produces signed(31 downto 0) naturally (16*16=32 bits).
    squaredDist <= resize(dx * dx, 64) + resize(dy * dy, 64);
 
   
    isSet <= '1' when squaredDist <= to_signed(RADIUS * RADIUS, 64) else '0';
 
end architecture;
