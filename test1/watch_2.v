module watch(
    input clk,              // 1kHz 클럭
    input rst,              // 리셋 신호
    input set_time,         // 시간 설정 모드 신호 (1: 설정 모드, 0: 동작 모드)
    input [3:0] keypad,     // 키패드 입력 (0~9)
    output reg [7:0] seg_data, // 세그먼트 데이터
    output reg [7:0] seg_com  // 세그먼트 선택 신호
);

    // 레지스터 선언
    reg [23:0] time_input;  // 키패드 입력 저장 (HHMMSS)
    reg [3:0] input_cnt;    // 키패드 입력 카운트
    reg set_complete;       // 설정 완료 플래그
    reg [9:0] clk_counter;  // 1Hz 클럭 생성용 카운터
    reg increment_time;     // 1Hz 신호 생성 플래그

    // 시간 저장 레지스터
    reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

    // 7세그먼트 디코딩용 wire
    wire [7:0] seg_digit [0:5];

    // 1Hz 클럭 생성 (1kHz 입력을 1Hz로 분주)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 0;
            increment_time <= 0;
        end else if (clk_counter >= 999) begin
            clk_counter <= 0;
            increment_time <= 1; // 1Hz 신호 발생
        end else begin
            clk_counter <= clk_counter + 1;
            increment_time <= 0;
        end
    end

    // 키패드 입력 처리 및 시간 설정
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            time_input <= 24'b0;
            input_cnt <= 0;
            set_complete <= 0;
        end else if (set_time) begin
            // 시간 설정 모드
            if (input_cnt < 6) begin
                if (keypad >= 0 && keypad <= 9) begin
                    time_input <= (time_input * 10) + keypad; // 숫자 입력 저장
                    input_cnt <= input_cnt + 1;
                end
            end else begin
                // 설정 완료
                h_ten <= time_input[23:20];
                h_one <= time_input[19:16];
                m_ten <= time_input[15:12];
                m_one <= time_input[11:8];
                s_ten <= time_input[7:4];
                s_one <= time_input[3:0];
                set_complete <= 1;
            end
        end else begin
            // 동작 모드로 전환 시 초기화
            input_cnt <= 0;
            set_complete <= 0;
        end
    end

    // 시간 증가 로직
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_ten <= 4'd0;
            h_one <= 4'd0;
            m_ten <= 4'd0;
            m_one <= 4'd0;
            s_ten <= 4'd0;
            s_one <= 4'd0;
        end else if (~set_time && increment_time) begin
            // 시간 증가 모드
            if (s_one == 9) begin
                s_one <= 0;
                if (s_ten == 5) begin
                    s_ten <= 0;
                    if (m_one == 9) begin
                        m_one <= 0;
                        if (m_ten == 5) begin
                            m_ten <= 0;
                            if (h_one == 9) begin
                                h_one <= 0;
                                if (h_ten == 2 && h_one == 3) begin
                                    h_ten <= 0; // 23:59:59 → 00:00:00
                                end else begin
                                    h_ten <= h_ten + 1;
                                end
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
        end
    end

    // 7세그먼트 디스플레이 로직 (6자리 출력)
    always @(posedge clk) begin
        // 디스플레이 제어
        seg_com <= 8'b1111_1111; // 기본값
        case (s_cnt)
            3'd0: seg_data <= seg_digit[5]; // HH 10자리
            3'd1: seg_data <= seg_digit[4]; // HH 1자리
            3'd2: seg_data <= seg_digit[3]; // MM 10자리
            3'd3: seg_data <= seg_digit[2]; // MM 1자리
            3'd4: seg_data <= seg_digit[1]; // SS 10자리
            3'd5: seg_data <= seg_digit[0]; // SS 1자리
        endcase
    end

    // 7세그먼트 디코딩
    seg_decode u0 (h_ten, seg_digit[5]);
    seg_decode u1 (h_one, seg_digit[4]);
    seg_decode u2 (m_ten, seg_digit[3]);
    seg_decode u3 (m_one, seg_digit[2]);
    seg_decode u4 (s_ten, seg_digit[1]);
    seg_decode u5 (s_one, seg_digit[0]);

endmodule
