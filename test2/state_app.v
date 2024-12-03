module state_app(
    input rst,         // 리셋 신호 (active high)
    input clk,         // 1kHz 입력 클럭
    input mode,        // 상태 전환 신호
    input start,       // 스톱워치 시작 신호
    output [7:0] seg_data, seg_com,       // 7-세그먼트 디스플레이 데이터 및 공통 신호
    output lcd_e, lcd_rs, lcd_rw,        // LCD 제어 신호
    output [7:0] lcd_data                // LCD 데이터
);

    // 내부 신호 선언
    wire clk_100hz; // 100Hz 클럭 신호

    // 클럭 분주기 인스턴스화
    clock_divider clk_div (
        .clk_in(clk),    // 1kHz 입력 클럭
        .rst(rst),       // 리셋 신호
        .clk_out(clk_100hz) // 100Hz 출력 클럭
    );

    // 상태 머신 상태 값 정의
    parameter s0 = 2'b00, s1 = 2'b01, s2 = 2'b10;
    reg [1:0] state_m; // 현재 상태를 저장하는 레지스터

    // 상태 머신
    always @(posedge rst or posedge mode) begin
        if (rst) begin
            state_m <= s0; // 리셋 시 초기 상태로 설정
        end else begin
            case (state_m)
                s0: state_m <= s1; // s0 -> s1
                s1: state_m <= s2; // s1 -> s2
                s2: state_m <= s0; // s2 -> s0
                default: state_m <= s0; // 기본 상태는 s0
            endcase
        end
    end

    // 시계 모듈 출력
    wire [7:0] watch_seg_data; // 시계 모듈의 7-세그먼트 데이터
    wire [7:0] watch_seg_com;  // 시계 모듈의 7-세그먼트 공통 신호

    watch watch_inst (
        .clk(clk),       // 시계는 1kHz 클럭 사용
        .rst(rst),       // 리셋 신호
        .seg_data(watch_seg_data), // 시계 데이터 출력
        .seg_com(watch_seg_com)    // 시계 공통 신호 출력
    );

    // 스톱워치 모듈 추가
    wire [7:0] stopwatch_seg_data; // 스톱워치 7-세그먼트 데이터
    wire [7:0] stopwatch_seg_com;  // 스톱워치 7-세그먼트 공통 신호

    stopwatch stopwatch_inst (
        .clk(clk),           // 1kHz 클럭
        .rst(rst),           // 리셋 신호
        .start(start),        // 모듈 내부에서 버튼으로 제어
        .seg_data(stopwatch_seg_data), // 스톱워치 데이터 출력
        .seg_com(stopwatch_seg_com)    // 스톱워치 공통 신호 출력
    );

    assign lcd_e = clk_100hz;
    assign lcd_rw = 1'b0; // 항상 쓰기 모드

    // 상태별 7-세그먼트 디스플레이 출력
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_data <= 8'b0000_0000;
            seg_com <= 8'b1111_1111;
        end else begin
            case (state_m)
                s0: begin
                    // 시계 출력
                    seg_data = watch_seg_data;
                    seg_com = watch_seg_com;
                end
                s1: begin
                    // 스톱워치 출력
                    seg_data = stopwatch_seg_data;
                    seg_com = stopwatch_seg_com;
                end
                s2: begin
                    // 알람 설정 (나중에 구현)
                    seg_data = 8'b0000_0000; // 기본값
                    seg_com = 8'b1111_1111; // 기본값
                end
                default: begin
                    seg_data = watch_seg_data;
                    seg_com = watch_seg_com;
                end
            endcase
        end
    end

endmodule
