module textlcd(
    input rst, clk,
    input [1:0] mode, // 모드 선택: WATCH/ALARM/STOPWATCH
    output lcd_e, lcd_rs, lcd_rw,
    output [7:0] lcd_data
);

reg [3:0] cnt;
wire [7:0] lcd_data_wire;
reg[3:0] state;
parameter DELAY = 3'b000, FUNCTION_SET = 3'b001, DISPLAY_ON = 3'b010, CLEAR_DISPLAY = 3'b011, ENTRY_MODE = 3'b100, READY = 3'b101;

integer timing_cnt;


// LCD 제어 신호
assign lcd_e = clk; // LCD Enable 신호
assign lcd_rw = 1'b0; // 항상 Write 모드

// lcd_control 인스턴스
lcd_control u_lcd_control (
    .mode(mode), 
    .cnt(cnt),
    .lcd_data(lcd_data_wire)
);

assign lcd_data = lcd_data_wire;

// 초기화 상태 머신
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= DELAY;
        timing_cnt <= 0;
        cnt <= 0;
    end else begin
        case (state)
            DELAY: begin
                if (timing_cnt < 70) timing_cnt <= timing_cnt + 1; // 초기 딜레이
                else begin
                    timing_cnt <= 0;
                    state <= FUNCTION_SET;
                end
            end
            FUNCTION_SET: begin
                if (timing_cnt == 30) begin
                    lcd_rs <= 1'b0;
                    lcd_data <= 8'b00111100; // Function Set
                    timing_cnt <= 0;
                    state <= DISPLAY_ON;
                end else timing_cnt <= timing_cnt + 1;
            end
            DISPLAY_ON: begin
                if (timing_cnt == 30) begin
                    lcd_rs <= 1'b0;
                    lcd_data <= 8'b00001100; // Display ON
                    timing_cnt <= 0;
                    state <= CLEAR_DISPLAY;
                end else timing_cnt <= timing_cnt + 1;
            end
            CLEAR_DISPLAY: begin
                if (timing_cnt == 100) begin
                    lcd_rs <= 1'b0;
                    lcd_data <= 8'b00000001; // Clear Display
                    timing_cnt <= 0;
                    state <= ENTRY_MODE;
                end else timing_cnt <= timing_cnt + 1;
            end
            ENTRY_MODE: begin
                if (timing_cnt == 30) begin
                    lcd_rs <= 1'b0;
                    lcd_data <= 8'b00000110; // Entry Mode
                    timing_cnt <= 0;
                    state <= READY;
                end else timing_cnt <= timing_cnt + 1;
            end
            READY: begin
                lcd_rs <= (cnt == 0) ? 1'b0 : 1'b1; // 첫 명령어는 명령 모드
                if (cnt < 4'd11) cnt <= cnt + 1;
                else cnt <= 0; // 반복
            end
        endcase
    end
end

endmodule