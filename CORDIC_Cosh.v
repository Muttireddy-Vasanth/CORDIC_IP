//************************************************************
// CORDIC Cosh Module
// Calculates hyperbolic cosine using iterative CORDIC algorithm
// 16 stages with shift and conditional add/subtract
//************************************************************

module CORDIC_Cosh(
    output reg [15:0] X0,         // Final X output (cosh result)
    output reg [15:0] Y0,         // Final Y output after rotation
    output reg [15:0] Z0,         // Final Z output (angle accumulator)
    input      [15:0] Xin,        // Initial X input
    input      [15:0] Yin,        // Initial Y input (usually zero or small)
    input      [15:0] Zin,        // Initial Z input (starting angle)
    input            clk          // Clock
);

    wire signed [15:0] x_reg [0:15];
    wire signed [15:0] y_reg [0:15];
    wire signed [15:0] z_reg [0:15];

    wire signed [15:0] x_reg_sh [0:15];
    wire signed [15:0] y_reg_sh [0:15];

    wire signed [15:0] sum_x [0:15];
    wire signed [15:0] sum_y [0:15];
    wire signed [15:0] sum_z [0:15];

    wire       z_co [0:15];       // Direction control signals

    reg [15:0] alpha [0:15];      // Fixed-point arctanh constants

    integer i;

    // Initialize alpha with arctanh(2^-i) fixed point values
    initial begin
        alpha[0]  = 16'h1193;
        alpha[1]  = 16'h082c;
        alpha[2]  = 16'h0405;
        alpha[3]  = 16'h0200;
        alpha[4]  = 16'h0200;
        alpha[5]  = 16'h0100;
        alpha[6]  = 16'h0080;
        alpha[7]  = 16'h0040;
        alpha[8]  = 16'h0020;
        alpha[9]  = 16'h0010;
        alpha[10] = 16'h0008;
        alpha[11] = 16'h0004;
        alpha[12] = 16'h0002;
        alpha[13] = 16'h0001;
        alpha[14] = 16'h0001;
        alpha[15] = 16'h0000;
    end

    // Stage 0: load inputs into registers
    Register rx0(x_reg[0], Xin, clk);
    Register ry0(y_reg[0], Yin, clk);
    Register rz0(z_reg[0], Zin, clk);

    assign x_reg_sh[0] = x_reg[0] >>> 1;
    assign y_reg_sh[0] = y_reg[0] >>> 1;

    not n0(z_co[0], z_reg[0][15]);

    // Perform first rotation stage
    adder_sub ax0(sum_x[0], , x_reg[0], y_reg_sh[0], z_reg[0][15]);
    adder_sub ay0(sum_y[0], , y_reg[0], x_reg_sh[0], z_reg[0][15]);
    adder_sub az0(sum_z[0], , z_reg[0], alpha[0], z_co[0]);

    // Iterative stages 1 to 15 using generate loop
    generate
        for (i = 1; i < 16; i = i + 1) begin : cordic_stages
            Register rx(x_reg[i], sum_x[i-1], clk);
            Register ry(y_reg[i], sum_y[i-1], clk);
            Register rz(z_reg[i], sum_z[i-1], clk);

            assign x_reg_sh[i] = x_reg[i] >>> i;
            assign y_reg_sh[i] = y_reg[i] >>> i;

            not zn(z_co[i], z_reg[i][15]);

            adder_sub ax(sum_x[i], , x_reg[i], y_reg_sh[i], z_reg[i][15]);
            adder_sub ay(sum_y[i], , y_reg[i], x_reg_sh[i], z_reg[i][15]);
            adder_sub az(sum_z[i], , z_reg[i], alpha[i], z_reg[i][15]);
        end
    endgenerate

    // Final outputs registered on clock edge
    Register rx_final(X0, sum_x[15], clk);
    Register ry_final(Y0, sum_y[15], clk);
    Register rz_final(Z0, sum_z[15], clk);

endmodule

// Same Register and adder_sub modules as in the sinh module

module Register(
    output reg [15:0] x0,
    input      [15:0] xin,
    input             clk
);
    always @(posedge clk) begin
        x0 <= xin;
    end
endmodule

module adder_sub(
    output signed [15:0] sum,
    output               carry,
    input  signed [15:0] in1,
    input  signed [15:0] in2,
    input                direction
);
    assign carry = 0;  // Not used here
    assign sum = direction ? (in1 - in2) : (in1 + in2);
endmodule
