module state_app(
    input rst,               // 리셋 (active high)
    input clk,               // 1kHz 입력 클록
    input mode,              // 상태 전환 (버튼)
    input start,             // 스톱워치 시작(버튼)
    input dip_sw,            // 시계 모드용 DIP
    input dip_sw_timer,      // 타이머 모드용 DIP
    input [9:0] keypad,      // 키패드
    output [7:0] seg_data,   // FND 데이터
    output [7:0] seg_com,    // FND 자리 선택
    output lcd_e,            // LCD Enable
    output lcd_rs,           // LCD Register Select
    output lcd_rw,           // LCD R/W
    output [7:0] lcd_data,   // LCD 데이터
    output [7:0] led         // ★ LED 8비트 (여기서 [0] 사용)
);

    //----------------------------------------
    // (1) 내부 reg, wire 선언
    //----------------------------------------
    reg [7:0] seg_data_reg;
    reg [7:0] seg_com_reg;

    assign seg_data = seg_data_reg;
    assign seg_com  = seg_com_reg;

    // 여기서 led는 wire 타입 (출력 포트)
    // 내부에선 timer_led라는 wire를 받아서 연결
    wire [7:0] timer_led;

    //----------------------------------------
    // (2) 상태 정의 및 전환
    //----------------------------------------
    parameter s0 = 2'b00, // 시계
              s1 = 2'b01, // 스톱워치
              s2 = 2'b10; // 타이머

    reg [1:0] state_m;

    always @(posedge rst or posedge mode) begin
        if (rst) begin
            state_m <= s0;
        end else begin
            case (state_m)
                s0: state_m <= s1;  
                s1: state_m <= s2;
                s2: state_m <= s0;
                default: state_m <= s0;
            endcase
        end
    end

    //----------------------------------------
    // (3) 시계/스톱워치/타이머 모듈 인스턴스
    //----------------------------------------
    // (A) 시계
    wire [7:0] watch_seg_data;
    wire [7:0] watch_seg_com;
    watch watch_inst (
        .clk(clk),
        .rst(rst),
        .keypad(keypad),
        .dip_sw(dip_sw),
        .seg_data(watch_seg_data),
        .seg_com(watch_seg_com)
    );

    // (B) 스톱워치
    wire [7:0] stopwatch_seg_data;
    wire [7:0] stopwatch_seg_com;
    stopwatch stopwatch_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .seg_data(stopwatch_seg_data),
        .seg_com(stopwatch_seg_com)
    );

    // (C) 타이머
    //     => led 신호를 추가로 받아옴
    wire [7:0] timer_seg_data;
    wire [7:0] timer_seg_com;
    timer timer_inst (
        .clk(clk),
        .rst(rst),
        .dip_sw_timer(dip_sw_timer),
        .keypad(keypad),
        .seg_data(timer_seg_data),
        .seg_com(timer_seg_com),
        .led(timer_led)       // ★ 추가된 LED 출력
    );

    //----------------------------------------
    // (4) 상태에 따른 FND 표시 선택
    //----------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_data_reg <= 8'b0000_0000;
            seg_com_reg  <= 8'b1111_1111;
        end else begin
            case (state_m)
                s0: begin
                    seg_data_reg <= watch_seg_data;
                    seg_com_reg  <= watch_seg_com;
                end
                s1: begin
                    seg_data_reg <= stopwatch_seg_data;
                    seg_com_reg  <= stopwatch_seg_com;
                end
                s2: begin
                    seg_data_reg <= timer_seg_data;
                    seg_com_reg  <= timer_seg_com;
                end
                default: begin
                    seg_data_reg <= 8'b0000_0000;
                    seg_com_reg  <= 8'b1111_1111;
                end
            endcase
        end
    end

    //----------------------------------------
    // (5) LCD (textlcd) 연결
    //----------------------------------------
    wire textlcd_e, textlcd_rs, textlcd_rw;
    wire [7:0] textlcd_data_w;

    // 상태 -> msg_sel 변환
    reg [1:0] msg_sel_reg;
    always @(*) begin
        case (state_m)
            s0: msg_sel_reg = 2'b00;
            s1: msg_sel_reg = 2'b01;
            s2: msg_sel_reg = 2'b10;
            default: msg_sel_reg = 2'b00;
        endcase
    end

    textlcd textlcd_inst (
        .rst(rst),
        .clk(clk),
        .msg_sel(msg_sel_reg),
        .lcd_e(textlcd_e),
        .lcd_rs(textlcd_rs),
        .lcd_rw(textlcd_rw),
        .lcd_data(textlcd_data_w)
    );

    // LCD 출력 배선
    assign lcd_e    = textlcd_e;
    assign lcd_rs   = textlcd_rs;
    assign lcd_rw   = textlcd_rw;
    assign lcd_data = textlcd_data_w;

    //----------------------------------------
    // (6) LED 출력
    //----------------------------------------
    // 여기서는 led[0]에 타이머 LED 연결, 나머지는 0으로 둠
    assign led = timer_led;

endmodule