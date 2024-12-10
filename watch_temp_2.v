module watch(clk, rst, dip_sw, keypad, seg_data, seg_com);

input clk;            // 1kHz clock
input rst;            // 리셋 신호
input dip_sw;         // DIP 스위치 입력 (1: 설정 모드, 0: 시계 모드)
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
reg [3:0] current_digit;   // 현재 입력된 키패드 숫자
reg [19:0] h_cnt;          // 1초 카운터 (20비트로 확장)
reg input_done;            // 입력 완료 플래그

// -----------------------------
// 키패드 입력 디코딩 (디바운싱)
// -----------------------------
reg [9:0] keypad_prev;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_digit <= 4'd0;
        keypad_prev <= 10'b0000000000;
    end else begin
        keypad_prev <= keypad;
        if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
            case (keypad)
                10'b0000000001: current_digit <= 4'd0;
                10'b0000000010: current_digit <= 4'd1;
                10'b0000000100: current_digit <= 4'd2;
                10'b0000001000: current_digit <= 4'd3;
                10'b0000010000: current_digit <= 4'd4;
                10'b0000100000: current_digit <= 4'd5;
                10'b0001000000: current_digit <= 4'd6;
                10'b0010000000: current_digit <= 4'd7;
                10'b0100000000: current_digit <= 4'd8;
                10'b1000000000: current_digit <= 4'd9;
                default: current_digit <= 4'd0;
            endcase
        end
    end
end

// -----------------------------
// 시간 설정 모드
// -----------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        input_done <= 0;
        h_ten <= 0; h_one <= 0;
        m_ten <= 0; m_one <= 0;
        s_ten <= 0; s_one <= 0;
    end else if (dip_sw) begin
        if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
            case (input_cnt)
                0: h_ten <= current_digit;
                1: h_one <= current_digit;
                2: m_ten <= current_digit;
                3: m_one <= current_digit;
                4: s_ten <= current_digit;
                5: begin
                    s_one <= current_digit;
                    input_done <= 1; // 설정 완료
                end
            endcase
            if (input_cnt < 5) begin
                input_cnt <= input_cnt + 1;
            end else begin
                input_cnt <= 0;     // 입력 완료 후 초기화
            end
        end
    end else begin
        input_done <= 0; // 시계 모드로 전환 시 플래그 리셋
    end
end

// -----------------------------
// 시계 카운터 모드
// -----------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 0;
    end else if (!dip_sw) begin
        if (h_cnt >= 999_999) begin // 1Hz 카운트 (assuming clk is 1MHz)
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

// -----------------------------
// 세그먼트 디코딩
// -----------------------------
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// -----------------------------
// 세그먼트 표시 (입력과 무관하게 각 자리 표시)
// -----------------------------
reg [2:0] s_cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_cnt <= 0;
    end else begin
        s_cnt <= s_cnt + 1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_com <= 8'b1111_1111;
        seg_data <= 8'b0000_0000;
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
