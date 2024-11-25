module watch(clk, rst, keypad_input, keypad_valid, seg_data, seg_com);

input clk;                  // 1kHz clock
input rst;                  // Reset signal
input [3:0] keypad_input;   // Keypad 입력 값 (0~9, *, #)
input keypad_valid;         // Keypad 입력 유효 신호
output reg [7:0] seg_data;  // 7-세그먼트 데이터 출력
output reg [7:0] seg_com;   // 7-세그먼트 선택 출력

reg [9:0] h_cnt;            // 1초 계산용 카운터
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one; // 시간 데이터
reg [3:0] temp_h_ten, temp_h_one, temp_m_ten, temp_m_one, temp_s_ten, temp_s_one; // 임시 시간 설정 데이터
reg [2:0] s_cnt;            // 7-세그먼트 선택 카운터
reg [2:0] set_position;     // 현재 시간 설정 중인 자리 (0: 시10, 1: 시1, ...)
reg time_setting;           // 시간 설정 모드 플래그

wire [7:0] seg_h_ten, seg_h_one, seg_m_ten, seg_m_one, seg_s_ten, seg_s_one; // 디코딩된 7-세그먼트 값

// 시간 설정 모드 로직
always @(posedge clk or posedge rst) begin
    if (rst) begin
        time_setting <= 0; // 시간 설정 모드 비활성화
        set_position <= 0;
        {h_ten, h_one, m_ten, m_one, s_ten, s_one} <= 24'b0;
        {temp_h_ten, temp_h_one, temp_m_ten, temp_m_one, temp_s_ten, temp_s_one} <= 24'b0;
    end else if (keypad_valid) begin
        if (!time_setting && keypad_input == 4'b1110) begin
            // `*` 키 입력 시 시간 설정 모드 진입
            time_setting <= 1;
            set_position <= 0; // 시의 10의 자리부터 시작
        end else if (time_setting) begin
            case (set_position)
                3'd0: temp_h_ten <= keypad_input; // 시의 10의 자리
                3'd1: temp_h_one <= keypad_input; // 시의 1의 자리
                3'd2: temp_m_ten <= keypad_input; // 분의 10의 자리
                3'd3: temp_m_one <= keypad_input; // 분의 1의 자리
                3'd4: temp_s_ten <= keypad_input; // 초의 10의 자리
                3'd5: temp_s_one <= keypad_input; // 초의 1의 자리
            endcase

            if (set_position < 5) begin
                set_position <= set_position + 1; // 다음 자리로 이동
            end else if (keypad_input == 4'b1111) begin
                // `#` 키 입력 시 시간 설정 완료
                time_setting <= 0; // 시간 설정 모드 종료
                {h_ten, h_one, m_ten, m_one, s_ten, s_one} <= 
                {temp_h_ten, temp_h_one, temp_m_ten, temp_m_one, temp_s_ten, temp_s_one};
            end
        end
    end
end

// h_cnt 카운터 (1초마다 증가)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 0;
    end else if (!time_setting) begin
        if (h_cnt >= 999) begin
            h_cnt <= 0;
        end else begin
            h_cnt <= h_cnt + 1;
        end
    end
end

// 초의 1의 자리 (s_one)
always @(posedge rst or posedge clk) begin
    if (rst) s_one <= 0;
    else if (!time_setting && h_cnt == 999) begin
        if (s_one >= 9) s_one <= 0;
        else s_one <= s_one + 1;
    end
end

// 초의 10의 자리 (s_ten)
always @(posedge rst or posedge clk) begin
    if (rst) s_ten <= 0;
    else if (!time_setting && h_cnt == 999 && s_one == 9) begin
        if (s_ten >= 5) s_ten <= 0;
        else s_ten <= s_ten + 1;
    end
end

// 분의 1의 자리 (m_one)
always @(posedge rst or posedge clk) begin
    if (rst) m_one <= 0;
    else if (!time_setting && h_cnt == 999 && s_one == 9 && s_ten == 5) begin
        if (m_one >= 9) m_one <= 0;
        else m_one <= m_one + 1;
    end
end

// 분의 10의 자리 (m_ten)
always @(posedge rst or posedge clk) begin
    if (rst) m_ten <= 0;
    else if (!time_setting && h_cnt == 999 && s_one == 9 && s_ten == 5 && m_one == 9) begin
        if (m_ten >= 5) m_ten <= 0;
        else m_ten <= m_ten + 1;
    end
end

// 시의 1의 자리 (h_one)
always @(posedge rst or posedge clk) begin
    if (rst) h_one <= 0;
    else if (!time_setting && h_cnt == 999 && s_one == 9 && s_ten == 5 && m_one == 9 && m_ten == 5) begin
        if (h_one >= 9) h_one <= 0;
        else h_one <= h_one + 1;
    end
end

// 시의 10의 자리 (h_ten)
always @(posedge rst or posedge clk) begin
    if (rst) h_ten <= 0;
    else if (!time_setting && h_cnt == 999 && s_one == 9 && s_ten == 5 && m_one == 9 && m_ten == 5 && h_one == 9) begin
        if (h_ten == 2 && h_one == 3) h_ten <= 0; // 23시에서 00시로 초기화
        else h_ten <= h_ten + 1;
    end
end

// 7-세그먼트 디스플레이
always @(posedge clk) begin
    case (s_cnt)
        3'd0: begin seg_com = 8'b0111_1111; seg_data = seg_h_ten; end
        3'd1: begin seg_com = 8'b1011_1111; seg_data = seg_h_one; end
        3'd2: begin seg_com = 8'b1101_1111; seg_data = seg_m_ten; end
        3'd3: begin seg_com = 8'b1110_1111; seg_data = seg_m_one; end
        3'd4: begin seg_com = 8'b1111_0111; seg_data = seg_s_ten; end
        3'd5: begin seg_com = 8'b1111_1011; seg_data = seg_s_one; end
        default: begin seg_com = 8'b1111_1111; seg_data = 8'b0000_0000; end
    endcase
end

endmodule
