module watch(clk, rst, seg_data, seg_com);

input clk;  // 1kHz clock (1ms 주기)
input rst;
output reg [7:0] seg_data;
output reg [7:0] seg_com;

// 카운터 선언
reg [9:0] h_cnt;        // 1ms 카운터 (0~999)
reg [3:0] h_ten, h_one; // 시의 10자리와 1자리
reg [3:0] m_ten, m_one; // 분의 10자리와 1자리
reg [3:0] s_ten, s_one; // 초의 10자리와 1자리
reg [3:0] ms_ten, ms_one; // 1/100초의 10자리와 1자리

// 세그먼트 디코딩을 위한 wire
wire [7:0] seg_h_ten, seg_h_one;
wire [7:0] seg_m_ten, seg_m_one;
wire [7:0] seg_s_ten, seg_s_one;
wire [7:0] seg_ms_ten, seg_ms_one;

// 세그먼트 선택을 위한 카운터
reg [2:0] s_cnt;

// 1ms 카운터
always @(posedge rst or posedge clk)
    if (rst) h_cnt <= 0;
    else if (h_cnt >= 999) h_cnt <= 0;
    else h_cnt <= h_cnt + 1;

// 1/100초 카운터
always @(posedge rst or posedge clk)
    if (rst) begin
        ms_one <= 0;
        ms_ten <= 0;
    end else if (h_cnt == 999) begin
        if (ms_one >= 9) begin
            ms_one <= 0;
            if (ms_ten >= 9) begin
                ms_ten <= 0;
            end else begin
                ms_ten <= ms_ten + 1;
            end
        end else begin
            ms_one <= ms_one + 1;
        end
    end

// 초 카운터
always @(posedge rst or posedge clk)
    if (rst) begin
        s_one <= 0;
        s_ten <= 0;
    end else if (h_cnt == 999 && ms_one == 9 && ms_ten == 9) begin
        if (s_one >= 9) begin
            s_one <= 0;
            if (s_ten >= 5) s_ten <= 0;
            else s_ten <= s_ten + 1;
        end else begin
            s_one <= s_one + 1;
        end
    end

// 분 카운터
always @(posedge rst or posedge clk)
    if (rst) begin
        m_one <= 0;
        m_ten <= 0;
    end else if (h_cnt == 999 && ms_one == 9 && ms_ten == 9 && s_one == 9 && s_ten == 5) begin
        if (m_one >= 9) begin
            m_one <= 0;
            if (m_ten >= 5) m_ten <= 0;
            else m_ten <= m_ten + 1;
        end else begin
            m_one <= m_one + 1;
        end
    end

// 시 카운터
always @(posedge rst or posedge clk)
    if (rst) begin
        h_one <= 0;
        h_ten <= 0;
    end else if (h_cnt == 999 && ms_one == 9 && ms_ten == 9 && s_one == 9 && s_ten == 5 && m_one == 9 && m_ten == 5) begin
        if (h_ten == 2 && h_one == 3) begin
            h_ten <= 0;
            h_one <= 0;
        end else if (h_one >= 9) begin
            h_one <= 0;
            h_ten <= h_ten + 1;
        end else begin
            h_one <= h_one + 1;
        end
    end

// 세그먼트 디코더 인스턴스
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);
seg_decode u6 (ms_ten, seg_ms_ten);
seg_decode u7 (ms_one, seg_ms_one);

// 세그먼트 선택을 위한 카운터
always @(posedge clk)
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;

// 세그먼트 선택 및 데이터 출력
always @(posedge clk)
    if (rst) begin
        seg_com <= 8'b1111_1111;
        seg_data <= 8'b0000_0000;
    end else begin
        case (s_cnt)
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= seg_h_ten; end // 시의 10자리
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= seg_h_one; end // 시의 1자리
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= seg_m_ten; end // 분의 10자리
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= seg_m_one; end // 분의 1자리
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= seg_s_ten; end // 초의 10자리
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= seg_s_one; end // 초의 1자리
            3'd6: begin seg_com <= 8'b1111_1101; seg_data <= seg_ms_ten; end // 1/100초의 10자리
            3'd7: begin seg_com <= 8'b1111_1110; seg_data <= seg_ms_one; end // 1/100초의 1자리
        endcase
    end

endmodule
