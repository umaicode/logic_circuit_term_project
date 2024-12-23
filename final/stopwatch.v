module stopwatch(
    input clk,
    input rst,
    input start,
    output reg [7:0] seg_data,
    output reg [7:0] seg_com
);
    //============================= input, register, wire 선언 =============================
    // 1ms counter
    reg [9:0] h_cnt;

    // 시/분/초 레지스터
    reg [3:0] h_ten, h_one;  // 시
    reg [3:0] m_ten, m_one;  // 분
    reg [3:0] s_ten, s_one;  // 초

    // 밀리초 레지스터 (세 자리)
    reg [3:0] ms_hun;        // 100의 자리 (0~9)
    reg [3:0] ms_ten;        // 10의 자리  (0~9)
    reg [3:0] ms_one;        // 1의 자리   (0~9)

    // 7세그먼트 디코더 출력
    wire [7:0] seg_h_ten, seg_h_one;
    wire [7:0] seg_m_ten, seg_m_one;
    wire [7:0] seg_s_ten, seg_s_one;
    wire [7:0] seg_ms_hun, seg_ms_ten, seg_ms_one;

    // 스톱워치 동작 상태/토글
    reg running;
    reg prev_start;

    // 분할구동용 s_cnt (3비트 → 8자리)
    reg [2:0] s_cnt;
    //============================= input, register, wire 선언 =============================


    //============================== 스톱워치 로직 ==============================
    //--------------------------------------------------------------------------
    // (1) Start/Stop 버튼 로직
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running <= 0;
            prev_start <= 0;
        end else begin
            if (start && !prev_start) begin
                running <= ~running; // 버튼 에지 시 토글
            end
            prev_start <= start;
        end
    end

    //--------------------------------------------------------------------------
    // (2) 1ms counter + 시/분/초/밀리초 증가 로직
    //     -> 1MHz 클록이므로, h_cnt가 999 되면 1ms가 지났다고 간주
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_cnt <= 0;
            // 밀리초 초기화
            ms_hun <= 0; 
            ms_ten <= 0; 
            ms_one <= 0;
            // 시분초 초기화
            s_one <= 0; s_ten <= 0;
            m_one <= 0; m_ten <= 0;
            h_one <= 0; h_ten <= 0;
        end 
        else if (h_cnt >= 999) begin
            // h_cnt=999 => 1 ms 구현
            h_cnt <= 0;

            if (running) begin
                // (1) ms_one 증가
                if (ms_one >= 9) begin
                    ms_one <= 0;
                    // (2) ms_ten 증가
                    if (ms_ten >= 9) begin
                        ms_ten <= 0;
                        // (3) ms_hun 증가
                        if (ms_hun >= 9) begin
                            // 999 -> 000
                            ms_hun <= 0;

                            // 초(s_one) 증가
                            if (s_one >= 9) begin
                                s_one <= 0;
                                if (s_ten >= 5) begin
                                    s_ten <= 0;
                                    // 분(m_one) 증가
                                    if (m_one >= 9) begin
                                        m_one <= 0;
                                        if (m_ten >= 5) begin
                                            m_ten <= 0;
                                            // 시(h_one) 증가
                                            if (h_one >= 9) begin
                                                h_one <= 0;
                                                if (h_ten >= 9) begin
                                                    h_ten <= 0;                 // 00:00:00.000 리셋
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
                        end else begin
                            ms_hun <= ms_hun + 1;
                        end
                    end else begin
                        ms_ten <= ms_ten + 1;
                    end
                end else begin
                    ms_one <= ms_one + 1;
                end
            end
        end 
        else begin
            h_cnt <= h_cnt + 1;
        end
    end
    //============================== 스톱워치 로직 ==============================


    //============================== 7-segment 디코딩 ==============================
    //--------------------------------------------------------------------------
    // (3) 세그먼트 디코더
    //     -> ms_hun, ms_ten, ms_one까지 3개 디코더 추가
    //--------------------------------------------------------------------------
    seg_decode u0 (h_ten,    seg_h_ten);
    seg_decode u1 (h_one,    seg_h_one);
    seg_decode u2 (m_ten,    seg_m_ten);
    seg_decode u3 (m_one,    seg_m_one);
    seg_decode u4 (s_ten,    seg_s_ten);
    seg_decode u5 (s_one,    seg_s_one);
    seg_decode u6 (ms_hun,   seg_ms_hun);
    seg_decode u7 (ms_ten,   seg_ms_ten);
    seg_decode u8 (ms_one,   seg_ms_one); 
    // 실제론 9개이지만, 8개만 쓸 수도 있음(여기서는 ms_one 디코더도 있긴 하지만 사용 안 함)
    //============================== 7-segment 디코딩 ==============================


    //============================== 7-segment 출력 ==============================
    //--------------------------------------------------------------------------
    // (4) 분할 구동(8자리 FND)
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) s_cnt <= 0;
        else     s_cnt <= s_cnt + 1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_com  <= 8'b1111_1111;
            seg_data <= 8'b0000_0000;
        end else begin
            case(s_cnt)
                // 0~5 : HH:MM:SS (6자리), 6 : ms_hun (100의 자리), 7 : ms_ten (10의 자리)
                3'd0: begin seg_com <= 8'b0111_1111; seg_data <= seg_h_ten; end
                3'd1: begin seg_com <= 8'b1011_1111; seg_data <= seg_h_one; end
                3'd2: begin seg_com <= 8'b1101_1111; seg_data <= seg_m_ten; end
                3'd3: begin seg_com <= 8'b1110_1111; seg_data <= seg_m_one; end
                3'd4: begin seg_com <= 8'b1111_0111; seg_data <= seg_s_ten; end
                3'd5: begin seg_com <= 8'b1111_1011; seg_data <= seg_s_one; end
                3'd6: begin seg_com <= 8'b1111_1101; seg_data <= seg_ms_hun; end
                3'd7: begin seg_com <= 8'b1111_1110; seg_data <= seg_ms_ten; end
                default: begin seg_com  <= 8'b1111_1111; seg_data <= 8'b0000_0000; end
            endcase
        end
    end
    //============================== 7-segment 출력 ==============================


endmodule