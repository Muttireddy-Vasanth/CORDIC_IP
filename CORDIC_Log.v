
//************************************************************
// CORDIC Logarithm Calculator
// Performs iterative calculation of logarithm function using CORDIC in hyperbolic mode
// 16 stages with shifting and add/subtract on x, y, and z registers
//************************************************************

module CORDIC_Log(
    output reg [15:0] X0,    // final x output
    output reg [15:0] Y0,    // final y output
    output reg [15:0] Z0,    // final z output (logarithm result)
    input      [15:0] Xin,   // initial x input
    input      [15:0] Yin,   // initial y input
    input      [15:0] Zin,   // initial z input (starting angle/magnitude)
    input            clk
);

    // Internal signed registers per stage
    wire signed [15:0] x_reg  [0:15];
    wire signed [15:0] y_reg  [0:15];
    wire signed [15:0] z_reg  [0:15];

    // Shifted versions of x and y for each stage
    wire signed [15:0] x_reg_sh [0:15];
    wire signed [15:0] y_reg_sh [0:15];

    // Sum outputs after add/sub operations at each stage
    wire signed [15:0] sum_x [0:15];
    wire signed [15:0] sum_y [0:15];
    wire signed [15:0] sum_z [0:15];

    // Direction control signals based on sign of y_reg at each stage
    wire y_co [0:15];

    // Pre-calculated constants alpha = tanh^(-1)(2^-i) in fixed-point format
    reg [15:0] alpha [0:15];

    integer i;

    // Initialize alpha constants (scaled fixed-point values of tanh^-1(2^-i))
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

    // Stage 0: Load initial inputs into registers
    Register rx0(x_reg[0], Xin, clk);
    Register ry0(y_reg[0], Yin, clk);
    Register rz0(z_reg[0], Zin, clk);

    assign x_reg_sh[0] = x_reg[0] >>> 1; // Shift by 1 (2^1)
    assign y_reg_sh[0] = y_reg[0] >>> 1;
    assign y_co[0]    = ~y_reg[0][15];    // Direction based on MSB of y_reg[0]

    adder_sub ax0(sum_x[0], , x_reg[0],  y_reg_sh[0], y_co[0]);
    adder_sub ay0(sum_y[0], , y_reg[0],  x_reg_sh[0], y_co[0]);
    adder_sub az0(sum_z[0], , z_reg[0],  alpha[0],  y_reg[0][15]);

    // Iterative stages 1 through 15
    generate
        for (i = 1; i < 16; i = i + 1) begin : stages
            Register rx(x_reg[i],  sum_x[i-1], clk);
            Register ry(y_reg[i],  sum_y[i-1], clk);
            Register rz(z_reg[i],  sum_z[i-1], clk);

            assign x_reg_sh[i] = x_reg[i] >>> i;  // shift right by i
            assign y_reg_sh[i] = y_reg[i] >>> i;

            assign y_co[i] = ~y_reg[i][15];       // direction control

            adder_sub ax(sum_x[i], , x_reg[i], y_reg_sh[i], y_co[i]);
            adder_sub ay(sum_y[i], , y_reg[i], x_reg_sh[i], y_co[i]);
            adder_sub az(sum_z[i], , z_reg[i], alpha[i], y_reg[i][15]);
        end
    endgenerate

    // Final outputs registered at clock edge from last stage results
    Register rxn(X0, sum_x[15], clk);
    Register ryn(Y0, sum_y[15], clk);
    Register rzn(Z0, sum_z[15], clk);

endmodule


//************************************************************
// Register module: 16-bit register clocked on posedge clk
//************************************************************
module Register(
    output reg [15:0] x0,
    input      [15:0] xin,
    input             clk
);
    always @(posedge clk) begin
        x0 <= xin;
    end
endmodule


//************************************************************
// adder_sub module: conditional add/sub based on direction control
// If direction=0 -> result = in1 + in2
// If direction=1 -> result = in1 - in2
//************************************************************
module adder_sub(
    output signed [15:0] sum,
    output               carry,  // carry output (not used in current design, left for completeness)
    input  signed [15:0] in1,
    input  signed [15:0] in2,
    input                direction
);
    assign carry = 0; // carry not used
    assign sum = direction ? (in1 - in2) : (in1 + in2);
endmodule
