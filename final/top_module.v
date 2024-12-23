module top_module(
    input clk_1mhz,   
    input rst,        
    input mode,       
    input start,      
    input dip_sw,     
    input dip_sw_timer,
    input [9:0] keypad,
    output [7:0] seg_data,
    output [7:0] seg_com,
    output lcd_e,
    output lcd_rs,
    output lcd_rw,
    output [7:0] lcd_data,
    output [7:0] led,
    output piezo_out
);

    //============================== 1) 1MHz -> 1kHz 분주 ==============================
    wire clk_1khz;
    clock_divider_1k div_1k (
        .clk_in(clk_1mhz),
        .rst(rst),
        .clk_out(clk_1khz)
    );
    //============================== 1) 1MHz -> 1kHz 분주 ==============================


    //============================== 2) 상태 전환 로직 ==============================
    parameter s0 = 2'b00,
              s1 = 2'b01,
              s2 = 2'b10;

    reg [1:0] state_m;
    always @(posedge rst or posedge mode) begin
        if (rst) 
            state_m <= s0;
        else begin
            case(state_m)
                s0: state_m <= s1;
                s1: state_m <= s2;
                s2: state_m <= s0;
                default: state_m <= s0;
            endcase
        end
    end
    //============================== 2) 상태 전환 로직 ==============================


    //============================== 3) Watch (1kHz) ==============================
    wire [7:0] watch_seg_data;
    wire [7:0] watch_seg_com;
    watch watch_inst (
        .clk(clk_1khz),
        .rst(rst),
        .dip_sw(dip_sw),
        .keypad(keypad),
        .seg_data(watch_seg_data),
        .seg_com(watch_seg_com)
    );
    //============================== 3) Watch (1kHz) ==============================


    //============================== 4) Stopwatch (1MHz) ==============================
    wire [7:0] stopwatch_seg_data;
    wire [7:0] stopwatch_seg_com;
    stopwatch stopwatch_inst (
        .clk(clk_1mhz),
        .rst(rst),
        .start(start),
        .seg_data(stopwatch_seg_data),
        .seg_com(stopwatch_seg_com)
    );
    //============================== 4) Stopwatch (1MHz) ==============================


    //============================== 5) Timer (1kHz) ==============================
    wire [7:0] timer_seg_data;
    wire [7:0] timer_seg_com;
    wire [7:0] timer_led;
    wire timer_done_wire; // timer 완료 신호

    timer timer_inst (
        .clk(clk_1khz),
        .rst(rst),
        .dip_sw_timer(dip_sw_timer),
        .keypad(keypad),
        .seg_data(timer_seg_data),
        .seg_com(timer_seg_com),
        .led(timer_led),
        .timer_done_out(timer_done_wire) // 출력 연결
    );
    //============================== 5) Timer (1kHz) ==============================


    //============================== 6) TextLCD (1kHz) ==============================
    wire [7:0] textlcd_data_w;
    wire textlcd_e_w, textlcd_rs_w, textlcd_rw_w;
    reg [1:0] msg_sel_reg;
    always @(*) begin
        case(state_m)
            s0: msg_sel_reg = 2'b00;
            s1: msg_sel_reg = 2'b01;
            s2: msg_sel_reg = 2'b10;
            default: msg_sel_reg = 2'b00;
        endcase
    end

    textlcd textlcd_inst (
        .rst(rst),
        .clk(clk_1khz),
        .msg_sel(msg_sel_reg),
        .lcd_e(textlcd_e_w),
        .lcd_rs(textlcd_rs_w),
        .lcd_rw(textlcd_rw_w),
        .lcd_data(textlcd_data_w)
    );

    assign lcd_e    = textlcd_e_w;
    assign lcd_rs   = textlcd_rs_w;
    assign lcd_rw   = textlcd_rw_w;
    assign lcd_data = textlcd_data_w;
    //============================== 6) TextLCD (1kHz) ==============================


    //============================== 7) 상태별 FND 표시 ==============================
    reg [7:0] seg_data_reg;
    reg [7:0] seg_com_reg;
    assign seg_data = seg_data_reg;
    assign seg_com  = seg_com_reg;

    always @(posedge clk_1mhz or posedge rst) begin
        if (rst) begin
            seg_data_reg <= 8'h00;
            seg_com_reg  <= 8'hFF;
        end else begin
            case (state_m)
                s0: begin
                    seg_data_reg <= watch_seg_data;
                    seg_com_reg  <= watch_seg_com;
                end
                s1: begin
                    seg_data_reg <= stopwatch_seg_data;
                    seg_com_reg  <= stopwatch_seg_com;
                end
                s2: begin
                    seg_data_reg <= timer_seg_data;
                    seg_com_reg  <= timer_seg_com;
                end
                default: begin
                    seg_data_reg <= 8'h00;
                    seg_com_reg  <= 8'hFF;
                end
            endcase
        end
    end
    //============================== 7) 상태별 FND 표시 ==============================


    //============================== 8) LED 연결 ==============================
    assign led = timer_led; 
    //============================== 8) LED 연결 ==============================


    //============================== 9) Piezo 멜로디 ==============================
    wire melody_en = timer_done_wire; 

    piezo_melody melody_inst (
        .clk(clk_1mhz),
        .rst(rst),
        .start_melody(melody_en),
        .piezo_out(piezo_out)
    );
    //============================== 9) Piezo 멜로디 ==============================


endmodule