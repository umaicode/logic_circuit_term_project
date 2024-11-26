module lcd_control(
    input [1:0] mode,       // 모드 선택: 2'b00 -> WATCH, 2'b01 -> ALARM, 2'b10 -> STOPWATCH
    input [3:0] cnt,        // 현재 출력할 문자 위치
    output reg [7:0] lcd_data // LCD에 출력할 데이터
);

// 모드 정의
parameter WATCH = 2'b00;
parameter ALARM = 2'b01;
parameter STOPWATCH = 2'b10;
parameter SETTING = 2'b11;

always @(*) begin
    case (mode)
        WATCH: begin
            // WATCH 모드: "MODE1 : WATCH"
            case (cnt)
                4'd0 : lcd_data = 8'b01001101; // 'M'
                4'd1 : lcd_data = 8'b01001111; // 'O'
                4'd2 : lcd_data = 8'b01000100; // 'D'
                4'd3 : lcd_data = 8'b01000101; // 'E'
                4'd4 : lcd_data = 8'b00110001; // '1'
                4'd5 : lcd_data = 8'b00111010; // ':'
                4'd6 : lcd_data = 8'b00100000; // ' '
                4'd7 : lcd_data = 8'b01010111; // 'W'
                4'd8 : lcd_data = 8'b01000001; // 'A'
                4'd9 : lcd_data = 8'b01010100; // 'T'
                4'd10: lcd_data = 8'b01000011; // 'C'
                4'd11: lcd_data = 8'b01001000; // 'H'
                default: lcd_data = 8'b00100000; // 공백
            endcase
        end
        ALARM: begin
            // ALARM 모드: "MODE2 : ALARM"
            case (cnt)
                4'd0 : lcd_data = 8'b01001101; // 'M'
                4'd1 : lcd_data = 8'b01001111; // 'O'
                4'd2 : lcd_data = 8'b01000100; // 'D'
                4'd3 : lcd_data = 8'b01000101; // 'E'
                4'd4 : lcd_data = 8'b00110010; // '2'
                4'd5 : lcd_data = 8'b00111010; // ':'
                4'd6 : lcd_data = 8'b00100000; // ' '
                4'd7 : lcd_data = 8'b01000001; // 'A'
                4'd8 : lcd_data = 8'b01001100; // 'L'
                4'd9 : lcd_data = 8'b01000001; // 'A'
                4'd10: lcd_data = 8'b01010010; // 'R'
                4'd11: lcd_data = 8'b01001101; // 'M'
                default: lcd_data = 8'b00100000; // 공백
            endcase
        end
        STOPWATCH: begin
            // STOPWATCH 모드: "MODE3 : STOP"
            case (cnt)
                4'd0 : lcd_data = 8'b01001101; // 'M'
                4'd1 : lcd_data = 8'b01001111; // 'O'
                4'd2 : lcd_data = 8'b01000100; // 'D'
                4'd3 : lcd_data = 8'b01000101; // 'E'
                4'd4 : lcd_data = 8'b00110011; // '3'
                4'd5 : lcd_data = 8'b00111010; // ':'
                4'd6 : lcd_data = 8'b00100000; // ' '
                4'd7 : lcd_data = 8'b01010011; // 'S'
                4'd8 : lcd_data = 8'b01010100; // 'T'
                4'd9 : lcd_data = 8'b01001111; // 'O'
                4'd10: lcd_data = 8'b01010000; // 'P'
                default: lcd_data = 8'b00100000; // 공백
            endcase
        end
        SETTING: begin
            // SETTING 모드: "MODE4 : SET"
            case (cnt)
                4'd0 : lcd_data = 8'b01001101; // 'M'
                4'd1 : lcd_data = 8'b01001111; // 'O'
                4'd2 : lcd_data = 8'b01000100; // 'D'
                4'd3 : lcd_data = 8'b01000101; // 'E'
                4'd4 : lcd_data = 8'b00110100; // '4'
                4'd5 : lcd_data = 8'b00111010; // ':'
                4'd6 : lcd_data = 8'b00100000; // ' '
                4'd7 : lcd_data = 8'b01010011; // 'S'
                4'd8 : lcd_data = 8'b01000101; // 'E'
                4'd9 : lcd_data = 8'b01010100; // 'T'
                default: lcd_data = 8'b00100000; // 공백
            endcase
        end
    endcase
end

endmodule
