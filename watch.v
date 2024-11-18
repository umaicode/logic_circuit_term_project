module watch(clk, rst, seg_data, seg_com);

input clk;  // 1kHz clock
input rst;
output [7:0] seg_data;
output [3:0] seg_com;

reg [9:0] h_cnt;
reg [3:0] m_ten, m_one, s_ten, s_one;

wire[7:0] seg_m_ten, seg_m_one;
wire[7:0] seg_s_ten, seg_s_one;

reg[1:2] s_cnt;
reg[7:0] seg_data;
reg[3:0] seg_com;



// watch count

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

// data conversion

seg_decode u4 (m_ten, seg_m_ten);
seg_decode u5 (m_one, seg_m_one);
seg_decode u6 (s_ten, seg_s_ten);
seg_decode u7 (s_one, seg_s_one);


// segment display part

always @(posedge clk)
    if (rst) s_cnt = 0;
    else s_cnt = s_cnt + 1;

always @(posedge clk)
    if (rst) seg_com = 8'b1111_1111;
    else
        case(s_cnt)
            2'd0 : seg_com = 8'b1111_0111;
            2'd1 : seg_com = 8'b1111_1011;
            2'd2 : seg_com = 8'b1111_1101;
            2'd3 : seg_com = 8'b1111_1110;
        endcase

always @(posedge clk)
    if (rst) seg_data = 8'b0000_0000;
    else
        case(s_cnt)
            2'd0 : seg_data = seg_m_ten;
            2'd1 : seg_data = seg_m_one;
            2'd2 : seg_data = seg_s_ten;
            2'd3 : seg_data = seg_s_one;
        endcase

endmodule