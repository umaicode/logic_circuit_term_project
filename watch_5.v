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

// 숫자 입력 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_confirmed <= 0;
        input_value <= 0;
    end else begin
        // 숫자 입력 확인
        if (input_mode) begin
            case (num_input)
                10'b0000000001: begin input_value <= 4'd0; input_confirmed <= 1; end // 버튼 0
                10'b0000000010: begin input_value <= 4'd1; input_confirmed <= 1; end // 버튼 1
                10'b0000000100: begin input_value <= 4'd2; input_confirmed <= 1; end // 버튼 2
                10'b0000001000: begin input_value <= 4'd3; input_confirmed <= 1; end // 버튼 3
                10'b0000010000: begin input_value <= 4'd4; input_confirmed <= 1; end // 버튼 4
                10'b0000100000: begin input_value <= 4'd5; input_confirmed <= 1; end // 버튼 5
                10'b0001000000: begin input_value <= 4'd6; input_confirmed <= 1; end // 버튼 6
                10'b0010000000: begin input_value <= 4'd7; input_confirmed <= 1; end // 버튼 7
                10'b0100000000: begin input_value <= 4'd8; input_confirmed <= 1; end // 버튼 8
                10'b1000000000: begin input_value <= 4'd9; input_confirmed <= 1; end // 버튼 9
                default: input_confirmed <= 0;
            endcase
        end else begin
            input_confirmed <= 0; // 입력 모드가 아닐 때는 무시
        end
    end
end

// 시간 설정 및 동작 모드 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        input_mode <= 0;       // 초기에는 입력 모드 비활성화
        h_ten <= 0; h_one <= 0;
        m_ten <= 0; m_one <= 0;
        s_ten <= 0; s_one <= 0;
        h_cnt <= 0;
    end else if (set_time) begin
        // 설정 모드 활성화 (# 버튼 눌림)
        input_mode <= ~input_mode;
        input_cnt <= 0;
    end else if (input_mode) begin
        // 입력 모드: 숫자 입력 처리
        if (input_confirmed) begin
            case (input_cnt)
                3'd0: if (input_value <= 2) h_ten <= input_value;  // 시의 10의 자리 (0~2)
                3'd1: if ((h_ten < 2 && input_value <= 9) || (h_ten == 2 && input_value <= 3)) h_one <= input_value;  // 시의 1의 자리
                3'd2: if (input_value <= 5) m_ten <= input_value;  // 분의 10의 자리 (0~5)
                3'd3: if (input_value <= 9) m_one <= input_value;  // 분의 1의 자리 (0~9)
                3'd4: if (input_value <= 5) s_ten <= input_value;  // 초의 10의 자리 (0~5)
                3'd5: begin
                    if (input_value <= 9) s_one <= input_value;    // 초의 1의 자리 (0~9)
                    input_mode <= 0;       // 입력 완료 -> 입력 모드 비활성화
                end
            endcase

            if (input_cnt < 5)
                input_cnt <= input_cnt + 1;
        end
    end else begin
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
                                    h_ten <= 0; // 24시 -> 00시
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

// 세그먼트 출력 제어 (깜빡임 처리)
reg [2:0] s_cnt;

always @(posedge clk) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk) begin
    if (input_mode && blink_state) begin
        // 설정 중 현재 자릿수 깜빡임
        case (input_cnt)
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= 8'b0000_0000; end // 시의 10의 자리
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= 8'b0000_0000; end // 시의 1의 자리
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= 8'b0000_0000; end // 분의 10의 자리
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= 8'b0000_0000; end // 분의 1의 자리
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= 8'b0000_0000; end // 초의 10의 자리
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= 8'b0000_0000; end // 초의 1의 자리
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
