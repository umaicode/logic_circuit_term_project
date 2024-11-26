module watch(
    input clk,         // 1kHz clock
    input rst,         // Reset
    input set_time,    // 설정 모드 버튼 (# 버튼)
    input [9:0] num_input,  // 숫자 입력 (10개의 독립적인 핀: 0~9)
    output reg [7:0] seg_data,
    output reg [7:0] seg_com
);

// 카운터와 레지스터 선언
reg [9:0] h_cnt;
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// 시간 입력 관련 변수
reg [2:0] input_cnt;  // 입력 단계 카운터 (0~5)
reg input_mode;       // 입력 모드 활성화 플래그
reg input_confirmed;  // 숫자 입력 확인 플래그
reg [3:0] input_value; // 현재 눌린 숫자 (0~9)

// 깜빡임 관련 변수
reg [15:0] blink_timer;  // 타이머 카운터 (깜빡임 주기)
reg blink_state;         // 깜빡임 상태 (ON/OFF)

// 디바운싱 관련 변수
reg [15:0] debounce_timer_0, debounce_timer_1, debounce_timer_2, debounce_timer_3;
reg [15:0] debounce_timer_4, debounce_timer_5, debounce_timer_6, debounce_timer_7;
reg [15:0] debounce_timer_8, debounce_timer_9;

reg num_input_stable_0, num_input_stable_1, num_input_stable_2, num_input_stable_3;
reg num_input_stable_4, num_input_stable_5, num_input_stable_6, num_input_stable_7;
reg num_input_stable_8, num_input_stable_9;

// 디코딩 출력
wire [7:0] seg_h_ten, seg_h_one;
wire [7:0] seg_m_ten, seg_m_one;
wire [7:0] seg_s_ten, seg_s_one;

// 디코딩 모듈 연결
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// 디바운싱 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        debounce_timer_0 <= 0; debounce_timer_1 <= 0;
        debounce_timer_2 <= 0; debounce_timer_3 <= 0;
        debounce_timer_4 <= 0; debounce_timer_5 <= 0;
        debounce_timer_6 <= 0; debounce_timer_7 <= 0;
        debounce_timer_8 <= 0; debounce_timer_9 <= 0;

        num_input_stable_0 <= 0; num_input_stable_1 <= 0;
        num_input_stable_2 <= 0; num_input_stable_3 <= 0;
        num_input_stable_4 <= 0; num_input_stable_5 <= 0;
        num_input_stable_6 <= 0; num_input_stable_7 <= 0;
        num_input_stable_8 <= 0; num_input_stable_9 <= 0;
    end else begin
        // 각 버튼의 디바운싱 처리
        if (num_input[0]) begin
            if (debounce_timer_0 < 50000) debounce_timer_0 <= debounce_timer_0 + 1;
            else num_input_stable_0 <= 1;
        end else begin
            debounce_timer_0 <= 0;
            num_input_stable_0 <= 0;
        end

        if (num_input[1]) begin
            if (debounce_timer_1 < 50000) debounce_timer_1 <= debounce_timer_1 + 1;
            else num_input_stable_1 <= 1;
        end else begin
            debounce_timer_1 <= 0;
            num_input_stable_1 <= 0;
        end

        if (num_input[2]) begin
            if (debounce_timer_2 < 50000) debounce_timer_2 <= debounce_timer_2 + 1;
            else num_input_stable_2 <= 1;
        end else begin
            debounce_timer_2 <= 0;
            num_input_stable_2 <= 0;
        end

        if (num_input[3]) begin
            if (debounce_timer_3 < 50000) debounce_timer_3 <= debounce_timer_3 + 1;
            else num_input_stable_3 <= 1;
        end else begin
            debounce_timer_3 <= 0;
            num_input_stable_3 <= 0;
        end

        if (num_input[4]) begin
            if (debounce_timer_4 < 50000) debounce_timer_4 <= debounce_timer_4 + 1;
            else num_input_stable_4 <= 1;
        end else begin
            debounce_timer_4 <= 0;
            num_input_stable_4 <= 0;
        end

        if (num_input[5]) begin
            if (debounce_timer_5 < 50000) debounce_timer_5 <= debounce_timer_5 + 1;
            else num_input_stable_5 <= 1;
        end else begin
            debounce_timer_5 <= 0;
            num_input_stable_5 <= 0;
        end

        if (num_input[6]) begin
            if (debounce_timer_6 < 50000) debounce_timer_6 <= debounce_timer_6 + 1;
            else num_input_stable_6 <= 1;
        end else begin
            debounce_timer_6 <= 0;
            num_input_stable_6 <= 0;
        end

        if (num_input[7]) begin
            if (debounce_timer_7 < 50000) debounce_timer_7 <= debounce_timer_7 + 1;
            else num_input_stable_7 <= 1;
        end else begin
            debounce_timer_7 <= 0;
            num_input_stable_7 <= 0;
        end

        if (num_input[8]) begin
            if (debounce_timer_8 < 50000) debounce_timer_8 <= debounce_timer_8 + 1;
            else num_input_stable_8 <= 1;
        end else begin
            debounce_timer_8 <= 0;
            num_input_stable_8 <= 0;
        end

        if (num_input[9]) begin
            if (debounce_timer_9 < 50000) debounce_timer_9 <= debounce_timer_9 + 1;
            else num_input_stable_9 <= 1;
        end else begin
            debounce_timer_9 <= 0;
            num_input_stable_9 <= 0;
        end
    end
