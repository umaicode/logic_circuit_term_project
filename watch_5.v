module watch(clk, rst, seg_data, seg_com, key_input, btn_set);

input clk;             // 1kHz clock
input rst;
input [9:0] key_input; // 키패드 입력 (12개 핀: key_input[0]~key_input[11], '#'은 key_input[10])
input btn_set;         // 별도의 초기화 버튼 (옵션)
output reg [7:0] seg_data;
output reg [7:0] seg_com;

// 시계 관련 레지스터
reg [9:0] h_cnt;
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;
wire [7:0] seg_h_ten, seg_h_one, seg_m_ten, seg_m_one, seg_s_ten, seg_s_one;
reg [2:0] s_cnt;

// 설정 모드 및 작동 플래그
reg set_mode;          // 설정 모드 플래그
reg run_mode;          // 시계 작동 플래그
reg [2:0] current_digit; // 현재 설정 중인 자리 (0: h_ten, 1: h_one, ...)

// 입력된 키값 감지
reg [3:0] detected_key;

// 초기화
always @(posedge clk or posedge rst) begin
    if (rst) begin
        set_mode <= 1'b1;      // 초기화 시 설정 모드 활성화
        run_mode <= 1'b0;      // 시계 정지 상태
        current_digit <= 3'd0;
        h_ten <= 4'd0; h_one <= 4'd0;
        m_ten <= 4'd0; m_one <= 4'd0;
        s_ten <= 4'd0; s_one <= 4'd0;
        detected_key <= 4'd15; // 감지된 키 초기화
    end else if (btn_set) begin
        set_mode <= 1'b1;      // 버튼 입력 시 설정 모드 활성화
        run_mode <= 1'b0;      // 시계 정지 상태로 전환
        current_digit <= 3'd0;
    end else if (set_mode) begin
        if (|key_input) begin
            // 키패드 입력 처리
            case (key_input)
                12'b000000000001: detected_key <= 4'd0;
                12'b000000000010: detected_key <= 4'd1;
                12'b000000000100: detected_key <= 4'd2;
                12'b000000001000: detected_key <= 4'd3;
                12'b000000010000: detected_key <= 4'd4;
                12'b000000100000: detected_key <= 4'd5;
                12'b000001000000: detected_key <= 4'd6;
                12'b000010000000: detected_key <= 4'd7;
                12'b000100000000: detected_key <= 4'd8;
                12'b001000000000: detected_key <= 4'd9;
                12'b010000000000: begin
                    // '#' 입력 시 설정 완료
                    set_mode <= 1'b0; // 설정 모드 비활성화
                    run_mode <= 1'b1; // 시계 작동 시작
                end
                default: detected_key <= 4'd15; // 아무 입력도 없을 경우
            endcase

            // 키 입력에 따라 시간 설정 (set_mode 상태에서만)
            if (detected_key != 4'd15) begin
                case (current_digit)
                    3'd0: h_ten <= (detected_key > 4'd2) ? 4'd0 : detected_key; // 최대값: 2
                    3'd1: h_one <= (h_ten == 4'd2 && detected_key > 4'd3) ? 4'd0 : detected_key; // 최대값: 3
                    3'd2: m_ten <= (detected_key > 4'd5) ? 4'd0 : detected_key; // 최대값: 5
                    3'd3: m_one <= detected_key; // 최대값: 9
                    3'd4: s_ten <= (detected_key > 4'd5) ? 4'd0 : detected_key; // 최대값: 5
                    3'd5: s_one <= detected_key; // 최대값: 9
                endcase
                current_digit <= (current_digit == 3'd5) ? 3'd0 : current_digit + 1; // 자리 이동
            end
        end
    end
end

// 시계 카운터 (run_mode 상태에서만 작동)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 0;
    end else if (run_mode) begin
        if (h_cnt >= 999) begin
            h_cnt <= 0;

            // 초 증가
            if (s_one >= 9) begin
                s_one <= 0;
                if (s_ten >= 5) begin
                    s_ten <= 0;

                    // 분 증가
                    if (m_one >= 9) begin
                        m_one <= 0;
                        if (m_ten >= 5) begin
                            m_ten <= 0;

                            // 시간 증가
                            if (h_one >= 9) begin
                                h_one <= 0;
                                if (h_ten >= 2 && h_one >= 3) begin
                                    h_ten <= 0;
                                    h_one <= 0;
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

// 디코더 연결
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// 세그먼트 디스플레이
always @(posedge clk) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk) begin
    if (rst) seg_com <= 8'b1111_1111;
    else begin
        case (s_cnt)
            3'd0: seg_com <= 8'b0111_1111; // h_ten
            3'd1: seg_com <= 8'b1011_1111; // h_one
            3'd2: seg_com <= 8'b1101_1111; // m_ten
            3'd3: seg_com <= 8'b1110_1111; // m_one
            3'd4: seg_com <= 8'b1111_0111; // s_ten
            3'd5: seg_com <= 8'b1111_1011; // s_one
            default: seg_com <= 8'b1111_1111;
        endcase
    end
end

always @(posedge clk) begin
    if (rst) seg_data <= 8'b0000_0000;
    else begin
        case (s_cnt)
            3'd0: seg_data <= seg_h_ten;
            3'd1: seg_data <= seg_h_one;
            3'd2: seg_data <= seg_m_ten;
            3'd3: seg_data <= seg_m_one;
            3'd4: seg_data <= seg_s_ten;
            3'd5: seg_data <= seg_s_one;
            default: seg_data <= 8'b0000_0000;
        endcase
    end
end

endmodule
