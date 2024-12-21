module alarm(
    input clk,              // 1kHz clock
    input rst,              // 리셋 신호
    input [9:0] keypad,     // 키패드 입력 (0~9)
    input alarm_set_mode,   // 알람 설정 모드 활성화 신호
    output reg [3:0] alarm_h_ten, alarm_h_one, alarm_m_ten, alarm_m_one, // 알람 시간
    output reg alarm_set_done,    // 알람 설정 완료 플래그
    output reg alarm_triggered,   // 알람 트리거 플래그
    output reg [7:0] seg_data,    // 7-세그먼트 데이터 출력
    output reg [7:0] seg_com      // 7-세그먼트 공통 신호 출력
);

reg [2:0] input_cnt;        // 0부터 3까지의 입력 카운터
reg [9:0] keypad_prev;      // 이전 키패드 입력 상태 저장
reg [2:0] s_cnt;            // 세그먼트 선택 카운터

// 키패드 입력 감지 및 알람 시간 설정
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        alarm_set_done <= 0;
        alarm_h_ten <= 0; alarm_h_one <= 0;
        alarm_m_ten <= 0; alarm_m_one <= 0;
        keypad_prev <= 10'b0000000000;
    end else begin
        keypad_prev <= keypad;

        if (alarm_set_mode) begin
            if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
                case (input_cnt)
                    0: alarm_h_ten <= keypad_to_digit(keypad);
                    1: alarm_h_one <= keypad_to_digit(keypad);
                    2: alarm_m_ten <= keypad_to_digit(keypad);
                    3: begin
                        alarm_m_one <= keypad_to_digit(keypad);
                        alarm_set_done <= 1; // 알람 설정 완료
                    end
                endcase

                if (input_cnt < 3) begin
                    input_cnt <= input_cnt + 1;
                end else begin
                    input_cnt <= 0; // 입력 완료 후 초기화
                end
            end
        end else begin
            alarm_set_done <= 0; // 알람 설정 모드 종료 시 플래그 초기화
        end
    end
end

// 세그먼트 디코딩
wire [7:0] seg_alarm_h_ten, seg_alarm_h_one, seg_alarm_m_ten, seg_alarm_m_one;

seg_decode u0 (alarm_h_ten, seg_alarm_h_ten);
seg_decode u1 (alarm_h_one, seg_alarm_h_one);
seg_decode u2 (alarm_m_ten, seg_alarm_m_ten);
seg_decode u3 (alarm_m_one, seg_alarm_m_one);

// 세그먼트 표시
always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_cnt <= 0;
        seg_com <= 8'b11111111;
        seg_data <= 8'b00000000;
    end else begin
        s_cnt <= s_cnt + 1;
        case (s_cnt)
            3'd0: begin seg_com <= 8'b01111111; seg_data <= seg_alarm_h_ten; end
            3'd1: begin seg_com <= 8'b10111111; seg_data <= seg_alarm_h_one; end
            3'd2: begin seg_com <= 8'b11011111; seg_data <= seg_alarm_m_ten; end
            3'd3: begin seg_com <= 8'b11101111; seg_data <= seg_alarm_m_one; end
            default: begin seg_com <= 8'b11111111; seg_data <= 8'b00000000; end
        endcase
    end
end

// 키패드 입력을 숫자로 변환하는 함수
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

endmodule
