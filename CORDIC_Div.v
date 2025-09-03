module CORDIC_Div(
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
    wire signed [15:0] y_reg_sh [0:15];
    wire signed [15:0] sum_x    [0:15];
    wire signed [15:0] sum_y    [0:15];
    wire signed [15:0] sum_z    [0:15];
    wire               y_co     [0:15];  // Direction based on y sign

    reg  [15:0] alpha [0:15];  // Angle table

    integer i;
    initial begin
        alpha[0]  = 16'b0010_0000_0000_0000; // pi/2^1 scaled
        alpha[1]  = 16'b0001_0000_0000_0000; // pi/2^2
        alpha[2]  = 16'b0000_1000_0000_0000; // pi/2^3
        alpha[3]  = 16'b0000_0100_0000_0000;
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

    // Stage 0: Load inputs
    Register rx0(x_reg[0], Xin, clk);
    Register ry0(y_reg[0], Yin, clk);
    Register rz0(z_reg[0], Zin, clk);

    assign x_reg_sh[0] = x_reg[0] >>> 0;
    assign y_reg_sh[0] = y_reg[0] >>> 0;

    not n0(y_co[0], y_reg[0][15]);  // Use sign of y_reg[0] for direction

    adder_sub ax0(sum_x[0], x_reg[0], y_reg_sh[0], y_reg[0][15]);
    adder_sub ay0(sum_y[0], y_reg[0], x_reg_sh[0], y_reg[0][15]);
    adder_sub az0(sum_z[0], z_reg[0], alpha[0], y_co[0]);

    // Iteration stages 1 to 15
    genvar idx;
    generate
        for(idx = 1; idx < 16; idx = idx + 1) begin: stages
            Register rx(x_reg[idx], sum_x[idx-1], clk);
            Register ry(y_reg[idx], sum_y[idx-1], clk);
            Register rz(z_reg[idx], sum_z[idx-1], clk);

            assign x_reg_sh[idx] = x_reg[idx] >>> idx;
            assign y_reg_sh[idx] = y_reg[idx] >>> idx;

            not ny(y_co[idx], y_reg[idx][15]);  // direction from y sign

            adder_sub ax(sum_x[idx], x_reg[idx], y_reg_sh[idx], y_reg[idx][15]);
            adder_sub ay(sum_y[idx], y_reg[idx], x_reg_sh[idx], y_reg[idx][15]);
            adder_sub az(sum_z[idx], z_reg[idx], alpha[idx], y_co[idx]);
        end
    endgenerate

    // Register final outputs
    Register rx_final(X0, x_reg[15], clk);
    Register ry_final(Y0, sum_y[15], clk);
    Register rz_final(Z0, sum_z[15], clk);

endmodule

// Register and adder_sub definitions unchanged

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
    input      signed [15:0] in1,
    input      signed [15:0] in2,
    input                direction
);
    assign sum = direction ? (in1 - in2) : (in1 + in2);
endmodule
