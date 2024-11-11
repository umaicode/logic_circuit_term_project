    signal hour_buf0, hour_buf1 : integer := 0;
    signal min_buf0, min_buf1 : integer := 0;
    signal sec_buf0, sec_buf1 : integer := 0;

-- process for converting to integer type
    process(hour, min, sec)
    begin
        hour_buf0 <= conv_integer(hour) / 10;
        hour_buf1 <= conv_integer(hour) mod 10;
        min_buf0 <= conv_integer(min) / 10;
        min_buf1 <= conv_integer(min) mod 10;
        sec_buf0 <= conv_integer(sec) / 10;
        sec_buf1 <= conv_integer(sec) mod 10;
    end process;