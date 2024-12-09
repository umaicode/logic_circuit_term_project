module piezo(clk, rst, piezo);

input clk, rst; // 1Mhz
output piezo;

reg piezo;

parameter do = 12'd3830;    // 261 Hz
parameter rae = 12'd3400;    // 294 Hz
parameter mi = 12'd3038;    // 329 Hz
parameter fa = 12'd2864;    // 349 Hz
parameter sol = 12'd2550;    // 392 Hz
parameter la = 12'd2272;    // 440 Hz
parameter ti = 12'd2028;    // 493 Hz
parameter high_do = 12'd1912;   // 523 Hz

reg [11:0] cnt;

wire [11:0] cnt_limit;

assign cnt_limit = rae;


always @(posedge clk)
    if (rst)   cnt = 0;
    else if (cnt >= cnt_limit / 2)
        begin
            piezo = !piezo;
            cnt = 0;
        end
    else
        cnt = cnt + 1;


endmodule