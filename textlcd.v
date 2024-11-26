module textlcd(
    input rst, clk,
    input [1:0] mode, // 모드 선택: WATCH/ALARM/STOPWATCH
    output lcd_e, lcd_rs, lcd_rw,
    output [7:0] lcd_data
);

reg [3:0] cnt;
wire [7:0] lcd_data_wire;

// lcd_control 인스턴스
lcd_control u_lcd_control (
    .mode(mode), 
    .cnt(cnt),
    .lcd_data(lcd_data_wire)
);

assign lcd_data = lcd_data_wire;

// LCD 제어 신호
assign lcd_e = clk; // LCD Enable 신호
assign lcd_rs = (cnt == 0) ? 1'b0 : 1'b1; // 첫 명령어는 명령 모드, 나머지는 데이터 모드
assign lcd_rw = 1'b0; // 항상 Write 모드

// 문자 출력 타이밍 관리
always @(posedge rst or posedge clk)
begin
    if (rst)
        cnt <= 4'd0;
    else if (cnt < 4'd11) // 최대 12문자 출력
        cnt <= cnt + 4'd1;
    else
        cnt <= 4'd0; // 반복
end

endmodule
