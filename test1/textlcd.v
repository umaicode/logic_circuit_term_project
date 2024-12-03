module textlcd(
    input rst,
    input clk,
    input [7:0] line1_data,  // Line 1의 동적 데이터
    input [7:0] line2_data,  // Line 2의 동적 데이터
    input enable,            // LCD 활성화 신호
    output lcd_e, lcd_rs, lcd_rw,
    output reg [7:0] lcd_data
);

reg [2:0] state;
parameter delay = 3'b000,
        function_set = 3'b001,
        entry_mode = 3'b010,
        disp_onoff = 3'b011,
        line1 = 3'b100,
        line2 = 3'b101,
        delay_t = 3'b110,
        clear_disp = 3'b111;

integer cnt;
integer cnt_100hz;
reg clk_100hz;

always @(posedge rst or posedge clk)
begin
    if (rst) begin
        cnt_100hz = 0;
        clk_100hz = 1'b0;
    end else if (cnt_100hz >= 4) begin
        cnt_100hz = 0;
        clk_100hz = ~clk_100hz;
    end else begin
        cnt_100hz = cnt_100hz + 1;
    end
end

always @(posedge rst or posedge clk_100hz)
begin
    if (rst) begin
        state = delay;
    end else if (enable) begin // enable 신호에 따라 활성화
        case (state)
            delay :
                if (cnt == 70) state = function_set;
            function_set:
                if (cnt == 30) state = disp_onoff;
            disp_onoff :
                if (cnt == 30) state = entry_mode;
            entry_mode :
                if (cnt == 30) state = line1;
            line1 :
                if (cnt == 20) state = line2;
            line2 :
                if (cnt == 20) state = delay_t;
            delay_t :
                if (cnt == 400) state = clear_disp;
            clear_disp :
                if (cnt == 200) state = line1;
            default :
                state = delay;
        endcase
    end
end

always @(posedge rst or posedge clk_100hz)
begin
    if (rst) begin
        lcd_rs = 1'b1;
        lcd_rw = 1'b1;
        lcd_data = 8'b00000000;
    end else if (enable) begin // enable 신호에 따라 동작
        case (state)
            line1 :
                begin
                    lcd_rw = 1'b0;
                    case (cnt)
                        0 : begin
                            lcd_rs = 1'b0;
                            lcd_data = 8'b10000000; // Line 1 커서
                        end
                        1 : begin
                            lcd_rs = 1'b1;
                            lcd_data = line1_data; // Line 1 데이터
                        end
                        default: lcd_data = 8'b00000000;
                    endcase
                end
            line2 :
                begin
                    lcd_rw = 1'b0;
                    case (cnt)
                        0 : begin
                            lcd_rs = 1'b0;
                            lcd_data = 8'b11000000; // Line 2 커서
                        end
                        1 : begin
                            lcd_rs = 1'b1;
                            lcd_data = line2_data; // Line 2 데이터
                        end
                        default: lcd_data = 8'b00000000;
                    endcase
                end
            default: lcd_data = 8'b00000000;
        endcase
    end
end

assign lcd_e = clk_100hz;

endmodule
