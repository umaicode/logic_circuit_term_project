module watch(clk, rst, dip_sw, keypad, seg_data, seg_com);

input clk;            // 1kHz clock
input rst;            // 由ъ뀑 떊 샇
input dip_sw;         // DIP 뒪 쐞移 엯 젰 (1: 꽕 젙 紐⑤뱶, 0: 떆怨 紐⑤뱶)
input [9:0] keypad;   // 궎 뙣 뱶 엯 젰 (0~9)

output reg [7:0] seg_data;
output reg [7:0] seg_com;

// 떆媛 移댁슫 꽣
reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one;

// 꽭洹몃㉫ 듃 뵒肄붾뵫 쓣 쐞 븳 wire
wire [7:0] seg_h_ten, seg_h_one;
wire [7:0] seg_m_ten, seg_m_one;
wire [7:0] seg_s_ten, seg_s_one;

// 엯 젰 愿 젴 긽 깭
reg [2:0] input_cnt;       // 0遺 꽣 5源뚯 쓽 엯 젰 移댁슫 꽣
reg [9:0] h_cnt;           // 1珥 移댁슫 꽣
reg input_done;            // 엯 젰 셿猷 뵆 옒洹

// 궎 뙣 뱶 엯 젰 뵒肄붾뵫 諛 떆媛 꽕 젙
reg [9:0] keypad_prev;

// ------------------------------ 븣 엺 뿰寃 --------------------------------------

//--------------------------- 뼹 엺 뿰寃 done ---------------------------------

// -----------------------------
// 궎 뙣 뱶 엯 젰 諛 떆媛 꽕 젙, 떆怨 移댁슫 꽣 넻 빀
// -----------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_cnt <= 0;
        input_done <= 0;
        h_cnt <= 0;
        h_ten <= 0; h_one <= 0;
        m_ten <= 0; m_one <= 0;
        s_ten <= 0; s_one <= 0;
        keypad_prev <= 10'b0000000000;
    end else begin
        keypad_prev <= keypad;

        if (dip_sw) begin
            // 떆媛 꽕 젙 紐⑤뱶
            if (keypad != 10'b0000000000 && keypad_prev == 10'b0000000000) begin
                // 궎 뙣 뱶 엯 젰 利됱떆 諛섏쁺
                case (input_cnt)
                    0: h_ten <= keypad_to_digit(keypad);
                    1: h_one <= keypad_to_digit(keypad);
                    2: m_ten <= keypad_to_digit(keypad);
                    3: m_one <= keypad_to_digit(keypad);
                    4: s_ten <= keypad_to_digit(keypad);
                    5: begin
                        s_one <= keypad_to_digit(keypad);
                        input_done <= 1; // 꽕 젙 셿猷
                    end
                endcase

                // 엯 젰 移댁슫 꽣 利앷
                if (input_cnt < 5) begin
                    input_cnt <= input_cnt + 1;
                end else begin
                    input_cnt <= 0; // 엯 젰 셿猷 썑 珥덇린 솕
                end
            end
        end else if (input_done) begin
            // 떆怨 移댁슫 꽣 紐⑤뱶
            if (h_cnt >= 999) begin
                h_cnt <= 0;
                if (s_one == 9) begin
                    s_one <= 0;
                    if (s_ten == 5) begin
                        s_ten <= 0;
                        if (m_one == 9) begin
                            m_one <= 0;
                            if (m_ten == 5) begin
                                m_ten <= 0;
                                if (h_ten == 2 && h_one == 3) begin
                                    h_ten <= 0;
                                    h_one <= 0;
                                end else if (h_one == 9) begin
                                    h_one <= 0;
                                    h_ten <= h_ten + 1;
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
                h_cnt <= h_cnt + 1;
            end
        end
    end
end

// 궎 뙣 뱶 엯 젰 쓣 닽 옄濡 蹂 솚 븯 뒗 븿 닔
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
        default: keypad_to_digit = 4'd0;
    endcase
endfunction

// -----------------------------
// 꽭洹몃㉫ 듃 뵒肄붾뵫
// -----------------------------
seg_decode u0 (h_ten, seg_h_ten);
seg_decode u1 (h_one, seg_h_one);
seg_decode u2 (m_ten, seg_m_ten);
seg_decode u3 (m_one, seg_m_one);
seg_decode u4 (s_ten, seg_s_ten);
seg_decode u5 (s_one, seg_s_one);

// -----------------------------
// 꽭洹몃㉫ 듃 몴 떆
// -----------------------------
reg [2:0] s_cnt;

always @(posedge clk or posedge rst) begin
    if (rst) s_cnt <= 0;
    else s_cnt <= s_cnt + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        seg_com <= 8'b1111_1111;
        seg_data <= 8'b0000_0000;
    end else begin
        case(s_cnt)
            3'd0: begin seg_com <= 8'b0111_1111; seg_data <= seg_h_ten; end
            3'd1: begin seg_com <= 8'b1011_1111; seg_data <= seg_h_one; end
            3'd2: begin seg_com <= 8'b1101_1111; seg_data <= seg_m_ten; end
            3'd3: begin seg_com <= 8'b1110_1111; seg_data <= seg_m_one; end
            3'd4: begin seg_com <= 8'b1111_0111; seg_data <= seg_s_ten; end
            3'd5: begin seg_com <= 8'b1111_1011; seg_data <= seg_s_one; end
            default: begin seg_com <= 8'b1111_1111; seg_data <= 8'b0000_0000; end
        endcase
    end
end

endmodule