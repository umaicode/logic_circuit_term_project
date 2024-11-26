module watch(clk, rst, seg_data, seg_com, key_input, btn_done);

input clk;           // 1kHz clock
input rst;
input [9:0] key_input;  // 넘버패드 입력 (10개 핀: key_input[0] ~ key_input[9])
input btn_done;      // 설정 완료 버튼
output reg [7:0] seg_data;
output reg [7:0] seg_com;

// 기존의 카운터 관련 reg와 wire
reg [9:0] h_cnt;
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;
wire [7:0] seg_h_ten, seg_h_one, seg_m_ten, seg_m_one, seg_s_ten, seg_s_one;
reg [2:0] s_cnt;

// 시간 설정 모드 플래그
reg set_mode;
reg [2:0] current_digit;  // 현재 입력 중인 자리 (0: h_ten, 1: h_one, ...)

// 시계 카운터는 그대로 사용
// watch count

always @(posedge rst or posedge clk)
    if (rst) h_cnt = 0;
    else if (h_cnt >=999) h_cnt = 0;
    else h_cnt = h_cnt + 1;

always @(posedge rst or posedge clk)
    if (rst) s_one = 0;
    else if (h_cnt == 999)
        if (s_one >= 9) s_one = 0;
        else s_one = s_one + 1;

always @(posedge rst or posedge clk)
    if (rst) s_ten = 0;
    else if (h_cnt == 999 && s_one == 9)
        if (s_ten >= 5) s_ten = 0;
        else s_ten = s_ten + 1;

always @(posedge rst or posedge clk)
    if (rst) m_one = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5))
        if (m_one >= 9) m_one = 0;
        else m_one = m_one + 1;

always @(posedge rst or posedge clk)
    if (rst) m_ten = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9))
        if (m_ten >= 5) m_ten = 0;
        else m_ten = m_ten + 1;

// TODO : 시간 출력을 위한 카운터 추가
always @(posedge rst or posedge clk)
    if (rst) h_ten = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9) && (m_ten == 5)) begin
        if (h_ten == 2 && h_one == 3) begin
            // "23:59:59 → 00:00:00" 처리
            h_ten = 0;
            h_one = 0;
        end else if (h_one == 9) begin
            // h_one이 9일 때 h_ten 증가
            h_one = 0;
            h_ten = h_ten + 1;
        end else begin
            // 일반적인 h_one 증가
            h_one = h_one + 1;
        end
    end

// 설정 모드 구현
always @(posedge clk or posedge rst) begin
    if (rst) begin
        set_mode <= 1'b1;  // 초기화 시 설정 모드 활성화
        current_digit <= 3'd0;  // 초기화 시 h_ten부터 시작
        h_ten <= 4'd0; h_one <= 4'd0; m_ten <= 4'd0; m_one <= 4'd0; s_ten <= 4'd0; s_one <= 4'd0;
    end else if (btn_done) begin
        set_mode <= 1'b0;  // 설정 완료 시 모드 비활성화
    end else if (set_mode) begin
        // 넘버패드 입력 처리
        if (|key_input) begin  // 키 입력이 감지되었을 때
            case (key_input)
                10'b0000000001: process_input(4'd0);  // 키 0
                10'b0000000010: process_input(4'd1);  // 키 1
                10'b0000000100: process_input(4'd2);  // 키 2
                10'b0000001000: process_input(4'd3);  // 키 3
                10'b0000010000: process_input(4'd4);  // 키 4
                10'b0000100000: process_input(4'd5);  // 키 5
                10'b0001000000: process_input(4'd6);  // 키 6
                10'b0010000000: process_input(4'd7);  // 키 7
                10'b0100000000: process_input(4'd8);  // 키 8
                10'b1000000000: process_input(4'd9);  // 키 9
            endcase
        end
    end
end

// 입력 처리 함수
task process_input(input [3:0] value);
begin
    case (current_digit)
        3'd0: h_ten <= (value > 4'd2) ? 4'd0 : value;  // h_ten 최대값: 2
        3'd1: h_one <= (h_ten == 4'd2 && value > 4'd3) ? 4'd0 : value;  // h_one 최대값: 3 (h_ten이 2일 때)
        3'd2: m_ten <= (value > 4'd5) ? 4'd0 : value;  // m_ten 최대값: 5
        3'd3: m_one <= value;  // m_one 최대값: 9
        3'd4: s_ten <= (value > 4'd5) ? 4'd0 : value;  // s_ten 최대값: 5
        3'd5: s_one <= value;  // s_one 최대값: 9
    endcase
    // 다음 자리로 이동
    current_digit <= (current_digit == 3'd5) ? 3'd0 : current_digit + 1;
end
endtask

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
