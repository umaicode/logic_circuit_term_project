module state_app(
    rst, clk, mode, motor_Sense,
    fled_r, fled_g, fled_b,
    seg_dat, seg_com, step_motor
);

input rst, clk, mode, motor_sense;

output [3:0] fled_r, fled_g, fled_b;
output [7:0] seg_dat, seg_com;
output [3:0] step_motor;

reg [7:0] seg_dat;
reg [3:0] step_motor;

reg [7:0] cnt_fled;
reg [1:0] cnt_motor;
reg [3:0] cnt_sense;

parameter s0 = 2'b00, s1 = 2'b01, s2 = 2'b10;
reg [1:0] state_m;

// state machine
always @(posedge rst or posedge mode)

    if (rst) state_m = s0;
    else
        case (state_m)
            s0 : state_m = s1;
            s1 : state_m = s2;
            s2 : state_m = s0;
            default : state_m = s0;
        endcase


// state 1
always @(posedge clk)
    if (state_m == s1) cnt_fled = cnt_fled + 1;
    else cnt_fled = 0;

assign fled_r = {cnt_fled[7], cnt_fled[7], cnt_fled[7], cnt_fled[7]};
assign fled_g = {cnt_fled[6], cnt_fled[6], cnt_fled[6], cnt_fled[6]};
assign fled_b = {cnt_fled[5], cnt_fled[5], cnt_fled[5], cnt_fled[5]};

// state 2
always @(posedge clk)
    if (state_m == s2) cnt_motor = cnt_motor + 1;
    else cnt_motor = 0;

always @(posedge clk)
    if (state_m == s2)
        case (cnt_motor)
            0 : step_motor = 4'b1100;
            1 : step_motor = 4'b0110;
            2 : step_motor = 4'b0011;
            3 : step_motor = 4'b1001;
            default : step_motor = 4'b1100;
        endcase
    else
        step_motor = 4'b0000;

always @(posedge motor_sense)
    if (state_m == s2)
        if (state_m >= 9)   cnt_sense = 0;
        else cnt_sense = cnt_sense + 1;
    else
        cnt_sense = 0;

always @(posedge clk)
    if (state_m == s2)
        case (cnt_sense)
            0 : seg_dat = 8'b1111_1100;
            1 : seg_dat = 8'b0110_0000;
            2 : seg_dat = 8'b1101_1010;
            3 : seg_dat = 8'b1111_0010;
            4 : seg_dat = 8'b0110_0110;
            5 : seg_dat = 8'b1011_0110;
            6 : seg_dat = 8'b1011_1110;
            7 : seg_dat = 8'b1110_0000;
            8 : seg_dat = 8'b1111_1110;
            9 : seg_dat = 8'b1110_0110;
            default : seg_dat : 8'b0000_0000;
        endcase
    else
        seg_dat = 8'b0000_0000;


assign seg_com = 8'b0111_1111;

endmodule