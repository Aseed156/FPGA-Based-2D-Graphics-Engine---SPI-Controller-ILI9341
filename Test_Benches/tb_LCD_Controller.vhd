library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_lcd_controller is
end tb_lcd_controller;

architecture sim of tb_lcd_controller is


    -- DUT signals
    signal clk              : std_logic := '0';
	 signal reset            : std_logic :='0';

    signal framebuffer_data : std_logic_vector(15 downto 0) := x"A55A";
    signal framebuffer_clk  : std_logic;

    signal lcd_sdi          : std_logic;
    signal lcd_sdo          : std_logic := '0';
    signal lcd_sck          : std_logic;
    signal lcd_cs           : std_logic;
    signal lcd_dc           : std_logic;
    signal lcd_reset        : std_logic;

    constant CLK_PERIOD : time := 10 ns; --100 MHz


    -- helper
    function slv_to_string(v : std_logic_vector) return string is
        variable s : string(1 to v'length);
        variable p : integer := 1;
    begin
        for i in v'reverse_range loop
            if v(i)='1' then
                s(p):='1';
            elsif v(i)='0' then
                s(p):='0';
            else
                s(p):='X';
            end if;
            p := p + 1;
        end loop;
        return s;
    end;

begin


    -- clock
    clk <= not clk after CLK_PERIOD/2;


    -- DUT
    DUT : entity work.LCD_Controller
    generic map(
        INPUT_CLK_MHZ => 100
    )
    port map(
        clk              => clk,
		  reset            =>reset,
        framebuffer_data => framebuffer_data,
        framebuffer_clk  => framebuffer_clk,
        lcd_sdi          => lcd_sdi,
        lcd_sdo          => lcd_sdo,
        lcd_sck          => lcd_sck,
        lcd_cs           => lcd_cs,
        lcd_dc           => lcd_dc,
        lcd_reset        => lcd_reset
    );



    -- Change framebuffer data every pixel request
    process(framebuffer_clk)
        variable pix : unsigned(15 downto 0) := x"1000";
    begin
        if rising_edge(framebuffer_clk) then
            pix := pix + 1;
            framebuffer_data <= std_logic_vector(pix);

            report "PIXEL ADVANCE -> new framebuffer_data = "
                   & integer'image(to_integer(pix));
        end if;
    end process;



    -- Check framebuffer clock spacing
    process
        variable rise_count : integer := 0;
        variable last_rise  : time := 0 ns;
    begin
        wait until rising_edge(framebuffer_clk);

        rise_count := rise_count + 1;

        report "framebuffer_clk rising #" &
               integer'image(rise_count) &
               " at " &
               time'image(now);

        if rise_count > 1 then
            report "delta since previous rise = " &
                   time'image(now-last_rise);
        end if;

        last_rise := now;
    end process;



    -- Monitor SPI activity
    process
        variable bit_count : integer := 0;
    begin
        wait until rising_edge(lcd_sck);

        if lcd_cs='0' then
            bit_count := bit_count + 1;

            report "SPI bit #" &
                   integer'image(bit_count) &
                   " dc=" & std_logic'image(lcd_dc) &
                   " mosi=" & std_logic'image(lcd_sdi);

            if bit_count = 8 then
                report "---- byte complete ----";
                bit_count := 0;
            end if;
        end if;
    end process;



    -- Detect suspicious framebuffer_clk toggles
    process
        variable toggle_count : integer := 0;
    begin
        wait on framebuffer_clk;

        toggle_count := toggle_count + 1;

        report "framebuffer_clk changed to "
               & std_logic'image(framebuffer_clk)
               & "  toggle="
               & integer'image(toggle_count);
    end process;


    -- run
    process
    variable rise_count : integer := 0;
    variable last_rise  : time := 0 ns;
    begin
    wait until rising_edge(framebuffer_clk);

    rise_count := rise_count + 1;

    report "framebuffer_clk rising #" &
           integer'image(rise_count) &
           " at " &
           time'image(now);

    if rise_count > 1 then
        report "delta since previous rise = " &
               time'image(now-last_rise);
    end if;

    last_rise := now;

    -- stop condition
    if rise_count = 20 then
        assert false
        report "TEST COMPLETE (20 pixels observed)"
        severity failure;
    end if;
end process;
end sim;