end

// 시계 동작 로직
always @(posedge clk or posedge rst) begin
    if (rst) h_cnt <= 0;
    else if (h_cnt >= 999) h_cnt <= 0;
    else h_cnt <= h_cnt + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst) s_one <= 0;
    else if (h_cnt == 999) begin
        if (s_one >= 9) s_one <= 0;
        else s_one <= s_one + 1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) s_ten <= 0;
    else if (h_cnt == 999 && s_one == 9) begin
        if (s_ten >= 5) s_ten <= 0;
        else s_ten <= s_ten + 1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) m_one <= 0;
    else if (h_cnt == 999 && s_one == 9 && s_ten == 5) begin
        if (m_one >= 9) m_one <= 0;
        else m_one <= m_one + 1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) m_ten <= 0;
    else if (h_cnt == 999 && s_one == 9 && s_ten == 5 && m_one == 9) begin
        if (m_ten >= 5) m_ten <= 0;
        else m_ten <= m_ten + 1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_ten <= 0;
        h_one <= 0;
    end else if (h_cnt == 999 && s_one == 9 && s_ten == 5 && m_one == 9 && m_ten == 5) begin
        if (h_ten == 2 && h_one == 3) begin
            h_ten <= 0;
            h_one <= 0;
        end else if (h_one == 9) begin
            h_one <= 0;
            h_ten <= h_ten + 1;
        end else begin
            h_one <= h_one + 1;
        end
    end
end

// 나머지 세그먼트 제어 및 설정 모드 로직 유지
// 세그먼트 출력 제어
reg [2:0] s_cnt;

always @(posedge clk) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk) begin
    if (input_mode && blink_state) begin
        case (input_cnt)
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= 8'b0000_0000; end
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= 8'b0000_0000; end
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= 8'b0000_0000; end
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= 8'b0000_0000; end
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= 8'b0000_0000; end
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= 8'b0000_0000; end
        endcase
    end else begin
        case (s_cnt)
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= seg_h_ten; end
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= seg_h_one; end
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= seg_m_ten; end
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= seg_m_one; end
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= seg_s_ten; end
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= seg_s_one; end
            default: begin seg_com <= 8'b1111_1111; seg_data <= 8'b0000_0000; end
        endcase
    end
end

endmodule
