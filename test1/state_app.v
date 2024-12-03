module state_app(
    input rst,         // 리셋 신호 (active high)
    input clk,         // 1kHz 입력 클럭
    input mode,        // 상태 전환 신호
    input motor_sense, // 모터 센서 신호
    output [3:0] fled_r, fled_g, fled_b, // RGB LED 제어
    output [7:0] seg_dat, seg_com,       // 7-세그먼트 디스플레이 데이터 및 공통 신호
    output [3:0] step_motor,             // 스텝 모터 제어
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

    // LCD 출력 데이터
    reg [7:0] line1_data [0:6]; // "mode 0" (7글자)
    reg [7:0] line2_data [0:4]; // "watch" (5글자)
    integer lcd_cnt;

    // 초기화 시 LCD 데이터 배열 설정
    always @(posedge rst) begin
        if (rst) begin
            // Line 1: "mode 0"
            line1_data[0] <= 8'h6D; // 'm'
            line1_data[1] <= 8'h6F; // 'o'
            line1_data[2] <= 8'h64; // 'd'
            line1_data[3] <= 8'h65; // 'e'
            line1_data[4] <= 8'h20; // ' '
            line1_data[5] <= 8'h30; // '0'
            line1_data[6] <= 8'h00; // Null terminator

            // Line 2: "watch"
            line2_data[0] <= 8'h77; // 'w'
            line2_data[1] <= 8'h61; // 'a'
            line2_data[2] <= 8'h74; // 't'
            line2_data[3] <= 8'h63; // 'c'
            line2_data[4] <= 8'h68; // 'h'
            line2_data[5] <= 8'h00; // Null terminator

            lcd_cnt <= 0; // LCD 출력 카운터 초기화
        end
    end

    // LCD 출력 로직
    always @(posedge clk_100hz or posedge rst) begin
        if (rst) begin
            lcd_cnt <= 0; // 카운터 초기화
        end else if (state_m == s0) begin
            case (lcd_cnt)
                // Line 1: "mode 0"
                0: begin
                    lcd_rs <= 1'b0;      // 명령 모드
                    lcd_data <= 8'b1000_0000; // Line 1 커서 시작 위치
                end
                1, 2, 3, 4, 5, 6: begin
                    lcd_rs <= 1'b1;      // 데이터 모드
                    lcd_data <= line1_data[lcd_cnt - 1];
                end
                // Line 2: "watch"
                7: begin
                    lcd_rs <= 1'b0;      // 명령 모드
                    lcd_data <= 8'b1100_0000; // Line 2 커서 시작 위치
                end
                8, 9, 10, 11, 12: begin
                    lcd_rs <= 1'b1;      // 데이터 모드
                    lcd_data <= line2_data[lcd_cnt - 8];
                end
                default: begin
                    lcd_cnt <= -1; // 완료 후 초기화
                end
            endcase
            lcd_cnt <= lcd_cnt + 1;
        end else begin
            lcd_cnt <= 0; // 다른 상태에서는 초기화
        end
    end

    assign lcd_e = clk_100hz;
    assign lcd_rw = 1'b0; // 항상 쓰기 모드

    // 상태 s1, s2의 동작 및 나머지 로직은 원래 코드 유지
    // 상태 s1: RGB LED 점등
    always @(posedge clk_100hz or posedge rst) begin
        if (rst) begin
            cnt_fled <= 0; // 리셋 시 초기화
        end else if (state_m == s1) begin
            cnt_fled <= cnt_fled + 1; // 100Hz 클럭에서 카운터 증가
        end else begin
            cnt_fled <= 0; // s1이 아닐 때 초기화
        end
    end

    assign fled_r = {cnt_fled[7], cnt_fled[7], cnt_fled[7], cnt_fled[7]};
    assign fled_g = {cnt_fled[6], cnt_fled[6], cnt_fled[6], cnt_fled[6]};
    assign fled_b = {cnt_fled[5], cnt_fled[5], cnt_fled[5], cnt_fled[5]};

    // 상태 s2: 스텝 모터 제어
    always @(posedge clk_100hz or posedge rst) begin
        if (rst) begin
            cnt_motor <= 0; // 리셋 시 초기화
        end else if (state_m == s2) begin
            cnt_motor <= cnt_motor + 1; // 100Hz 클럭에서 카운터 증가
        end else begin
            cnt_motor <= 0; // s2가 아닐 때 초기화
        end
    end

    reg [3:0] step_motor_reg; // 스텝 모터 상태 저장
    always @(posedge clk_100hz) begin
        if (state_m == s2) begin
            case (cnt_motor)
                2'b00: step_motor_reg <= 4'b1100;
                2'b01: step_motor_reg <= 4'b0110;
                2'b10: step_motor_reg <= 4'b0011;
                2'b11: step_motor_reg <= 4'b1001;
                default: step_motor_reg <= 4'b0000;
            endcase
        end else begin
            step_motor_reg <= 4'b0000;
        end
    end
    assign step_motor = step_motor_reg;

    // 상태에 따른 7-세그먼트 디스플레이 출력
    always @(posedge clk_100hz or posedge rst) begin
        if (rst) begin
            seg_dat <= 8'b0000_0000;
            seg_com <= 8'b1111_1111;
        end else begin
            case (state_m)
                s0: begin
                    // 시계 출력
                    seg_dat <= watch_seg_data;
                    seg_com <= watch_seg_com;
                end
                s1: begin
                    // LED 상태를 디스플레이 (필요하면 구현)
                    seg_dat <= 8'b0000_0000;
                    seg_com <= 8'b1111_1111;
                end
                s2: begin
                    // 모터 상태를 디스플레이 (필요하면 구현)
                    seg_dat <= 8'b0000_0000;
                    seg_com <= 8'b1111_1111;
                end
                default: begin
                    seg_dat <= 8'b0000_0000;
                    seg_com <= 8'b1111_1111;
                end
            endcase
        end
    end

endmodule
