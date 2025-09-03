`timescale 1ns / 1ps

module CORDIC_Cos(
    output [15:0] X0,
    output [15:0] Y0,
    output [15:0] Z0,
    input [15:0] Xin,
    input [15:0] Yin,
    input [15:0] Zin,
    input clk
);

    wire signed [15:0] x_reg [15:0];
    wire signed [15:0] y_reg [15:0];
    wire signed [15:0] z_reg [15:0];

    wire [15:0] x_reg_sh [15:0];
    wire [15:0] y_reg_sh [15:0];

    wire [15:0] sum_x [15:0];
    wire [15:0] sum_y [15:0];
    wire [15:0] sum_z [15:0];

    wire [15:0] z_co;

    reg [15:0] alpha[15:0];

    initial begin
        alpha[0]  = 16'h1921;   // atan(2^0)
        alpha[1]  = 16'h0ed6;   // atan(2^-1)
        alpha[2]  = 16'h07d6;   // atan(2^-2)
        alpha[3]  = 16'h03fa;   // atan(2^-3)
        alpha[4]  = 16'h01ff;   // atan(2^-4)
        alpha[5]  = 16'h00ff;   // atan(2^-5)
        alpha[6]  = 16'h007f;   // atan(2^-6)
        alpha[7]  = 16'h003f;   // atan(2^-7)
        alpha[8]  = 16'h001f;   // atan(2^-8)
        alpha[9]  = 16'h000f;   // atan(2^-9)
        alpha[10] = 16'h0007;   // atan(2^-10)
        alpha[11] = 16'h0003;   // atan(2^-11)
        alpha[12] = 16'h0001;   // atan(2^-12)
        alpha[13] = 16'h0001;   // atan(2^-13)
        alpha[14] = 16'h0001;   // atan(2^-14)
        alpha[15] = 16'h0000;   // atan(2^-15)
    end

    // Stage 0
    Register rx0(x_reg[0], Xin, clk);
    Register ry0(y_reg[0], Yin, clk);
    Register rz0(z_reg[0], Zin, clk);

    assign x_reg_sh[0] = x_reg[0] >>> 0;
    assign y_reg_sh[0] = y_reg[0] >>> 0;

    not n0(z_co[0], z_reg[0][15]);

    adder_sub ax0(sum_x[0], , x_reg[0], y_reg_sh[0], z_co[0]);
    adder_sub ay0(sum_y[0], , y_reg[0], x_reg_sh[0], z_reg[0][15]);
    adder_sub az0(sum_z[0], , z_reg[0], alpha[0], z_co[0]);

    // Stages 1 to 15
    genvar i;
    generate
        for(i = 1; i < 16; i = i + 1) begin : cordic_stages
            Register rx(x_reg[i], sum_x[i-1], clk);
            Register ry(y_reg[i], sum_y[i-1], clk);
            Register rz(z_reg[i], sum_z[i-1], clk);

            assign x_reg_sh[i] = x_reg[i] >>> i;
            assign y_reg_sh[i] = y_reg[i] >>> i;

            not zn(z_co[i], z_reg[i][15]);

            adder_sub ax(sum_x[i], , x_reg[i], y_reg_sh[i], z_reg[i][15]);
            adder_sub ay(sum_y[i], , y_reg[i], x_reg_sh[i], z_reg[i][15]);
            adder_sub az(sum_z[i], , z_reg[i], alpha[i], z_co[i]);
        end
    endgenerate

    // Outputs (registered)
    Register rx16(X0, sum_x[15], clk);
    Register ry16(Y0, sum_y[15], clk);
    Register rz16(Z0, sum_z[15], clk);

endmodule


// Register module for pipelining
module Register(
    output reg [15:0] x0,
    input [15:0]      xin,
    input             clk
);
    always @(posedge clk) begin
        x0 <= xin;
    end
endmodule


// Adder/subtractor module controlled by direction bit
module adder_sub(
    output [15:0] sum,
    output        carry,
    input  [15:0] A,
    input  [15:0] B,
    input         cin
);
    wire [15:0] b;
    xor x0(b[0], B[0], cin);
    xor x1(b[1], B[1], cin);
    xor x2(b[2], B[2], cin);
    xor x3(b[3], B[3], cin);
    xor x4(b[4], B[4], cin);
    xor x5(b[5], B[5], cin);
    xor x6(b[6], B[6], cin);
    xor x7(b[7], B[7], cin);
    xor x8(b[8], B[8], cin);
    xor x9(b[9], B[9], cin);
    xor x10(b[10], B[10], cin);
    xor x11(b[11], B[11], cin);
    xor x12(b[12], B[12], cin);
    xor x13(b[13], B[13], cin);
    xor x14(b[14], B[14], cin);
    xor x15(b[15], B[15], cin);
    assign {carry, sum} = A + b + cin;
endmodule
