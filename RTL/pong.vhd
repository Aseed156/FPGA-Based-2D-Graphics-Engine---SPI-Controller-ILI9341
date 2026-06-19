library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pong is
    port (
        checkX     : in  unsigned(8 downto 0);
        checkY     : in  unsigned(7 downto 0);
        ball_isSet : out std_logic;
        physicsClk : in  std_logic;
        reset      : in  std_logic;
        user_input : in  std_logic;   -- '1' = move right paddle up, '0' = down
        lp_isSet   : out std_logic;
        rp_isSet   : out std_logic
    );
end pong;

architecture rtl of pong is

    -- Game constants
    constant BALL_R    : integer := 6;
    constant PADDLE_W  : integer := 12;
    constant PADDLE_H  : integer := 60;    
    constant LEFT_X    : integer := 10;    
    constant RIGHT_X   : integer := 298;  
                                          


    constant WALL_TOP    : integer := BALL_R;           -- 6
    constant WALL_BOTTOM : integer := 239 - BALL_R;     -- 233

 
    constant PADDLE_MIN_Y : integer := 0;
    constant PADDLE_MAX_Y : integer := 239 - PADDLE_H;  

    -- AI speed
    constant AI_SPEED  : integer := 2;
    constant PAD_SPEED : integer := 3;

    constant VX_INIT   : integer := 2;
    constant VY_INIT   : integer := 1;
    constant VY_MAX    : integer := 5;    


    -- Game state signals  (integer pixel coordinates, no fixed-point)
    signal ballX  : integer range -20 to 340 := 160;
    signal ballY  : integer range -20 to 260 := 120;
    signal ballVX : integer range -8  to 8   := VX_INIT;
    signal ballVY : integer range -8  to 8   := VY_INIT;
    signal leftY  : integer range 0   to 240 := 80;
    signal rightY : integer range 0   to 240 := 80;

begin

    -- ---------------------------------------------------------------
    -- Physics process
    process(physicsClk, reset)
        variable nx      : integer range -20 to 340;
        variable ny      : integer range -20 to 260;
        variable offset  : integer;
        variable vy_new  : integer;
        variable new_lY  : integer;
        variable new_rY  : integer;
    begin
        if reset = '1' then
            ballX  <= 160;
            ballY  <= 120;
            ballVX <= VX_INIT;
            ballVY <= VY_INIT;   
            leftY  <= 80;
            rightY <= 80;

        elsif rising_edge(physicsClk) then

            nx := ballX + ballVX;
            ny := ballY + ballVY;

            if ny < WALL_TOP then
                ny     := WALL_TOP;      
                ballVY <= -ballVY;
            elsif ny > WALL_BOTTOM then
                ny     := WALL_BOTTOM;
                ballVY <= -ballVY;
            end if;

            if nx - BALL_R <= LEFT_X + PADDLE_W and
               nx + BALL_R >= LEFT_X            and
               ny >= leftY                      and
               ny <= leftY + PADDLE_H           then

                nx     := LEFT_X + PADDLE_W + BALL_R + 1;
                offset := ny - (leftY + PADDLE_H / 2);
                vy_new := offset / 5;   -- scale: centre=0, edge=+-6

                if vy_new = 0 then
                    vy_new := 1;
                end if;

                if vy_new > VY_MAX then
                    vy_new := VY_MAX;
                elsif vy_new < -VY_MAX then
                    vy_new := -VY_MAX;
                end if;
                if ballVX < 0 then
                    ballVX <= -ballVX;
                end if;
                ballVY <= vy_new;
            end if;


            if nx + BALL_R >= RIGHT_X              and
               nx - BALL_R <= RIGHT_X + PADDLE_W  and
               ny >= rightY                        and
               ny <= rightY + PADDLE_H             then


                nx := RIGHT_X - BALL_R - 1;

                offset := ny - (rightY + PADDLE_H / 2);
                vy_new := offset / 5;

                if vy_new = 0 then
                    vy_new := 1;
                end if;
                if vy_new > VY_MAX then
                    vy_new := VY_MAX;
                elsif vy_new < -VY_MAX then
                    vy_new := -VY_MAX;
                end if;

                -- Ball must go LEFT after right paddle hit
                if ballVX > 0 then
                    ballVX <= -ballVX;
                end if;
                ballVY <= vy_new;
            end if;


            if nx < 0 or nx > 319 then
                nx     := 160;
                ny     := 120;
                ballVX <= -ballVX;   -- serve toward the side that scored
                ballVY <= VY_INIT;   -- FIX 8: clean vertical speed on reset
            end if;

            -- Commit variables to signals
            ballX <= nx;
            ballY <= ny;


            new_rY := rightY;
            if user_input = '1' then
                new_rY := rightY - PAD_SPEED;
            else
                new_rY := rightY + PAD_SPEED;
            end if;

            if new_rY < PADDLE_MIN_Y then
                new_rY := PADDLE_MIN_Y;
            elsif new_rY > PADDLE_MAX_Y then
                new_rY := PADDLE_MAX_Y;
            end if;
            rightY <= new_rY;

            new_lY := leftY;
            if ballY > leftY + PADDLE_H / 2 then
                new_lY := leftY + AI_SPEED;
            elsif ballY < leftY + PADDLE_H / 2 then
                new_lY := leftY - AI_SPEED;
            end if;

            if new_lY < PADDLE_MIN_Y then
                new_lY := PADDLE_MIN_Y;
            elsif new_lY > PADDLE_MAX_Y then
                new_lY := PADDLE_MAX_Y;
            end if;
            leftY <= new_lY;

        end if;
    end process;


    ball_isSet <= '1' when
        (to_integer(checkX) - ballX) * (to_integer(checkX) - ballX) +
        (to_integer(checkY) - ballY) * (to_integer(checkY) - ballY)
        <= BALL_R * BALL_R
        else '0';

    -- Left paddle (AI)
    lp_isSet <= '1' when
        to_integer(checkX) >= LEFT_X              and
        to_integer(checkX) <  LEFT_X + PADDLE_W  and
        to_integer(checkY) >= leftY               and
        to_integer(checkY) <  leftY + PADDLE_H
        else '0';

    -- Right paddle (player)
    rp_isSet <= '1' when
        to_integer(checkX) >= RIGHT_X             and
        to_integer(checkX) <  RIGHT_X + PADDLE_W and
        to_integer(checkY) >= rightY              and
        to_integer(checkY) <  rightY + PADDLE_H
        else '0';

end rtl;
