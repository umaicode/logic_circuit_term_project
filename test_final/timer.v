module timer(clk, rst, dip_sw, keypad, seg_data, seg_com);

input clk;            // 1kHz 클럭
input rst;            // 리셋 신호
input dip_sw;         // DIP 스위치 (1: 설정 모드, 0: 카운트다운 모드)
input [9:0] keypad;   // 키패드 입력 (0~9)

output reg [7:0] seg_data; // 7-Segment 데이터 출력
output reg [7:0] seg_com;  // 7-Segment 공통 출력

// 시간 변수 (hh:mm:ss)
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// 키패드 입력 상태 저장
reg [2:0] input_cnt;       // 입력 자리수 카운터 (0~5)
reg [9:0] h_cnt;           // 1ms 카운터
reg input_done;            // 키패드 입력 완료 상태
reg timer_done;            // 타이머 종료 상태

// 이전 키패드 상태 저장
reg [9:0] keypad_prev;

// 키패드 -> 숫자 변환 함수
function [3:0] keypad_to_digit;
    input [9:0] keypad;
    case (keypad)
        10'b0000000001: keypad_to_digit = 4'd0;
        10'b0000000010: keypad_to_digit = 4'd1;
        10'b0000000100: keypad_to_digit = 4'd2;
        10'b0000001000: keypad_to_digit = 4'd3;
        10'b0000010000: keypad_to_digit = 4'd4;
        10'b0000100000: keypad_to_digit = 4'd5;
        10'b0001000000: keypad_to_digit = 4'd6;
        10'b0010000000: keypad_to_digit = 4'd7;
        10'b0100000000: keypad_to_digit = 4'd8;
        10'b1000000000: keypad_to_digit = 4'd9;
        default: keypad_to_digit = 4'd0;
    endcase
endfunction

// DIP 스위치에 따른 모드 전환 및 키패드 입력 처리
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        input_done <= 0;
        h_cnt <= 0;
        timer_done <= 0;
        h_ten <= 0; h_one <= 0;
        m_ten <= 0; m_one <= 0;
        s_ten <= 0; s_one <= 0;
        keypad_prev <= 10'b0000000000;
    end else begin
        keypad_prev <= keypad;

        if (dip_sw == 1 && !input_done) begin
            // 설정 모드 (키패드 입력 처리)
            if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
                case (input_cnt)
                    0: h_ten <= keypad_to_digit(keypad);
                    1: h_one <= keypad_to_digit(keypad);
                    2: m_ten <= keypad_to_digit(keypad);
                    3: m_one <= keypad_to_digit(keypad);
                    4: s_ten <= keypad_to_digit(keypad);
                    5: begin 
                        s_one <= keypad_to_digit(keypad); 
                        input_done <= 1; // 입력 완료
                    end
                endcase

                if (input_cnt < 5) begin
                    input_cnt <= input_cnt + 1;
                end else begin
                    input_cnt <= 0;
                end
            end
        end else if (dip_sw == 0 && input_done && !timer_done) begin
            // 카운트다운 모드
            if (h_cnt >= 999) begin // 1초마다 감소
                h_cnt <= 0;

                if (s_one == 0) begin
                    s_one <= 9;
                    if (s_ten == 0) begin
                        s_ten <= 5;
                        if (m_one == 0) begin
                            m_one <= 9;
                            if (m_ten == 0) begin
                                m_ten <= 5;
                                if (h_one == 0) begin
                                    h_one <= 9;
                                    if (h_ten == 0) begin
                                        timer_done <= 1; // 타이머 종료
                                    end else begin
                                        h_ten <= h_ten - 1;
                                    end
                                end else begin
                                    h_one <= h_one - 1;
                                end
                            end else begin
                                m_ten <= m_ten - 1;
                            end
                        end else begin
                            m_one <= m_one - 1;
                        end
                    end else begin
                        s_ten <= s_ten - 1;
                    end
                end else begin
                    s_one <= s_one - 1;
                end
            end else begin
                h_cnt <= h_cnt + 1; // 1ms 단위 증가
            end
        end
    end
end

// 7-Segment 디코딩
seg_decode u0 (h_ten, seg_data[7:0]);
seg_decode u1 (h_one, seg_data[7:0]);
seg_decode u2 (m_ten, seg_data[7:0]);
seg_decode u3 (m_one, seg_data[7:0]);
seg_decode u4 (s_ten, seg_data[7:0]);
seg_decode u5 (s_one, seg_data[7:0]);

// 7-Segment 표시 제어
always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_com <= 8'b1111_1111;
        seg_data <= 8'b0000_0000;
    end else begin
        case (h_cnt[2:0]) // 멀티플렉싱
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= h_ten; end
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= h_one; end
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= m_ten; end
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= m_one; end
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= s_ten; end
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= s_one; end
            default: begin seg_com <= 8'b1111_1111; seg_data <= 8'b0000_0000; end
        endcase
    end
end

endmodule
