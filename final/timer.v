module timer(
    input clk,                // 1kHz clock
    input rst,                // 리셋
    input dip_sw_timer,       // DIP switch 입력 (타이머 세팅 모드(1) / 동작 모드(0))
    input [9:0] keypad,       // 키패드 입력 (0 ~ 9)

    output reg [7:0] seg_data,// 7-Segment 디스플레이 데이터 출력
    output reg [7:0] seg_com, // 7-Segment 디스플레이 공통 출력
    output reg [7:0] led,     // LED 제어 신호 (8비트)

    // 타이머가 00:00:00 도달 시 → top_module로 보내서 Piezo나 다른 로직 트리거
    output wire timer_done_out
);


    //============================= input, register, wire 선언 =============================
    reg [3:0] h_ten, h_one;  // 시(00~99)
    reg [3:0] m_ten, m_one;  // 분(00~59)
    reg [3:0] s_ten, s_one;  // 초(00~59)

    reg [2:0] input_cnt;     
    reg [9:0] keypad_prev;
    reg input_done;          

    reg [9:0] h_cnt;         // 1ms마다 카운트 -> 1000이면 1초
    reg timer_done;          // 00:00:00 도달 시=1 (내부 레지스터)

    // LED 깜빡임 관련
    reg [15:0] blink_cnt;        // LED 토글 주기(0.5초)
    reg [3:0]  led_toggle_count; // LED 토글 횟수 (최대 10회)

    // timer_done을 top_module로
    assign timer_done_out = timer_done;
    //============================= input, register, wire 선언 =============================


    //============================== 키패드 입력 처리, 시간 설정, 타이머 동작 로직 구현 ==============================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            input_cnt  <= 0;
            input_done <= 0;
            timer_done <= 0;
            h_cnt      <= 0;
            h_ten <= 0; h_one <= 0;
            m_ten <= 0; m_one <= 0;
            s_ten <= 0; s_one <= 0;

            keypad_prev <= 10'b0000000000;
            led         <= 8'b00000000;
            blink_cnt   <= 0;
            led_toggle_count <= 0;
        end 
        else begin
            // 키패드 상태 갱신
            keypad_prev <= keypad;
            if (dip_sw_timer) begin
                //-------------------------------- 타이머 설정 모드 --------------------------------
                timer_done <= 0;
                h_cnt <= 0;

                // LED 관련도 초기화
                led <= 8'b00000000;
                blink_cnt <= 0;
                led_toggle_count <= 0;

                // 키패드 입력
                if (keypad != 0 && keypad_prev == 0) begin
                    case (input_cnt)
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

                    //------------------------------ 입력 단계 카운터 증가 로직 ------------------------------
                    if (input_cnt < 5) input_cnt <= input_cnt + 1;
                    else input_cnt <= 0;
                end
            end 

            else if (input_done) begin
                //------------------------------ 타이머 동작 로직 구현 ------------------------------
                // 00:00:00 -> timer_done = 1
                if (h_ten==0 && h_one==0 &&
                    m_ten==0 && m_one==0 &&
                    s_ten==0 && s_one==0) begin
                    timer_done <= 1;
                end 
                else begin
                    // 1초마다 감소
                    if (h_cnt >= 999) begin
                        h_cnt <= 0;
                        // 초 감소 로직 구현
                        if (s_one == 0) begin
                            s_one <= 9;
                            if (s_ten == 0) begin
                                s_ten <= 5;
                                if (m_one == 0) begin
                                    m_one <= 9;
                                    if (m_ten == 0) begin
                                        m_ten <= 5;
                                        if (h_one == 0) begin
                                            h_ten <= h_ten - 1;
                                            h_one <= 9;
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
                        h_cnt <= h_cnt + 1;
                    end
                end
            end


            //============================== 타이머 종료 후 LED 로직 구현 ==============================
            if (timer_done) begin
                // 만약 led_toggle_count < 10회(토글)라면 깜빡임 진행
                // 토글은 5회 빛나는 것으로 설정
                if (led_toggle_count < 10) begin
                    if (blink_cnt >= 16'd499) begin
                        blink_cnt <= 0;
                        led <= ~led;
                        led_toggle_count <= led_toggle_count + 1;
                    end else begin
                        blink_cnt <= blink_cnt + 1;
                    end
                end
                else begin
                    // 10번 모두 깜빡이면 LED 끔
                    led <= 8'b00000000;
                end
            end 
            else begin
                // 동작 중이면 LED 끔, 카운터 리셋
                led <= 8'b00000000;
                blink_cnt <= 0;
                led_toggle_count <= 0;
            end
            //============================== 타이머 종료 후 LED 로직 구현 ==============================


        end
    end
    //============================== 키패드 입력 처리, 시간 설정, 타이머 동작 로직 구현 ==============================


    //============================== 키패드 입력을 숫자로 변환하는 함수 ==============================
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
    //============================== 키패드 입력을 숫자로 변환하는 함수 ==============================


    //============================== 7-segment 디코딩 ==============================
    wire [7:0] seg_h_ten, seg_h_one;
    wire [7:0] seg_m_ten, seg_m_one;
    wire [7:0] seg_s_ten, seg_s_one;

    seg_decode u0(h_ten, seg_h_ten);
    seg_decode u1(h_one, seg_h_one);
    seg_decode u2(m_ten, seg_m_ten);
    seg_decode u3(m_one, seg_m_one);
    seg_decode u4(s_ten, seg_s_ten);
    seg_decode u5(s_one, seg_s_one);
    //============================== 7-segment 디코딩 ==============================

    //============================== 7-segment 출력 ==============================
    reg [2:0] s_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) 
            s_cnt <= 0;
        else     
            s_cnt <= s_cnt + 1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_data <= 8'b00000000;
            seg_com  <= 8'b11111111;
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
                default: begin seg_com  <= 8'b11111111; seg_data <= 8'b00000000; end
            endcase
        end
    end
    //============================== 7-segment 출력 ==============================


endmodule
