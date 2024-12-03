module stopwatch(clk, rst, seg_data, seg_com, start);

input clk;  // 1kHz clock
input rst;
input start;
output [7:0] seg_data;

output [7:0] seg_com;
// output [3:0] seg_com;

reg prev_start;
reg [9:0] h_cnt;

reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;
// reg [3:0] m_ten, m_one, s_ten, s_one;


wire[7:0] seg_h_ten, seg_h_one;
wire[7:0] seg_m_ten, seg_m_one;
wire[7:0] seg_s_ten, seg_s_one;


reg[2:0] s_cnt;
// reg[1:2] s_cnt;

reg running = 0;

reg[7:0] seg_data;
reg[7:0] seg_com;

// watch count

always @(posedge clk or posedge rst)
begin
    if (rst) begin
        running <= 0;
        prev_start <= 0;
    end else begin
        if (start && !prev_start) begin
            running <= ~running;
        end
        prev_start <= start;
    end
end

always @(posedge rst or posedge clk)
    if (rst) h_cnt = 0;
    else if (h_cnt >=999) h_cnt = 0;
    else if (running == 1) h_cnt = h_cnt + 1;

always @(posedge rst or posedge clk)
    if (rst) s_one = 0;
    else if (h_cnt == 999)
        if (s_one >= 9) s_one = 0;
        else if (running == 1) s_one = s_one + 1;

always @(posedge rst or posedge clk)
    if (rst) s_ten = 0;
    else if (h_cnt == 999 && s_one == 9)
        if (s_ten >= 5) s_ten = 0;
        else if (running == 1)s_ten = s_ten + 1;

always @(posedge rst or posedge clk)
    if (rst) m_one = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5))
        if (m_one >= 9) m_one = 0;
        else if (running == 1)m_one = m_one + 1;

always @(posedge rst or posedge clk)
    if (rst) m_ten = 0;
    else if ((h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9))
        if (m_ten >= 5) m_ten = 0;
        else if (running == 1)m_ten = m_ten + 1;

always @(posedge rst or posedge clk)
    if (rst) h_one = 0;
    else if ((running == 1) && (h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9) && (m_ten == 5))
        if (h_one >= 9) h_one = 0;
        else h_one = h_one + 1;

always @(posedge rst or posedge clk)
    if (rst) h_ten = 0;
    else if ((running == 1) && (h_cnt == 999) && (s_one == 9) && (s_ten == 5) && (m_one == 9) && (m_ten == 5) && (h_one == 9)) begin
        if (h_ten >= 2 && h_one == 3) begin
            h_ten = 0;
            h_one = 0;
        end
        else h_ten = h_ten + 1;
    end
        

// data conversion
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// seg_decode u4 (m_ten, seg_m_ten);
// seg_decode u5 (m_one, seg_m_one);
// seg_decode u6 (s_ten, seg_s_ten);
// seg_decode u7 (s_one, seg_s_one);


// segment display part
always @(posedge clk)
    if (rst) s_cnt = 0;
    else s_cnt = s_cnt + 1;

always @(posedge clk)
    if (rst) seg_com = 8'b1111_1111;
    else
        case(s_cnt)
            3'd0 : seg_com = 8'b0111_1111; 
            3'd1 : seg_com = 8'b1011_1111;
            3'd2 : seg_com = 8'b1101_1111; 
            3'd3 : seg_com = 8'b1110_1111;
            3'd4 : seg_com = 8'b1111_0111;
            3'd5 : seg_com = 8'b1111_1011;
            3'd6 : seg_com = 8'b1111_1101; 
            3'd7 : seg_com = 8'b1111_1110;
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
            3'd6 : seg_data = 8'b0000_0000;
            3'd7 : seg_data = 8'b0000_0000;
        endcase

// always @(posedge clk)
//     if (rst) s_cnt = 0;
//     else s_cnt = s_cnt + 1;

// always @(posedge clk)
//     if (rst) seg_com = 8'b1111_1111;
//     else
//         case(s_cnt)
//             2'd0 : seg_com = 8'b1111_0111;
//             2'd1 : seg_com = 8'b1111_1011;
//             2'd2 : seg_com = 8'b1111_1101;
//             2'd3 : seg_com = 8'b1111_1110;
//         endcase

// always @(posedge clk)
//     if (rst) seg_data = 8'b0000_0000;
//     else
//         case(s_cnt)
//             2'd0 : seg_data = seg_m_ten;
//             2'd1 : seg_data = seg_m_one;
//             2'd2 : seg_data = seg_s_ten;
//             2'd3 : seg_data = seg_s_one;
//         endcase

endmodule