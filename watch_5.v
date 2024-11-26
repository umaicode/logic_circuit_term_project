module watch(
    input clk,         // 1kHz clock
    input rst,         // Reset
    input set_time,    // 시간 설정 모드 활성화
    input [3:0] num_input,  // 숫자 입력 (0~9)
    output reg [7:0] seg_data,
    output reg [7:0] seg_com
);

// 카운터와 레지스터 선언
reg [9:0] h_cnt;
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// 시간 입력 관련 변수
reg [2:0] input_cnt;  // 입력 단계 카운터 (0~5)
reg input_mode;       // 입력 모드 활성화 플래그
reg input_done;       // 입력 완료 플래그

// 깜빡임 관련 변수
reg [15:0] blink_timer;  // 타이머 카운터 (깜빡임 주기)
reg blink_state;         // 깜빡임 상태 (ON/OFF)

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

// 깜빡임 타이머
always @(posedge clk or posedge rst) begin
    if (rst) begin
        blink_timer <= 0;
        blink_state <= 0;
    end else begin
        if (blink_timer >= 50000) begin // 500ms 기준 (1kHz에서 50,000 사이클)
            blink_timer <= 0;
            blink_state <= ~blink_state; // 깜빡임 상태 토글
        end else begin
            blink_timer <= blink_timer + 1;
        end
    end
end

// 시간 설정 및 동작 모드 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // 초기화
        input_cnt <= 0;
        input_mode <= 1; // 입력 모드 활성화
        input_done <= 0;
        h_ten <= 0; h_one <= 0;
        m_ten <= 0; m_one <= 0;
        s_ten <= 0; s_one <= 0;
        h_cnt <= 0;
    end else if (set_time) begin
        input_mode <= 1;  // 입력 모드 활성화
        input_done <= 0;
        input_cnt <= 0;   // 입력 카운터 초기화
    end else begin
        if (input_mode) begin
            // 입력 모드 처리
            case (input_cnt)
                3'd0: h_ten <= num_input;  // 시의 10의 자리 입력
                3'd1: h_one <= num_input;  // 시의 1의 자리 입력
                3'd2: m_ten <= num_input;  // 분의 10의 자리 입력
                3'd3: m_one <= num_input;  // 분의 1의 자리 입력
                3'd4: s_ten <= num_input;  // 초의 10의 자리 입력
                3'd5: begin
                    s_one <= num_input;    // 초의 1의 자리 입력
                    input_mode <= 0;       // 입력 완료 -> 입력 모드 비활성화
                    input_done <= 1;       // 입력 완료 플래그 설정
                end
            endcase

            if (input_cnt < 5)
                input_cnt <= input_cnt + 1;
        end else if (input_done) begin
            // 시계 동작 모드
            if (h_cnt >= 999) begin
                h_cnt <= 0;
                if (s_one == 9) begin
                    s_one <= 0;
                    if (s_ten == 5) begin
                        s_ten <= 0;
                        if (m_one == 9) begin
                            m_one <= 0;
                            if (m_ten == 5) begin
                                m_ten <= 0;
                                if (h_one == 9) begin
                                    h_one <= 0;
                                    if (h_ten == 2 && h_one == 3) begin
                                        h_ten <= 0;
                                    end else begin
                                        h_ten <= h_ten + 1;
                                    end
                                end else begin
                                    h_one <= h_one + 1;
                                end
                            end else begin
                                m_ten <= m_ten + 1;
                            end
                        end else begin
                            m_one <= m_one + 1;
                        end
                    end else begin
                        s_ten <= s_ten + 1;
                    end
                end else begin
                    s_one <= s_one + 1;
                end
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end
end

// 세그먼트 출력 제어
reg [2:0] s_cnt;

always @(posedge clk) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk) begin
    if (input_mode && blink_state) begin
        // 입력 모드에서 선택된 자리만 깜빡임
        case (input_cnt)
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= 8'b0000_0000; end // 깜빡이는 시의 10의 자리
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= 8'b0000_0000; end // 깜빡이는 시의 1의 자리
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= 8'b0000_0000; end // 깜빡이는 분의 10의 자리
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= 8'b0000_0000; end // 깜빡이는 분의 1의 자리
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= 8'b0000_0000; end // 깜빡이는 초의 10의 자리
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= 8'b0000_0000; end // 깜빡이는 초의 1의 자리
        endcase
    end else begin
        // 일반적인 세그먼트 출력
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
