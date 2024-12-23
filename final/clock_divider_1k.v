module clock_divider_1k(
    input clk_in,           // 1MHz 입력
    input rst,
    output reg clk_out      // 1kHz 출력
);
    reg [9:0] count;        // 10비트 카운터 (쿨럭 주기를 표현하기 위해서 이진수 499 : 9비트)


    //============================== 카운터 증가 로직 구현 ==============================
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count   <= 10'd0;               // 카운터 초기화
            clk_out <= 1'b0;                // 쿨럭 초기화
        end else begin
            if (count >= 10'd499) begin
                count   <= 10'd0;           // 499 도달 시 초기화
                clk_out <= ~clk_out;        // 출력 쿨럭 반전 (1kHz)
            end else begin
                count <= count + 1'b1;      // 카운터 증가
            end
        end
    end
    //============================== 카운터 증가 로직 구현 ==============================


endmodule