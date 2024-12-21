module alarm(
    input clk,              // 1kHz clock
    input rst,              // 리셋 신호
    input [9:0] keypad,     // 키패드 입력 (0~9)
    input alarm_set_mode,   // 알람 설정 모드 활성화 신호
    output reg [3:0] alarm_h_ten, alarm_h_one, alarm_m_ten, alarm_m_one,
    output reg alarm_set_done,    // 알람 설정 완료 플래그
    output reg alarm_triggered,   // 알람 트리거 플래그
    output reg [7:0] leds         // LEDs 출력
);

// 키패드 입력 상태 저장
reg [2:0] input_cnt;
reg [9:0] keypad_prev;

// 알람 설정 로직
always @(posedge clk or posedge rst) begin
    if (rst) begin
        alarm_h_ten <= 0; alarm_h_one <= 0;
        alarm_m_ten <= 0; alarm_m_one <= 0;
        alarm_set_done <= 0;
        input_cnt <= 0;
    end else if (alarm_set_mode) begin
        if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
            case (input_cnt)
                0: alarm_h_ten <= keypad_to_digit(keypad);
                1: alarm_h_one <= keypad_to_digit(keypad);
                2: alarm_m_ten <= keypad_to_digit(keypad);
                3: begin
                    alarm_m_one <= keypad_to_digit(keypad);
                    alarm_set_done <= 1;
                end
            endcase
            if (input_cnt < 3) input_cnt <= input_cnt + 1;
            else input_cnt <= 0;
        end
        keypad_prev <= keypad;
    end else begin
        alarm_set_done <= 0;
    end
end

// 알람 트리거 로직
always @(posedge clk or posedge rst) begin
    if (rst) begin
        alarm_triggered <= 0;
        leds <= 8'b00000000;
    end else if (alarm_h_ten == h_ten && alarm_h_one == h_one &&
                 alarm_m_ten == m_ten && alarm_m_one == m_one) begin
        alarm_triggered <= 1;
        leds <= 8'b11111111;
    end else begin
        alarm_triggered <= 0;
        leds <= 8'b00000000;
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
