module textlcd(rst, clk, lcd_e, lcd_rs, lcd_rw, lcd_data);

    input rst, clk;
    output lcd_e, lcd_rs, lcd_rw;
    output [7:0] lcd_data;

    wire lcd_e;
    reg lcd_rs, lcd_rw;
    reg [7:0] lcd_data;

    reg [9:0] cnt;
    reg [2:0] state;

    clock_divider clk_div (
        .clk_in(clk),
        .rst(rst),
        .clk_out(clk_100hz)
    );

    parameter delay = 3'b000,
              function_set = 3'b001,
              entry_mode = 3'b010,
              disp_onoff = 3'b011,
              line1 = 3'b100,
              line2 = 3'b101,
              delay_t = 3'b110,
              clear_disp = 3'b111;

    reg [3:0] cnt_100hz;
    reg clk_100hz;

    // 100Hz 클럭 생성
    always @(posedge rst or posedge clk) begin
        if (rst) begin
            cnt_100hz <= 0;
            clk_100hz <= 1'b0;
        end else if (cnt_100hz >= 4) begin
            cnt_100hz <= 0;
            clk_100hz <= ~clk_100hz;
        end else begin
            cnt_100hz <= cnt_100hz + 1;
        end
    end

    // 상태 전환 로직
    always @(posedge rst or posedge clk_100hz) begin
        if (rst) begin
            state <= delay;
            cnt <= 0;
        end else begin
            case (state)
                delay: 
                    if (cnt == 70) begin state <= function_set; cnt <= 0; end 
                    else cnt <= cnt + 1;
                function_set:
                    if (cnt == 30) begin state <= disp_onoff; cnt <= 0; end 
                    else cnt <= cnt + 1;
                disp_onoff:
                    if (cnt == 30) begin state <= entry_mode; cnt <= 0; end 
                    else cnt <= cnt + 1;
                entry_mode:
                    if (cnt == 30) begin state <= line1; cnt <= 0; end 
                    else cnt <= cnt + 1;
                line1:
                    if (cnt == 20) begin state <= line2; cnt <= 0; end 
                    else cnt <= cnt + 1;
                line2:
                    if (cnt == 20) begin state <= delay_t; cnt <= 0; end 
                    else cnt <= cnt + 1;
                delay_t:
                    if (cnt == 400) begin state <= clear_disp; cnt <= 0; end 
                    else cnt <= cnt + 1;
                clear_disp:
                    if (cnt == 200) begin state <= line1; cnt <= 0; end 
                    else cnt <= cnt + 1;
                default: 
                    begin state <= delay; cnt <= 0; end
            endcase
        end
    end

    // LCD 제어 로직
    always @(posedge rst or posedge clk_100hz) begin
        if (rst) begin
            lcd_rs <= 1'b1;
            lcd_rw <= 1'b1;
            lcd_data <= 8'b00000000;
        end else begin
            case (state)
                function_set: begin
                    lcd_rs <= 1'b0;
                    lcd_rw <= 1'b0;
                    lcd_data <= 8'b00111100;
                end
                disp_onoff: begin
                    lcd_rs <= 1'b0;
                    lcd_rw <= 1'b0;
                    lcd_data <= 8'b00001100;
                end
                entry_mode: begin
                    lcd_rs <= 1'b0;
                    lcd_rw <= 1'b0;
                    lcd_data <= 8'b00000110;
                end
                line1: begin
                    lcd_rw <= 1'b0;
                    case (cnt)
                        0:  begin lcd_rs <= 1'b0; lcd_data <= 8'b10000000; end
                        1:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01001000; end // H
                        2:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01100101; end // E
                        3:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01101100; end // L
                        4:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01101100; end // L
                        5:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01101111; end // O
                        default: begin lcd_rs <= 1'b1; lcd_data <= 8'b00100000; end
                    endcase
                end
                line2: begin
                    lcd_rw <= 1'b0;
                    case (cnt)
                        0:  begin lcd_rs <= 1'b0; lcd_data <= 8'b11000000; end
                        1:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01010111; end // W
                        2:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01101111; end // O
                        3:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01110010; end // R
                        4:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01101100; end // L
                        5:  begin lcd_rs <= 1'b1; lcd_data <= 8'b01100100; end // D
                        default: begin lcd_rs <= 1'b1; lcd_data <= 8'b00100000; end
                    endcase
                end
                delay_t: begin
                    lcd_rs <= 1'b0;
                    lcd_rw <= 1'b0;
                    lcd_data <= 8'b00000010;
                end
                clear_disp: begin
                    lcd_rs <= 1'b0;
                    lcd_rw <= 1'b0;
                    lcd_data <= 8'b00000001;
                end
                default: begin
                    lcd_rs <= 1'b1;
                    lcd_rw <= 1'b1;
                    lcd_data <= 8'b00000000;
                end
            endcase
        end
    end

    assign lcd_e = clk_100hz;

endmodule
