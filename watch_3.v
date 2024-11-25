module watch(clk, rst, mode_btn, keypad_input, keypad_valid, seg_data, seg_com);

input clk;                  // 1kHz clock
input rst;                  // Reset signal
input mode_btn;             // 모드 변경 버튼 입력
input [3:0] keypad_input;   // Keypad 입력 값 (0~9, *, #)
input keypad_valid;         // Keypad 입력 유효 신호
output reg [7:0] seg_data;  // 7-세그먼트 데이터 출력
output reg [7:0] seg_com;   // 7-세그먼트 선택 출력

// 공통적인 카운터 및 설정 데이터
reg [9:0] h_cnt;            // 1초 계산용 카운터
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one; // 시계 데이터
reg [3:0] sw_h_ten, sw_h_one, sw_m_ten, sw_m_one, sw_s_ten, sw_s_one; // 스톱워치 데이터
reg [3:0] temp_h_ten, temp_h_one, temp_m_ten, temp_m_one, temp_s_ten, temp_s_one; // 임시 시간 설정 데이터
reg [2:0] s_cnt;            // 7-세그먼트 선택 카운터
reg [2:0] set_position;     // 현재 시간 설정 중인 자리
reg [1:0] mode;             // Mode 설정 (00: 시계, 01: 스톱워치)
reg time_setting;           // 시간 설정 모드 플래그
reg sw_running;             // 스톱워치 작동 여부 플래그
reg mode_btn_last_state;    // 이전 모드 버튼 상태

// -----------------------
// 모드 변경 로직
// -----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        mode <= 2'b00; // 초기 모드는 시계 모드
        mode_btn_last_state <= 0; // 초기 모드 버튼 상태
    end else begin
        if (mode_btn && !mode_btn_last_state) begin
            // 버튼이 눌렸고, 이전에 눌리지 않은 상태였을 때 (떨어질 때가 아니라 눌릴 때만)
            mode <= mode + 1; // 모드 변경 (00 -> 01 -> 다시 00)
        end
        mode_btn_last_state <= mode_btn; // 버튼 상태 갱신
    end
end

// -----------------------
// 시간 설정 모드 로직
// -----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        time_setting <= 0;
        set_position <= 0;
        {h_ten, h_one, m_ten, m_one, s_ten, s_one} <= 24'b0;
        {temp_h_ten, temp_h_one, temp_m_ten, temp_m_one, temp_s_ten, temp_s_one} <= 24'b0;
    end else if (keypad_valid && mode == 2'b00) begin
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

// -----------------------
// 스톱워치 모드 입력 처리
// -----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sw_running <= 0;
        {sw_h_ten, sw_h_one, sw_m_ten, sw_m_one, sw_s_ten, sw_s_one} <= 24'b0;
    end else if (mode == 2'b01 && keypad_valid) begin
        if (keypad_input == 4'b1110) begin
            // `*` 키 입력 시 스톱워치 작동/정지
            sw_running <= ~sw_running;
        end else if (keypad_input == 4'b1111) begin
            // `#` 키 입력 시 스톱워치 초기화
            {sw_h_ten, sw_h_one, sw_m_ten, sw_m_one, sw_s_ten, sw_s_one} <= 24'b0;
            sw_running <= 0;
        end
    end
end

// -----------------------
// 공통 1초 카운터
// -----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 0;
    end else if (h_cnt >= 999) begin
        h_cnt <= 0;
    end else begin
        h_cnt <= h_cnt + 1;
    end
end

// -----------------------
// 초의 1의 자리 증가 - 시계/스톱워치 모드 분리
// -----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_one <= 0;
        sw_s_one <= 0;
    end else if (h_cnt == 999) begin
        if (mode == 2'b00 && !time_setting) begin
            // 시계 모드
            if (s_one >= 9) s_one <= 0;
            else s_one <= s_one + 1;
        end else if (mode == 2'b01 && sw_running) begin
            // 스톱워치 모드
            if (sw_s_one >= 9) sw_s_one <= 0;
            else sw_s_one <= sw_s_one + 1;
        end
    end
end

// -----------------------
// 초의 10의 자리 증가 - 시계/스톱워치 모드 분리
// -----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_ten <= 0;
        sw_s_ten <= 0;
    end else if (h_cnt == 999 && s_one == 9) begin
        if (mode == 2'b00 && !time_setting) begin
            // 시계 모드
            if (s_ten >= 5) s_ten <= 0;
            else s_ten <= s_ten + 1;
        end else if (mode == 2'b01 && sw_running) begin
            // 스톱워치 모드
            if (sw_s_ten >= 5) sw_s_ten <= 0;
            else sw_s_ten <= sw_s_ten + 1;
        end
    end
end

// ... 이하 동일한 방식으로 각 자리별 증가 구현 (분, 시)

// -----------------------
// 7-세그먼트 디스플레이 출력
// -----------------------
always @(posedge clk) begin
    case (s_cnt)
        3'd0: seg_com = 8'b0111_1111;
        3'd1: seg_com = 8'b1011_1111;
        3'd2: seg_com = 8'b1101_1111;
        3'd3: seg_com = 8'b1110_1111;
        3'd4: seg_com = 8'b1111_0111;
        3'd5: seg_com = 8'b1111_1011;
        default: seg_com = 8'b1111_1111;
    endcase

    if (mode == 2'b00) begin
        // 시계 모드
        case (s_cnt)
            3'd0: seg_data = h_ten;
            3'd1: seg_data = h_one;
            3'd2: seg_data = m_ten;
            3'd3: seg_data = m_one;
            3'd4: seg_data = s_ten;
            3'd5: seg_data = s_one;
            default: seg_data = 8'b0000_0000;
        endcase
    end else if (mode == 2'b01) begin
        // 스톱워치 모드
        case (s_cnt)
            3'd0: seg_data = sw_h_ten;
            3'd1: seg_data = sw_h_one;
            3'd2: seg_data = sw_m_ten;
            3'd3: seg_data = sw_m_one;
            3'd4: seg_data = sw_s_ten;
            3'd5: seg_data = sw_s_one;
            default: seg_data = 8'b0000_0000;
        endcase
    end
end

endmodule
