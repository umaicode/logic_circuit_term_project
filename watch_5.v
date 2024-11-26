module watch(clk, rst, seg_data, seg_com, btn_set, btn_inc, btn_done);

input clk;  // 1kHz clock
input rst;
input btn_set;  // 시간 설정 모드 활성화 버튼
input btn_inc;  // 설정 모드에서 숫자 증가 버튼
input btn_done; // 설정 완료 버튼
output reg [7:0] seg_data;
output reg [7:0] seg_com;

// 기존의 카운터 관련 reg와 wire
reg [9:0] h_cnt;
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;
wire [7:0] seg_h_ten, seg_h_one, seg_m_ten, seg_m_one, seg_s_ten, seg_s_one;
reg [2:0] s_cnt;

// 시간 설정 모드 플래그
reg set_mode;
reg [2:0] current_digit;  // 설정 중인 숫자의 자리 (0: h_ten, 1: h_one, ...)

// 시계 카운터는 그대로 사용
always @(posedge rst or posedge clk)
    if (rst) h_cnt = 0;
    else if (h_cnt >= 999) h_cnt = 0;
    else h_cnt = h_cnt + 1;

// 설정 모드 구현
always @(posedge clk or posedge rst) begin
    if (rst) begin
        set_mode <= 1'b1;  // 초기화 시 설정 모드 활성화
        current_digit <= 3'd0;  // 초기화 시 h_ten부터 시작
    end else if (btn_done) begin
        set_mode <= 1'b0;  // 설정 완료 시 모드 비활성화
    end else if (btn_set) begin
        // 설정할 자리를 순서대로 이동
        current_digit <= (current_digit == 3'd5) ? 3'd0 : current_digit + 1;
    end else if (btn_inc && set_mode) begin
        // 현재 설정 중인 자리를 증가
        case (current_digit)
            3'd0: h_ten <= (h_ten == 2) ? 0 : h_ten + 1;  // 최대값: 2
            3'd1: h_one <= (h_ten == 2 && h_one == 3) ? 0 : (h_one == 9 ? 0 : h_one + 1);  // 최대값: 3 (h_ten이 2일 때)
            3'd2: m_ten <= (m_ten == 5) ? 0 : m_ten + 1;  // 최대값: 5
            3'd3: m_one <= (m_one == 9) ? 0 : m_one + 1;  // 최대값: 9
            3'd4: s_ten <= (s_ten == 5) ? 0 : s_ten + 1;  // 최대값: 5
            3'd5: s_one <= (s_one == 9) ? 0 : s_one + 1;  // 최대값: 9
        endcase
    end
end

// 디코딩
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// 세그먼트 표시 제어
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
