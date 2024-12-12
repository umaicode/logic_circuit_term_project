module alarm(
    input clk,              // 1kHz clock
    input rst,              // 리셋 신호
    input [9:0] keypad,     // 키패드 입력 (0~9)
    input alarm_set_mode,   // 알람 설정 모드 활성화 신호 (예: '*' 키로 설정 모드 진입)
    output reg [3:0] alarm_h_ten, alarm_h_one, alarm_m_ten, alarm_m_one, // 알람 시간
    output reg alarm_set_done,    // 알람 설정 완료 플래그
    output reg alarm_triggered,   // 알람 트리거 플래그
    output reg [7:0] leds         // LED 출력
);

reg [2:0] input_cnt;       // 0부터 3까지의 입력 카운터
reg [9:0] keypad_prev;     // 이전 키패드 입력 상태 저장
reg [3:0] blink_count;     // LED 점등 반복 횟수 카운터
reg [15:0] blink_timer;    // LED 점등 시간 타이머

// 키패드 입력 감지 및 알람 시간 설정
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        alarm_set_done <= 0;
        alarm_triggered <= 0;
        alarm_h_ten <= 0; alarm_h_one <= 0;
        alarm_m_ten <= 0; alarm_m_one <= 0;
        leds <= 8'b00000000;
        keypad_prev <= 10'b0000000000;
        blink_count <= 0;
        blink_timer <= 0;
    end else begin
        keypad_prev <= keypad;
        
        if (alarm_set_mode) begin
            // 알람 설정 모드
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
                
                // 입력 카운터 증가
                if (input_cnt < 3) begin
                    input_cnt <= input_cnt + 1;
                end else begin
                    input_cnt <= 0; // 입력 완료 후 초기화
                end
            end
        end else begin
            alarm_set_done <= 0; // 알람 설정 모드가 비활성화되면 완료 플래그 초기화
        end
    end
end

// 알람 트리거 로직
always @(posedge clk or posedge rst) begin
    if (rst) begin
        alarm_triggered <= 0;
        blink_count <= 0;
        blink_timer <= 0;
        leds <= 8'b00000000;
    end else begin
        if (alarm_set_done && !alarm_triggered) begin
            alarm_triggered <= 1;
            blink_count <= 0;
            blink_timer <= 0;
        end

        // 알람 트리거가 활성화되면 LED 점멸 10번 반복
        if (alarm_triggered) begin
            if (blink_count < 10) begin
                if (blink_timer < 50000) begin
                    blink_timer <= blink_timer + 1;
                    leds <= 8'b11111111; // 모든 LED 점등
                end else if (blink_timer < 100000) begin
                    blink_timer <= blink_timer + 1;
                    leds <= 8'b00000000; // 모든 LED 소등
                end else begin
                    blink_timer <= 0;
                    blink_count <= blink_count + 1;
                end
            end else begin
                alarm_triggered <= 0; // 알람 종료
                leds <= 8'b00000000; // LED 끄기
            end
        end else begin
            leds <= 8'b00000000; // LED 끄기
        end
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
