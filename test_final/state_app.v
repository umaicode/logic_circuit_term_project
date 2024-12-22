module state_app(
    input rst,         // 뵳 딅 ? 뻿? 깈 (active high)
    input clk,         // 1kHz ? 뿯? 젾 ?寃 ? 쑏
    input mode,        // ?湲 ?源 ? 읈? 넎 ? 뻿? 깈
    input start,       // ? 뮞? 꽧? 뜖燁 ? ? 뻻? 삂 ? 뻿? 깈
    input dip_sw,
    input dip_sw_timer,      // DIP ? 뮞? 맄燁 ? ? 뿯? 젾 (1: ?苑 ? 젟 筌뤴뫀諭 , 0: ? 뻻 ? 筌뤴뫀諭 )
    input [9:0] keypad, // ?沅 ? 솭?諭 ? 뿯? 젾
    output [7:0] seg_data, seg_com,       // 7-?苑 域밸챶 돧? 뱜 ?逾 ? 뮞?逾 ? 쟿? 뵠 ? 쑓? 뵠?苑 獄 ? ⑤벏 꽰 ? 뻿? 깈
    output lcd_e, lcd_rs, lcd_rw,        // LCD ? 젫?堉 ? 뻿? 깈
    output [7:0] lcd_data,                // LCD ? 쑓? 뵠?苑
    output [7:0] led
);

    reg[7:0] seg_data;
    reg[7:0] seg_com;
    reg[7:0] led;
   
    // // ?沅↓겫? ? 뻿? 깈 ?苑 ?堉
    // wire clk_100hz; // 100Hz ?寃 ? 쑏 ? 뻿? 깈

    // // ?寃 ? 쑏 겫袁⑼폒疫 ? ? 뵥? 뮞?苑 ? 뮞? 넅
    // clock_divider clk_div (
    //     .clk_in(clk),    // 1kHz ? 뿯? 젾 ?寃 ? 쑏
    //     .rst(rst),       // 뵳 딅 ? 뻿? 깈
    //     .clk_out(clk_100hz) // 100Hz 빊 뮆 젾 ?寃 ? 쑏
    // );

    // ?湲 ?源 솒紐꾨뻿 ?湲 ?源 揶 ? ? 젟? 벥
    parameter s0 = 2'b00, s1 = 2'b01, s2 = 2'b10;
    reg [1:0] state_m; // ? 겱? 삺 ?湲 ?源 몴? ??? 삢?釉 ? 뮉 ? 쟿筌 ?? 뮞?苑

    // ?湲 ?源 솒紐꾨뻿
    always @(posedge rst or posedge mode) begin
        if (rst) begin
            state_m <= s0; // 뵳 딅 ? 뻻 룯 뜃由 ?湲 ?源 嚥 ? ?苑 ? 젟
        end else begin
            case (state_m)
                s0: state_m <= s1; // s0 -> s1
                s1: state_m <= s2; // s1 -> s2
                s2: state_m <= s0; // s2 -> s0
                default: state_m <= s0; // 疫꿸퀡 궚 ?湲 ?源 ? 뮉 s0
            endcase
        end
    end

    // ? 뻻 ? 筌뤴뫀諭 빊 뮆 젾
    wire [7:0] watch_seg_data; // ? 뻻 ? 筌뤴뫀諭 ? 벥 7-?苑 域밸챶 돧? 뱜 ? 쑓? 뵠?苑
    wire [7:0] watch_seg_com;  // ? 뻻 ? 筌뤴뫀諭 ? 벥 7-?苑 域밸챶 돧? 뱜 ⑤벏 꽰 ? 뻿? 깈

    watch watch_inst (
        .clk(clk),       // ? 뻻 ④쑬 뮉 1kHz ?寃 ? 쑏 ?沅 ? 뒠
        .rst(rst),       // 뵳 딅 ? 뻿? 깈
        .keypad(keypad), // ?沅 ? 솭?諭 ? 뿯? 젾
        .dip_sw(dip_sw), // DIP ? 뮞? 맄燁 ? ? 뿯? 젾
        .seg_data(watch_seg_data), // ? 뻻 ? ? 쑓? 뵠?苑 빊 뮆 젾
        .seg_com(watch_seg_com)    // ? 뻻 ? ⑤벏 꽰 ? 뻿? 깈 빊 뮆 젾
    );

    // ? 뮞? 꽧? 뜖燁 ? 筌뤴뫀諭 빊遺 ?
    wire [7:0] stopwatch_seg_data; // ? 뮞? 꽧? 뜖燁 ? 7-?苑 域밸챶 돧? 뱜 ? 쑓? 뵠?苑
    wire [7:0] stopwatch_seg_com;  // ? 뮞? 꽧? 뜖燁 ? 7-?苑 域밸챶 돧? 뱜 ⑤벏 꽰 ? 뻿? 깈

    stopwatch stopwatch_inst (
        .clk(clk),           // 1kHz ?寃 ? 쑏
        .rst(rst),           // 뵳 딅 ? 뻿? 깈
        .start(start),        // 筌뤴뫀諭 ?沅↓겫??肉 ?苑 甕곌쑵 뱣? 몵嚥 ? ? 젫?堉
        .seg_data(stopwatch_seg_data), // ? 뮞? 꽧? 뜖燁 ? ? 쑓? 뵠?苑 빊 뮆 젾
        .seg_com(stopwatch_seg_com)    // ? 뮞? 꽧? 뜖燁 ? ⑤벏 꽰 ? 뻿? 깈 빊 뮆 젾
    );

    wire [7:0] timer_seg_data;
    wire [7:0] timer_seg_com;

    timer timer_inst (
        .clk(clk),
        .rst(rst),
        .dip_sw_timer(dip_sw_timer),
        .keypad(keypad),
        .seg_data(timer_seg_data),
        .seg_com(timer_seg_com)
    );

        // LCD 젣 뼱
    wire textlcd_e, textlcd_rs, textlcd_rw;
    wire [7:0] textlcd_data;

    textlcd textlcd_inst (
        .rst(rst),
        .clk(clk),       // 100Hz 겢 윮
        .lcd_e(textlcd_e),     // LCD Enable
        .lcd_rs(textlcd_rs),   // LCD Register Select
        .lcd_rw(textlcd_rw),   // LCD Read/Write
        .lcd_data(textlcd_data) // LCD 뜲 씠 꽣
    );

    assign lcd_e = textlcd_e;
    assign lcd_rs = textlcd_rs;
    assign lcd_rw = textlcd_rw;
    assign lcd_data = textlcd_data;

    // ?湲 ?源 癰 ? 7-?苑 域밸챶 돧? 뱜 ?逾 ? 뮞?逾 ? 쟿? 뵠 빊 뮆 젾
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_data <= 8'b0000_0000;
            seg_com <= 8'b1111_1111;
        end else begin
            case (state_m)
                s0: begin
                    // ? 뻻 ? 빊 뮆 젾
                    seg_data = watch_seg_data;
                    seg_com = watch_seg_com;
                end
                s1: begin
                    // ? 뮞? 꽧? 뜖燁 ? 빊 뮆 젾
                    seg_data = stopwatch_seg_data;
                    seg_com = stopwatch_seg_com;
                end
                s2: begin
                    // ?釉 ? 뿺 ?苑 ? 젟 (?援밥빳臾믩퓠 뤃 뗭겱)
                    seg_data = timer_seg_data; // 疫꿸퀡 궚揶 ?
                    seg_com = timer_seg_com; // 疫꿸퀡 궚揶 ?
                end
                default: begin
                    seg_data = watch_seg_data;
                    seg_com = watch_seg_com;
                end
            endcase
        end
    end

endmodule