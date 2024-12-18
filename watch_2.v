module watch(clk, rst, keypad, seg_data, seg_com);

input clk;            // 1kHz clock
input rst;            // 리셋 신호
input [9:0] keypad;   // 키패드 입력 (0~9)

output reg [7:0] seg_data;
output reg [7:0] seg_com;

// 시간 카운터
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// 세그먼트 디코딩을 위한 wire
wire [7:0] seg_h_ten, seg_h_one;
wire [7:0] seg_m_ten, seg_m_one;
wire [7:0] seg_s_ten, seg_s_one;

// 입력 관련 상태
reg [2:0] input_cnt;       // 0부터 5까지의 입력 카운터
reg [9:0] current_digit;   // 현재 입력된 키패드 숫자
reg setting_mode;          // 설정 모드 활성화 플래그
reg [9:0] h_cnt;           // 1초 카운터

// 키패드 입력 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        setting_mode <= 1;
        h_ten <= 0;
        h_one <= 0;
        m_ten <= 0;
        m_one <= 0;
        s_ten <= 0;
        s_one <= 0;
    end else if (setting_mode) begin
        if (keypad != 10'b1111111111) begin  // 10비트 키패드 입력 조건
            current_digit <= keypad[3:0];    // 하위 4비트만 사용
            // current_digit <= keypad[9:0]  만약 안되면 이거 try 해보기.
            case (input_cnt)
                0: h_ten <= current_digit;
                1: h_one <= current_digit;
                2: m_ten <= current_digit;
                3: m_one <= current_digit;
                4: s_ten <= current_digit;
                5: begin
                    s_one <= current_digit;
                    setting_mode <= 0;       // 6자리 입력 후 설정 모드 종료
                end
            endcase
            input_cnt <= input_cnt + 1;
        end
    end
end

// 1초 카운터 (1kHz 입력을 기반으로 1초 단위로 동작)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 0;
        h_ten <= 0;
        h_one <= 0;
        m_ten <= 0;
        m_one <= 0;
        s_ten <= 0;
        s_one <= 0;
    end else if (!setting_mode) begin
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
                            if (h_ten == 2 && h_one == 3) begin
                                // 23:59:59에서 00:00:00으로 리셋
                                h_ten <= 0;
                                h_one <= 0;
                            end else if (h_one == 9) begin
                                h_one <= 0;
                                h_ten <= h_ten + 1;
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

// 세그먼트 디코딩
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// 세그먼트 표시
reg [2:0] s_cnt; // 세그먼트 선택 카운터

always @(posedge clk or posedge rst) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_com <= 8'b1111_1111;
        seg_data <= 8'b0000_0000;
    end else begin
        case(s_cnt)
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
