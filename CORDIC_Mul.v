//************************************************************
// CORDIC Multiplier
// Iterative module performing vector rotation using CORDIC algorithm
// Uses 16 stages with shifting and add/subtract operations at each clock
//************************************************************

module CORDIC_Mul(
    output reg [15:0] X0,
    output reg [15:0] Y0,
    output reg [15:0] Z0,
    input      [15:0] Xin,
    input      [15:0] Yin,
    input      [15:0] Zin,
    input            clk
);

    // Internal wires/registers for each stage
    wire signed [15:0] x_reg  [0:15];
    wire signed [15:0] y_reg  [0:15];
    wire signed [15:0] z_reg  [0:15];

    wire signed [15:0] x_reg_sh [0:15];
    wire signed [15:0] sum_y    [0:15];
    wire signed [15:0] sum_z    [0:15];
    wire               z_co     [0:15]; // Direction signal based on sign of Z

    reg  [15:0] alpha [0:15];  // Angle table for each stage

    integer i;

    // Initialize alpha array with angle constants (scaled)
    initial begin
        alpha[0]  = 16'b0010_0000_0000_0000; // pi/2^1 scaled
        alpha[1]  = 16'b0001_0000_0000_0000; // pi/2^2
        alpha[2]  = 16'b0000_1000_0000_0000; // pi/2^3
        alpha[3]  = 16'b0000_0100_0000_0000; // etc.
        alpha[4]  = 16'b0000_0010_0000_0000;
        alpha[5]  = 16'b0000_0001_0000_0000;
        alpha[6]  = 16'b0000_0000_1000_0000;
        alpha[7]  = 16'b0000_0000_0100_0000;
        alpha[8]  = 16'b0000_0000_0010_0000;
        alpha[9]  = 16'b0000_0000_0001_0000;
        alpha[10] = 16'b0000_0000_0000_1000;
        alpha[11] = 16'b0000_0000_0000_0100;
        alpha[12] = 16'b0000_0000_0000_0010;
        alpha[13] = 16'b0000_0000_0000_0001;
        alpha[14] = 16'b0000_0000_0000_0001;
        alpha[15] = 16'b0000_0000_0000_0000;
    end

    // Stage 0: Load inputs into stage registers
    Register rx0 (x_reg[0], Xin, clk);
    Register ry0 (y_reg[0], Yin, clk);
    Register rz0 (z_reg[0], Zin, clk);

    assign x_reg_sh[0] = x_reg[0] >>> 0; // Shift right by 0 is just x_reg[0]
    assign z_co[0] = ~z_reg[0][15];      // Direction: if MSB of z_reg[0] = 0, z_co[0] = 1 else 0

    adder_sub ay0 (sum_y[0], y_reg[0], x_reg_sh[0], z_reg[0][15]);      // Add/Sub stage 0 for y
    adder_sub az0 (sum_z[0], z_reg[0], alpha[0], z_co[0]);             // Add/Sub stage 0 for z

    // Stages 1 to 15: iterative processing
    genvar idx;
    generate
        for(idx = 1; idx < 16; idx = idx + 1) begin : stages
            Register rx (x_reg[idx], x_reg[idx-1], clk);
            Register ry (y_reg[idx], sum_y[idx-1], clk);
            Register rz (z_reg[idx], sum_z[idx-1], clk);

            assign x_reg_sh[idx] = x_reg[idx] >>> idx;
            assign z_co[idx]     = ~z_reg[idx][15];

            adder_sub ay (sum_y[idx], y_reg[idx], x_reg_sh[idx], z_reg[idx][15]);
            adder_sub az (sum_z[idx], z_reg[idx], alpha[idx], z_co[idx]);
        end
    endgenerate

    // After last stage registers hold final results, clocked to outputs
    Register rx_final (X0, x_reg[15], clk);
    Register ry_final (Y0, sum_y[15], clk);
    Register rz_final (Z0, sum_z[15], clk);

endmodule


//************************************************************
// Register module: Holds 16-bit value on rising edge of clk
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
// adder_sub module: performs addition or subtraction based on sign
// Inputs:
//    in1, in2: operands
//    direction: if 0 do add (sum = in1 + in2), if 1 do subtract (sum = in1 - in2)
// Output:
//    sum: result of addition or subtraction
//************************************************************
module adder_sub(
    output signed [15:0] sum,
    input      signed [15:0] in1,
    input      signed [15:0] in2,
    input                direction
);
    assign sum = direction ? (in1 - in2) : (in1 + in2);
endmodule
