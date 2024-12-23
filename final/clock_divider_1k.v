module clock_divider_1k(
    input clk_in,   // 1MHz 입력
    input rst,
    output reg clk_out // 1kHz 출력
);
    reg [9:0] count; // 분주 카운터 (1MHz / 1kHz = 1000)

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count   <= 0;
            clk_out <= 0;
        end else begin
            if (count >= 999) begin
                count   <= 0;
                clk_out <= ~clk_out;  // 1000번마다 토글 -> 1kHz
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule
