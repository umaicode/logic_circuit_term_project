module textlcd(
    input rst, clk,
    output lcd_e, lcd_rs, lcd_rw,
    output reg [7:0] lcd_data
);

    wire clk_100hz;

    clock_divider clk_div (
        .clk_in(clk),
        .rst(rst),
        .clk_out(clk_100hz)
    );

    reg [2:0] state;
    parameter delay = 3'b000, function_set = 3'b001, entry_mode = 3'b010,
              disp_onoff = 3'b011, line1 = 3'b100, line2 = 3'b101,
              delay_t = 3'b110, clear_disp = 3'b111;

    assign lcd_e = clk_100hz;

    always @(posedge clk_100hz or posedge rst) begin
        if (rst) state <= delay;
        else begin
            case (state)
                delay: if (cnt == 70) state <= function_set;
                function_set: if (cnt == 30) state <= disp_onoff;
                disp_onoff: if (cnt == 30) state <= entry_mode;
                entry_mode: if (cnt == 30) state <= line1;
                line1: if (cnt == 20) state <= line2;
                line2: if (cnt == 20) state <= delay_t;
                delay_t: if (cnt == 400) state <= clear_disp;
                clear_disp: if (cnt == 200) state <= line1;
            endcase
        end
    end

always @(posedge rst or posedge clk_100hz)
begin
    if(rst)
        begin
            lcd_rs = 1'b1;
            lcd_rw = 1'b1;
            lcd_data = 8'b00000000;
        end
    else
        begin
            case (state)
                function_set :
                    begin
                        lcd_rs = 1'b0;
                        lcd_rw = 1'b0;
                        lcd_data = 8'b00111100;
                    end
                disp_onoff :
                    begin
                        lcd_rs = 1'b0;
                        lcd_rw = 1'b0;
                        lcd_data = 8'b00001100;
                    end
                entry_mode :
                    begin
                        lcd_rs = 1'b0;
                        lcd_rw = 1'b0;
                        lcd_data = 8'b00000110;
                    end
                line1 :
                    begin
                        lcd_rw = 1'b0;

                        case (cnt)
                            0 : 
                                begin
                                    lcd_rs = 1'b0;
                                    lcd_data = 8'b10000000;
                                end
                            1 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b00100000;
                                end
                            2 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01001000; // H
                                end
                            3 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01100101; // E
                                end
                            4 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01101100; // L
                                end
                            5 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01101100; // L
                                end
                            6 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01101111; // O
                                end
                            7 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01110111; // W;
                                end
                            default :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b00100000;
                                end
                        endcase
                    end
                line2 :
                    begin
                        lcd_rw = 1'b0;

                        case (cnt)
                            0 :
                                begin
                                    lcd_rs = 1'b0;
                                    lcd_data = 8'b11000000;
                                end
                            9 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01010111; // W
                                end
                            10 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01101111; // O
                                end
                            11 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01110010; // R
                                end
                            12 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01101100; // L
                                end
                            13 :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b01100100; // D
                                end
                            default :
                                begin
                                    lcd_rs = 1'b1;
                                    lcd_data = 8'b00100000;
                                end
                        endcase
                    end
                delay_t :
                    begin
                        lcd_rs = 1'b0;
                        lcd_rw = 1'b0;
                        lcd_data = 8'b00000010;
                    end
                clear_disp :
                    begin
                        lcd_rs = 1'b0;
                        lcd_rw = 1'b0;
                        lcd_data = 8'b00000001;
                    end
                default :
                    begin
                        lcd_rs = 1'b1;
                        lcd_rw = 1'b1;
                        lcd_data = 8'b00000000;
                    end
            endcase
        end
end

endmodule