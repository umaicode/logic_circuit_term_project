module watch(clk, rst, seg_data, seg_com);

input clk;  // 1kHz clock
input rst;
output [7:0] seg_data;
// TODO : 시간 출력을 위한 output 추가 선언
output [7:0] seg_com;
// output [3:0] seg_com;

reg [9:0] h_cnt;
// TODO : 시간 출력을 위한 reg 추가 선언
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;
// reg [3:0] m_ten, m_one, s_ten, s_one;

// TODO : 시간 출력을 위한 wire 추가 선언
wire[7:0] seg_h_ten, seg_h_one;
wire[7:0] seg_m_ten, seg_m_one;
wire[7:0] seg_s_ten, seg_s_one;

// TODO : 시간 출력을 위한 3비트 카운터 -> 기존 분, 초는 4자리 세그먼트만 선택하므로 2비트로 충분.
reg[2:0] s_cnt;
// reg[1:2] s_cnt;


reg[7:0] seg_data;
reg[7:0] seg_com;
// gpt 추천 코드 : 위의 reg 없애고 5-7번째 줄에 아래와 같이 추가
// output reg [7:0] seg_data;
// output reg [7:0] seg_com;



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

        

// data conversion
// TODO : 시간 출력을 위한 seg_decode 추가
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