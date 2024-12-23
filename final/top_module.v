module top_module(
    input clk_1mhz,     // 보드에서 공급되는 1MHz 클록 (또는 PLL 등으로 1MHz 만들었다고 가정)
    input rst,          // Reset (active high)
    input mode,         // 모드 전환 버튼
    input start,        // 스톱워치 Start 버튼
    input dip_sw,       // watch 모드 스위치
    input dip_sw_timer, // timer 모드 스위치
    input [9:0] keypad, // 키패드
    output [7:0] seg_data,
    output [7:0] seg_com,
    output lcd_e,
    output lcd_rs,
    output lcd_rw,
    output [7:0] lcd_data,
    output [7:0] led,
    output piezo_out    // ★ 추가: 피에조 스피커 출력 (원하면)
);

    //------------------------------------
    // 1) 1MHz -> 1kHz 분주
    //------------------------------------
    wire clk_1khz;
    clock_divider_1k div_1k (
        .clk_in(clk_1mhz),
        .rst(rst),
        .clk_out(clk_1khz)
    );

    //------------------------------------
    // 2) 상태 전환 로직 (mode 버튼)
    //    - 시계(s0), 스톱워치(s1), 타이머(s2)
    //------------------------------------
    parameter s0 = 2'b00,
              s1 = 2'b01,
              s2 = 2'b10;

    reg [1:0] state_m;

    always @(posedge rst or posedge mode) begin
        if (rst) state_m <= s0;
        else begin
            case(state_m)
                s0: state_m <= s1;
                s1: state_m <= s2;
                s2: state_m <= s0;
                default: state_m <= s0;
            endcase
        end
    end

    //------------------------------------
    // 3) 각 모듈 인스턴스
    //------------------------------------
    // (A) Watch
    wire [7:0] watch_seg_data;
    wire [7:0] watch_seg_com;
    watch watch_inst (
        .clk(clk_1khz),      // ★ 1kHz 사용
        .rst(rst),
        .dip_sw(dip_sw),
        .keypad(keypad),
        .seg_data(watch_seg_data),
        .seg_com(watch_seg_com)
    );

    // (B) Stopwatch
    wire [7:0] stopwatch_seg_data;
    wire [7:0] stopwatch_seg_com;
    stopwatch stopwatch_inst (
        .clk(clk_1mhz),      // ★ 1MHz 직접 사용 (ms 정확도 위해)
        .rst(rst),
        .start(start),
        .seg_data(stopwatch_seg_data),
        .seg_com(stopwatch_seg_com)
    );

    // (C) Timer
    wire [7:0] timer_seg_data;
    wire [7:0] timer_seg_com;
    wire [7:0] timer_led;
    timer timer_inst (
        .clk(clk_1khz),      // ★ 1kHz 사용
        .rst(rst),
        .dip_sw_timer(dip_sw_timer),
        .keypad(keypad),
        .seg_data(timer_seg_data),
        .seg_com(timer_seg_com),
        .led(timer_led)      // 8비트 LED 신호
    );

    // (D) TextLCD
    wire [7:0] textlcd_data_w;
    wire textlcd_e_w, textlcd_rs_w, textlcd_rw_w;
    // msg_sel 결정
    reg [1:0] msg_sel_reg;
    always @(*) begin
        case(state_m)
            s0: msg_sel_reg = 2'b00;
            s1: msg_sel_reg = 2'b01;
            s2: msg_sel_reg = 2'b10;
            default: msg_sel_reg = 2'b00;
        endcase
    end

    textlcd textlcd_inst (
        .rst(rst),
        .clk(clk_1khz),          // ★ 1kHz를 넣고, 내부에서 100Hz 분주
        .msg_sel(msg_sel_reg),
        .lcd_e(textlcd_e_w),
        .lcd_rs(textlcd_rs_w),
        .lcd_rw(textlcd_rw_w),
        .lcd_data(textlcd_data_w)
    );

    // LCD 외부 포트 연결
    assign lcd_e    = textlcd_e_w;
    assign lcd_rs   = textlcd_rs_w;
    assign lcd_rw   = textlcd_rw_w;
    assign lcd_data = textlcd_data_w;

    //------------------------------------
    // 4) 상태별 FND 표시 선택
    //------------------------------------
    reg [7:0] seg_data_reg;
    reg [7:0] seg_com_reg;
    assign seg_data = seg_data_reg;
    assign seg_com  = seg_com_reg;

    always @(posedge clk_1mhz or posedge rst) begin
        if (rst) begin
            seg_data_reg <= 8'h00;
            seg_com_reg  <= 8'hFF;
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
                    seg_data_reg <= 8'h00;
                    seg_com_reg  <= 8'hFF;
                end
            endcase
        end
    end

    //------------------------------------
    // 5) LED 연결 (timer의 led 출력 사용)
    //------------------------------------
    assign led = timer_led; // 타이머 모듈이 00:00:00 되면 led 깜빡

    //------------------------------------
    // 6) Piezo (멜로디) (옵션)
    //------------------------------------
    // timer_done 시점에 도레미파솔라시도 등 멜로디를 내고 싶다면,
    // 아래와 같은 모듈을 추가:
    wire timer_done; // timer에서 "00:00:00" 도달 신호를 wire로 뽑아오고 싶다면
    // => timer.v를 조금 수정해서 'timer_done'을 포트로 꺼낼 수 있음.
    // 여기선 가상의 예시
    wire melody_en = timer_done; // timer_done이 1이면 멜로디 스타트

    piezo_melody melody_inst (
        .clk(clk_1mhz),     // 1MHz
        .rst(rst),
        .start_melody(melody_en),
        .piezo_out(piezo_out)
    );

endmodule
