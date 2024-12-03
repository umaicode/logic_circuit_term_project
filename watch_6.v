module watch(clk, rst, set_time, keypad, seg_data, seg_com);

input clk;  // 1kHz clock
input rst;  // 리셋 신호
input set_time;  // 시간 설정 모드 신호 (1: 설정 모드, 0: 동작 모드)
input [9:0] keypad;  // 키패드 입력 (0~9)
output reg [7:0] seg_data;  // 세그먼트 데이터
output reg [7:0] seg_com;  // 세그먼트 선택 신호

// 기존 watch count의 레지스터들
reg [9:0] h_cnt;  
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// 키패드 입력 관련 레지스터
reg [23:0] time_input;  // 키패드 입력 저장 (HHMMSS)
reg [3:0] input_cnt;  // 키패드 입력 카운트
reg set_complete;  // 설정 완료 플래그

// 세그먼트 관련 레지스터 및 wires
reg [2:0] s_cnt;  // 세그먼트 선택 카운터
wire [7:0] seg_h_ten, seg_h_one, seg_m_ten, seg_m_one, seg_s_ten, seg_s_one;

// 키패드 입력 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        time_input <= 0;
        set_complete <= 0;
    end else if (set_time) begin
        // 설정 모드: 키패드 입력 처리
        if (input_cnt < 6) begin
            time_input <= (time_input * 10) + keypad;  // 입력 숫자 저장
            input_cnt <= input_cnt + 1;
        end else begin
            // 설정 완료
            h_ten <= time_input[23:20];
            h_one <= time_input[19:16];
            m_ten <= time_input[15:12];
            m_one <= time_input[11:8];
            s_ten <= time_input[7:4];
            s_one <= time_input[3:0];
            set_complete <= 1;  // 설정 완료 플래그 활성화
        end
    end
end

// watch count
always @(posedge rst or posedge clk)
    if (rst) h_cnt = 0;
    else if (h_cnt >= 999) h_cnt = 0;
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

always @(posedge rst or posedge clk)
    if (rst) h_ten = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9) && (m_ten == 5)) begin
        if (h_ten == 2 && h_one == 3) begin
            h_ten = 0;
            h_one = 0;
        end else if (h_one == 9) begin
            h_one = 0;
            h_ten = h_ten + 1;
        end else begin
            h_one = h_one + 1;
        end
    end

// 세그먼트 디스플레이
always @(posedge clk) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk) begin
    case (s_cnt)
        3'd0: seg_com <= 8'b0111_1111;  // 시의 10의 자리
        3'd1: seg_com <= 8'b1011_1111;  // 시의 1의 자리
        3'd2: seg_com <= 8'b1101_1111;  // 분의 10의 자리
        3'd3: seg_com <= 8'b1110_1111;  // 분의 1의 자리
        3'd4: seg_com <= 8'b1111_0111;  // 초의 10의 자리
        3'd5: seg_com <= 8'b1111_1011;  // 초의 1의 자리
        3'd6: seg_com <= 8'b1111_1101;  // 비활성화
        3'd7: seg_com <= 8'b1111_1110;  // 비활성화
    endcase
end

always @(posedge clk) begin
    case (s_cnt)
        3'd0: seg_data <= seg_h_ten;
        3'd1: seg_data <= seg_h_one;
        3'd2: seg_data <= seg_m_ten;
        3'd3: seg_data <= seg_m_one;
        3'd4: seg_data <= seg_s_ten;
        3'd5: seg_data <= seg_s_one;
        3'd6: seg_data <= 8'b0000_0000;  // 비활성화
        3'd7: seg_data <= 8'b0000_0000;  // 비활성화
    endcase
end

// 7세그먼트 디코딩
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

endmodule
