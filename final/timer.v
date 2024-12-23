module timer(
    input clk,                // 1kHz clock (상위에서 분주된 클록)
    input rst,                // 리셋(active high)
    input dip_sw_timer,       // 타이머 세팅 모드(1) / 동작 모드(0)
    input [9:0] keypad,       // 키패드 입력 (0~9)
    output reg [7:0] seg_data,// 7-Segment 표시 데이터
    output reg [7:0] seg_com, // 7-Segment Common
    output reg [7:0] led            // ★ 추가: LED 제어 신호
);
    //-----------------------------------
    // (1) 내부 레지스터/와이어 선언
    //-----------------------------------
    // 각 자리 시/분/초
    reg [3:0] h_ten, h_one;  // 시(00~99 가정)
    reg [3:0] m_ten, m_one;  // 분(00~59)
    reg [3:0] s_ten, s_one;  // 초(00~59)

    // 입력 관련
    reg [2:0] input_cnt;     // 0~5 (시 tens, 시 ones, 분 tens, 분 ones, 초 tens, 초 ones)
    reg [9:0] keypad_prev;
    reg input_done;          // 세팅이 끝났는지 표시

    // 타이머 동작 관련
    reg [9:0] h_cnt;         // 1ms마다 카운트 -> 1000이면 1초
    reg timer_done;          // 00:00:00 도달 시=1

    // LED 깜빡임 관련
    reg [15:0] blink_cnt;    // 깜빡임 주기 카운터

    //-----------------------------------
    // (2) 입력 세팅 로직
    //-----------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            input_cnt   <= 0;
            input_done  <= 0;
            timer_done  <= 0;
            h_cnt       <= 0;
            h_ten <= 0; h_one <= 0;
            m_ten <= 0; m_one <= 0;
            s_ten <= 0; s_one <= 0;
            keypad_prev <= 10'b0000000000;
            led         <= 1'b0;    // LED 초기값
            blink_cnt   <= 16'd0;   // 깜빡임 카운터 초기화
        end
        else begin
            // 이전 키패드 상태 저장 (에지 검출용)
            keypad_prev <= keypad;

            // (A) dip_sw_timer=1 -> 세팅 모드
            if (dip_sw_timer) begin
                timer_done <= 0;    // 동작 모드 해제
                h_cnt <= 0;         // 초 카운터 리셋

                // 키패드가 눌렸고, 직전에는 안눌린 상태였다면(에지 검출)
                if (keypad != 0 && keypad_prev == 0) begin
                    case (input_cnt)
                        0: h_ten <= keypad_to_digit(keypad);
                        1: h_one <= keypad_to_digit(keypad);
                        2: m_ten <= keypad_to_digit(keypad);
                        3: m_one <= keypad_to_digit(keypad);
                        4: s_ten <= keypad_to_digit(keypad);
                        5: begin
                            s_one <= keypad_to_digit(keypad);
                            input_done <= 1; // 6자리 모두 입력 완료
                        end
                    endcase

                    // 다음 자리로 이동
                    if (input_cnt < 5)
                        input_cnt <= input_cnt + 1;
                    else
                        input_cnt <= 0; // 다시 처음으로
                end
            end
            // (B) dip_sw_timer=0 && input_done=1 -> 실제 타이머 동작
            else if (input_done) begin
                // 이미 00:00:00 ?
                if (h_ten==0 && h_one==0 &&
                    m_ten==0 && m_one==0 &&
                    s_ten==0 && s_one==0) begin
                    timer_done <= 1; // 완료
                end
                else begin
                    // 1초마다 감소
                    if (h_cnt >= 999) begin
                        h_cnt <= 0;
                        // 초 내려가기
                        if (s_one == 0) begin
                            s_one <= 9;
                            if (s_ten == 0) begin
                                s_ten <= 5;
                                if (m_one == 0) begin
                                    m_one <= 9;
                                    if (m_ten == 0) begin
                                        m_ten <= 5;
                                        if (h_one == 0) begin
                                            // h_one이 0이면서 h_ten>0일 때
                                            h_ten <= (h_ten - 1);
                                            h_one <= 9;
                                        end else begin
                                            h_one <= (h_one - 1);
                                        end
                                    end else begin
                                        m_ten <= (m_ten - 1);
                                    end
                                end else begin
                                    m_one <= (m_one - 1);
                                end
                            end else begin
                                s_ten <= (s_ten - 1);
                            end
                        end else begin
                            s_one <= (s_one - 1);
                        end
                    end
                    else begin
                        h_cnt <= h_cnt + 1;
                    end
                end
            end

            // (C) LED 깜빡임 로직
            if (timer_done) begin
                // 이미 00:00:00 도달
                // 0.5초마다 토글 (1kHz -> 500카운트 = 약 0.5초)
                if (blink_cnt >= 16'd499) begin
                    blink_cnt <= 0;
                    led <= ~led;
                end else begin
                    blink_cnt <= blink_cnt + 1;
                end
            end else begin
                // 타이머 동작 중이면 LED 끔
                led <= 8'b0000_0000;
                blink_cnt <= 0;
            end
        end
    end

    //-----------------------------------
    // (3) keypad -> digit 변환 함수
    //-----------------------------------
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
            default:         keypad_to_digit = 4'd0;
        endcase
    endfunction

    //-----------------------------------
    // (4) 세그먼트 디코더(각 자릿수)
    //-----------------------------------
    wire [7:0] seg_h_ten, seg_h_one;
    wire [7:0] seg_m_ten, seg_m_one;
    wire [7:0] seg_s_ten, seg_s_one;

    // seg_decode는 미리 구현된 모듈이라 가정
    seg_decode u0(h_ten, seg_h_ten);
    seg_decode u1(h_one, seg_h_one);
    seg_decode u2(m_ten, seg_m_ten);
    seg_decode u3(m_one, seg_m_one);
    seg_decode u4(s_ten, seg_s_ten);
    seg_decode u5(s_one, seg_s_one);

    //-----------------------------------
    // (5) 세그먼트 분할 구동
    //-----------------------------------
    reg [2:0] s_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) s_cnt <= 0;
        else     s_cnt <= s_cnt + 1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_data <= 8'b0000_0000;
            seg_com  <= 8'b1111_1111;
        end else begin
            case(s_cnt)
                3'd0: begin seg_com <= 8'b0111_1111; seg_data <= 8'b0000_0000; end
                3'd1: begin seg_com <= 8'b1011_1111; seg_data <= 8'b0000_0000; end
                3'd2: begin seg_com <= 8'b1101_1111; seg_data <= seg_h_ten; end
                3'd3: begin seg_com <= 8'b1110_1111; seg_data <= seg_h_one; end
                3'd4: begin seg_com <= 8'b1111_0111; seg_data <= seg_m_ten; end
                3'd5: begin seg_com <= 8'b1111_1011; seg_data <= seg_m_one; end
                3'd6: begin seg_com <= 8'b1111_1101; seg_data <= seg_s_ten; end
                3'd7: begin seg_com <= 8'b1111_1110; seg_data <= seg_s_one; end
                default: begin
                    seg_com  <= 8'b1111_1111;
                    seg_data <= 8'b0000_0000;
                end
            endcase
        end
    end

endmodule