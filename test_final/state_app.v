module state_app(
    input rst,         // 由ъ뀑 ?떊?샇 (active high)
    input clk,         // 1kHz ?엯?젰 ?겢?윮
    input mode,        // ?긽?깭 ?쟾?솚 ?떊?샇
    input start,       // ?뒪?넲?썙移? ?떆?옉 ?떊?샇
    input dip_sw,
    input dip_sw_timer      // DIP ?뒪?쐞移? ?엯?젰 (1: ?꽕?젙 紐⑤뱶, 0: ?떆怨? 紐⑤뱶)
    input [9:0] keypad, // ?궎?뙣?뱶 ?엯?젰
    output [7:0] seg_data, seg_com,       // 7-?꽭洹몃㉫?듃 ?뵒?뒪?뵆?젅?씠 ?뜲?씠?꽣 諛? 怨듯넻 ?떊?샇
    output lcd_e, lcd_rs, lcd_rw,        // LCD ?젣?뼱 ?떊?샇
    output [7:0] lcd_data,                // LCD ?뜲?씠?꽣
    output [7:0] led
);

    reg[7:0] seg_data;
    reg[7:0] seg_com;
    reg[7:0] led;
   
    // // ?궡遺? ?떊?샇 ?꽑?뼵
    // wire clk_100hz; // 100Hz ?겢?윮 ?떊?샇

    // // ?겢?윮 遺꾩＜湲? ?씤?뒪?꽩?뒪?솕
    // clock_divider clk_div (
    //     .clk_in(clk),    // 1kHz ?엯?젰 ?겢?윮
    //     .rst(rst),       // 由ъ뀑 ?떊?샇
    //     .clk_out(clk_100hz) // 100Hz 異쒕젰 ?겢?윮
    // );

    // ?긽?깭 癒몄떊 ?긽?깭 媛? ?젙?쓽
    parameter s0 = 2'b00, s1 = 2'b01, s2 = 2'b10;
    reg [1:0] state_m; // ?쁽?옱 ?긽?깭瑜? ???옣?븯?뒗 ?젅吏??뒪?꽣

    // ?긽?깭 癒몄떊
    always @(posedge rst or posedge mode) begin
        if (rst) begin
            state_m <= s0; // 由ъ뀑 ?떆 珥덇린 ?긽?깭濡? ?꽕?젙
        end else begin
            case (state_m)
                s0: state_m <= s1; // s0 -> s1
                s1: state_m <= s2; // s1 -> s2
                s2: state_m <= s0; // s2 -> s0
                default: state_m <= s0; // 湲곕낯 ?긽?깭?뒗 s0
            endcase
        end
    end

    // ?떆怨? 紐⑤뱢 異쒕젰
    wire [7:0] watch_seg_data; // ?떆怨? 紐⑤뱢?쓽 7-?꽭洹몃㉫?듃 ?뜲?씠?꽣
    wire [7:0] watch_seg_com;  // ?떆怨? 紐⑤뱢?쓽 7-?꽭洹몃㉫?듃 怨듯넻 ?떊?샇

    watch watch_inst (
        .clk(clk),       // ?떆怨꾨뒗 1kHz ?겢?윮 ?궗?슜
        .rst(rst),       // 由ъ뀑 ?떊?샇
        .keypad(keypad), // ?궎?뙣?뱶 ?엯?젰
        .dip_sw(dip_sw), // DIP ?뒪?쐞移? ?엯?젰
        .seg_data(watch_seg_data), // ?떆怨? ?뜲?씠?꽣 異쒕젰
        .seg_com(watch_seg_com)    // ?떆怨? 怨듯넻 ?떊?샇 異쒕젰
    );

    // ?뒪?넲?썙移? 紐⑤뱢 異붽?
    wire [7:0] stopwatch_seg_data; // ?뒪?넲?썙移? 7-?꽭洹몃㉫?듃 ?뜲?씠?꽣
    wire [7:0] stopwatch_seg_com;  // ?뒪?넲?썙移? 7-?꽭洹몃㉫?듃 怨듯넻 ?떊?샇

    stopwatch stopwatch_inst (
        .clk(clk),           // 1kHz ?겢?윮
        .rst(rst),           // 由ъ뀑 ?떊?샇
        .start(start),        // 紐⑤뱢 ?궡遺??뿉?꽌 踰꾪듉?쑝濡? ?젣?뼱
        .seg_data(stopwatch_seg_data), // ?뒪?넲?썙移? ?뜲?씠?꽣 異쒕젰
        .seg_com(stopwatch_seg_com)    // ?뒪?넲?썙移? 怨듯넻 ?떊?샇 異쒕젰
    );

    wire [7:0] timer_seg_data;
    wire [7:0] timer_seg_com;

    timer timer_inst (
        .clk(clk),
        .rst(rst),
        .dip_sw(dip_sw),
        .keypad(keypad),
        .seg_data(timer_seg_data),
        .seg_com(timer_seg_com)
    )

        // LCD 제어
    wire textlcd_e, textlcd_rs, textlcd_rw;
    wire [7:0] textlcd_data;

    textlcd textlcd_inst (
        .rst(rst),
        .clk(clk),       // 100Hz 클럭
        .lcd_e(textlcd_e),     // LCD Enable
        .lcd_rs(textlcd_rs),   // LCD Register Select
        .lcd_rw(textlcd_rw),   // LCD Read/Write
        .lcd_data(textlcd_data) // LCD 데이터
    );

    assign lcd_e = textlcd_e;
    assign lcd_rs = textlcd_rs;
    assign lcd_rw = textlcd_rw;
    assign lcd_data = textlcd_data;

    // ?긽?깭蹂? 7-?꽭洹몃㉫?듃 ?뵒?뒪?뵆?젅?씠 異쒕젰
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_data <= 8'b0000_0000;
            seg_com <= 8'b1111_1111;
        end else begin
            case (state_m)
                s0: begin
                    // ?떆怨? 異쒕젰
                    seg_data = watch_seg_data;
                    seg_com = watch_seg_com;
                end
                s1: begin
                    // ?뒪?넲?썙移? 異쒕젰
                    seg_data = stopwatch_seg_data;
                    seg_com = stopwatch_seg_com;
                end
                s2: begin
                    // ?븣?엺 ?꽕?젙 (?굹以묒뿉 援ы쁽)
                    seg_data = timer_seg_data; // 湲곕낯媛?
                    seg_com = timer_seg_com; // 湲곕낯媛?
                end
                default: begin
                    seg_data = watch_seg_data;
                    seg_com = watch_seg_com;
                end
            endcase
        end
    end

endmodule
