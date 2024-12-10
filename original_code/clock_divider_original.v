module clock_divider(
    input clk_in,       // 1kHz 입력 클럭
    input rst,          // 리셋 신호
    output reg clk_out  // 100Hz 출력 클럭
);

reg [3:0] counter;      // 4비트 카운터 (10진수 카운팅)

always @(posedge clk_in or posedge rst) begin
    if (rst) begin
        counter <= 0;
        clk_out <= 0;
    end else if (counter == 9) begin
        counter <= 0;
        clk_out <= ~clk_out; // 클럭 반전으로 50% duty cycle 생성
    end else begin
        counter <= counter + 1;
    end
end

endmodule
