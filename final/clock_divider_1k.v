module clock_divider_1k(
    input clk_in,   // 1MHz 입력
    input rst,
    output reg clk_out // 1kHz 출력
);
    reg [9:0] count;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count   <= 10'd0;
            clk_out <= 1'b0;
        end else begin
            if (count >= 10'd499) begin
                count   <= 10'd0;
                clk_out <= ~clk_out;  
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
