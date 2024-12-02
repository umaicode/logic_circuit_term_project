module watch(
    input clk,   // 1kHz clock
    input rst,   // Reset signal
    input mode_btn, // 모드 변경 버튼 입력
    input setting_btn, // 시간 설정 버튼 입력
    input [9:0] keypad_input, // Keypad 입력 값 (0~9)
    output [7:0] seg_data, // 7-세그먼트 데이터
    output [7:0] seg_com,  // 7-세그먼트 자리 선택
    output lcd_e, lcd_rs, lcd_rw, // LCD 제어 신호
    output [7:0] lcd_data  // LCD 데이터
);

// -------------------- 모드 관리 --------------------
reg [1:0] mode; // 2비트 모드: 00=WATCH, 01=ALARM, 10=STOPWATCH, 11=SETTING
reg mode_btn_prev;
reg setting_btn_prev;
reg [3:0] step; // 설정 단계 : 0=시(10), 1=시(1)... 5=초(1)

// 기존 시계 기능 (seg_data 및 seg_com 생성)
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// TODO : 시간 출력을 위한 wire 추가 선언
wire[7:0] seg_h_ten, seg_h_one;
wire[7:0] seg_m_ten, seg_m_one;
wire[7:0] seg_s_ten, seg_s_one;

// TODO : 시간 출력을 위한 3비트 카운터 -> 기존 분, 초는 4자리 세그먼트만 선택하므로 2비트로 충분.
reg[2:0] s_cnt;

reg[7:0] seg_data;
reg[7:0] seg_com;

// -------------------- 모드 변경 로직 --------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        mode <= 2'b00; // 초기값: WATCH
        mode_btn_prev <= 1'b0;
        setting_btn_prev <= 1'b0;
        step <= 0;
    end else begin
        // 모드 변경 버튼 처리
        if (mode_btn && !mode_btn_prev) begin // 버튼의 상승 엣지 감지
            mode <= mode + 1'b1;
            if (mode == 2'b10) // STOPWATCH 다음은 WATCH로 순환
                mode <= 2'b00;
        end

        // 설정 버튼 처리
        if (setting_btn && !setting_btn_prev) begin
            mode <= 2'b11;  // SETTING 모드로 변경
            step <= 0; // 설정 초기화
        end

        mode_btn_prev <= mode_btn;
        setting_btn_prev <= setting_btn;
    end
end

// -------------------- watch count --------------------
always @(posedge rst or posedge clk)
    if (rst) h_cnt = 0;
    else if (h_cnt >=999) h_cnt = 0;
    else h_cnt = h_cnt + 1;

always @(posedge rst or posedge clk)
    if (rst) s_one = 0;
    else if (h_cnt == 999)
        if (s_one >= 9) s_one = 0;
        else s_one = s_one + 1;

always @(posedge rst or posedge clk)
    if (rst) s_ten = 0;
    else if (h_cnt == 999 && s_one == 9)
        if (s_ten >= 5) s_ten = 0;
        else s_ten = s_ten + 1;

always @(posedge rst or posedge clk)
    if (rst) m_one = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5))
        if (m_one >= 9) m_one = 0;
        else m_one = m_one + 1;

always @(posedge rst or posedge clk)
    if (rst) m_ten = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9))
        if (m_ten >= 5) m_ten = 0;
        else m_ten = m_ten + 1;

// TODO : 시간 출력을 위한 카운터 추가
always @(posedge rst or posedge clk)
    if (rst) h_ten = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9) && (m_ten == 5)) begin
        if (h_ten == 2 && h_one == 3) begin
            // "23:59:59 → 00:00:00" 처리
            h_ten = 0;
            h_one = 0;
        end else if (h_one == 9) begin
            // h_one이 9일 때 h_ten 증가
            h_one = 0;
            h_ten = h_ten + 1;
        end else begin
            // 일반적인 h_one 증가
            h_one = h_one + 1;
        end
    end

// -------------------- 설정 모드 처리 --------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_ten <= 0;
        h_one <= 0;
        m_ten <= 0;
        m_one <= 0;
        s_ten <= 0;
        s_one <= 0;
        step <= 0;
    end else if (mode = 2'b11) begin
        case (step)
            0: if (keypad_input <= 4'd2) begin h_ten <= keypad_input; step <= step + 1; end
            1: if ((h_ten < 4'd2 && keypad_input <= 4'd9) || (h_ten == 4'd2 && keypad_input <= 4'd3)) begin h_one <= keypad_input; step <= step + 1; end
            2: if (keypad_input <= 4'd5) begin m_ten <= keypad_input; step <= step + 1; end
            3: if (keypad_input <= 4'd9) begin m_one <= keypad_input; step <= step + 1; end
            4: if (keypad_input <= 4'd5) begin s_ten <= keypad_input; step <= step + 1; end
            5: if (keypad_input <= 4'd9) begin s_one <= keypad_input; mode <= 2'b00; end // 설정 완료 후 WATCH 모드로 전환
        endcase
    end
end

// -------------------- data conversion --------------------
// TODO : 시간 출력을 위한 seg_decode 추가
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// -------------------- segment display part --------------------
// TODO : 시간 출력을 위한 세그먼트 선택 추가
always @(posedge clk)
    if (rst) s_cnt = 0;
    else s_cnt = s_cnt + 1;

always @(posedge clk)
    if (rst) seg_com = 8'b1111_1111;
    else
        case(s_cnt)
            3'd0 : seg_com = 8'b0111_1111; // 시의 10의 자리
            3'd1 : seg_com = 8'b1011_1111; // 시의 1의 자리
            3'd2 : seg_com = 8'b1101_1111; // 분의 10의 자리
            3'd3 : seg_com = 8'b1110_1111; // 분의 1의 자리
            3'd4 : seg_com = 8'b1111_0111; // 초의 10의 자리
            3'd5 : seg_com = 8'b1111_1011; // 초의 1의 자리
            3'd6 : seg_com = 8'b1111_1101; // 비활성화
            3'd7 : seg_com = 8'b1111_1110; // 비활성화
        endcase

always @(posedge clk)
    if (rst) seg_data = 8'b0000_0000;
    else
        case(s_cnt)
            3'd0 : seg_data = seg_h_ten;
            3'd1 : seg_data = seg_h_one;
            3'd2 : seg_data = seg_m_ten;
            3'd3 : seg_data = seg_m_one;
            3'd4 : seg_data = seg_s_ten;
            3'd5 : seg_data = seg_s_one;
            3'd6 : seg_data = 8'b0000_0000; // 비활성화
            3'd7 : seg_data = 8'b0000_0000; // 비활성화
        endcase

// -------------------- LCD 출력 --------------------
textlcd u_textlcd (
    .rst(rst),
    .clk(clk),
    .mode(mode), // 현재 모드 전달
    .lcd_e(lcd_e),
    .lcd_rs(lcd_rs),
    .lcd_rw(lcd_rw),
    .lcd_data(lcd_data)
);

endmodule
