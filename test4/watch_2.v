module watch(
    input clk,            // 1kHz clock
    input rst,            // 리셋 신호
    input dip_sw,         // DIP 스위치 입력 (1: 설정 모드, 0: 시계 모드)
    input [9:0] keypad,   // 키패드 입력 (0~9)
    output reg [7:0] seg_data,
    output reg [7:0] seg_com,
    output wire [7:0] leds // LEDs를 wire로 선언
);

// 알람 설정 모드
wire alarm_set_mode;
assign alarm_set_mode = dip_sw; // DIP 스위치를 통해 설정

// 시간 카운터
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;
reg [9:0] h_cnt;
reg input_done;
reg [9:0] keypad_prev;

// 알람 모듈 신호
wire [3:0] alarm_h_ten, alarm_h_one, alarm_m_ten, alarm_m_one;
wire alarm_set_done;
wire alarm_triggered;

// 알람 모듈 인스턴스화
alarm alarm_inst (
    .clk(clk),
    .rst(rst),
    .keypad(keypad),
    .alarm_set_mode(alarm_set_mode),
    .alarm_h_ten(alarm_h_ten),
    .alarm_h_one(alarm_h_one),
    .alarm_m_ten(alarm_m_ten),
    .alarm_m_one(alarm_m_one),
    .alarm_set_done(alarm_set_done),
    .alarm_triggered(alarm_triggered),
    .leds(leds) // LEDs 연결
);

// 키패드 입력 디코딩 및 시간 설정
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 0;
        input_done <= 0;
        h_ten <= 0; h_one <= 0;
        m_ten <= 0; m_one <= 0;
        s_ten <= 0; s_one <= 0;
        keypad_prev <= 10'b0000000000;
    end else begin
        keypad_prev <= keypad;
        if (dip_sw) begin
            // 시간 설정 모드
            if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
                case (input_done)
                    0: h_ten <= keypad_to_digit(keypad);
                    1: h_one <= keypad_to_digit(keypad);
                    2: m_ten <= keypad_to_digit(keypad);
                    3: m_one <= keypad_to_digit(keypad);
                    4: s_ten <= keypad_to_digit(keypad);
                    5: begin 
                        s_one <= keypad_to_digit(keypad); 
                        input_done <= 1;
                    end
                endcase
            end
        end else if (input_done) begin
            // 시계 카운터 모드
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
