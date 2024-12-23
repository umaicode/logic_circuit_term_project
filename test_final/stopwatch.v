module stopwatch(
    input clk,  // 1kHz clock
    input rst,
    input start,
    output reg [7:0] seg_data,
    output reg [7:0] seg_com
);

    reg [9:0] h_cnt; // 1ms counter
    reg [3:0] h_ten, h_one, m_ten, m_one, s_ten, s_one, ms_ten, ms_one;

    wire [7:0] seg_h_ten, seg_h_one;
    wire [7:0] seg_m_ten, seg_m_one;
    wire [7:0] seg_s_ten, seg_s_one;
    wire [7:0] seg_ms_ten, seg_ms_one;

    reg running; // Stopwatch running state
    reg prev_start; // Previous state of the start button
    reg [2:0] s_cnt; // Segment control counter

    // Start/Stop toggle logic
    always @(posedge clk or posedge rst) begin
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

    // 1ms counter and time update logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_cnt <= 0;
            ms_one <= 0;
            ms_ten <= 0;
            s_one <= 0;
            s_ten <= 0;
            m_one <= 0;
            m_ten <= 0;
            h_one <= 0;
            h_ten <= 0;
        end else if (h_cnt >= 999) begin // 1ms = 1kHz clock cycle
            h_cnt <= 0; // Reset millisecond counter

            if (running) begin
                // Milliseconds update
                if (ms_one >= 9) begin
                    ms_one <= 0;
                    if (ms_ten >= 9) begin
                        ms_ten <= 0;

                        // Seconds update
                        if (s_one >= 9) begin
                            s_one <= 0;
                            if (s_ten >= 5) begin
                                s_ten <= 0;

                                // Minutes update
                                if (m_one >= 9) begin
                                    m_one <= 0;
                                    if (m_ten >= 5) begin
                                        m_ten <= 0;

                                        // Hours update
                                        if (h_one >= 9) begin
                                            h_one <= 0;
                                            if (h_ten >= 9) begin
                                                h_ten <= 0; // Reset to 00:00:00.000
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
                        ms_ten <= ms_ten + 1;
                    end
                end else begin
                    ms_one <= ms_one + 1;
                end
            end
        end else begin
            h_cnt <= h_cnt + 1; // Increment 1ms counter
        end
    end

    // Decode digits into 7-segment values
    seg_decode u0 (h_ten, seg_h_ten);
    seg_decode u1 (h_one, seg_h_one);
    seg_decode u2 (m_ten, seg_m_ten);
    seg_decode u3 (m_one, seg_m_one);
    seg_decode u4 (s_ten, seg_s_ten);
    seg_decode u5 (s_one, seg_s_one);
    seg_decode u6 (ms_ten, seg_ms_ten);
    seg_decode u7 (ms_one, seg_ms_one);

    // Segment control logic (multiplexing)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_cnt <= 0;
        end else begin
            s_cnt <= s_cnt + 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_com <= 8'b1111_1111;
            seg_data <= 8'b0000_0000;
        end else begin
            case (s_cnt)
                3'd0: begin seg_com <= 8'b0111_1111; seg_data <= seg_h_ten; end
                3'd1: begin seg_com <= 8'b1011_1111; seg_data <= seg_h_one; end
                3'd2: begin seg_com <= 8'b1101_1111; seg_data <= seg_m_ten; end
                3'd3: begin seg_com <= 8'b1110_1111; seg_data <= seg_m_one; end
                3'd4: begin seg_com <= 8'b1111_0111; seg_data <= seg_s_ten; end
                3'd5: begin seg_com <= 8'b1111_1011; seg_data <= seg_s_one; end
                3'd6: begin seg_com <= 8'b1111_1101; seg_data <= seg_ms_ten; end
                3'd7: begin seg_com <= 8'b1111_1110; seg_data <= seg_ms_one; end
                default: begin seg_com <= 8'b1111_1111; seg_data <= 8'b0000_0000; end
            endcase
        end
    end

endmodule