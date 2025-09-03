module CORDIC_tanInv_sqrt(
    output [15:0] X0,  // Magnitude (scaled)sqrt(X^2+Y^2)
    output [15:0] Y0,  // Should approach zero
    output [15:0] Z0,  // Accumulated angle = arctan(Yin/Xin)
    input  [15:0] Xin,
    input  [15:0] Yin,
    input  [15:0] Zin,  // Usually zero at start
    input  clk
);

    wire signed [15:0] x_reg [15:0];
    wire signed [15:0] y_reg [15:0];
    wire signed [15:0] z_reg [15:0];

    wire [15:0] x_reg_sh [15:0];
    wire [15:0] y_reg_sh [15:0];

    wire [15:0] sum_x [15:0];
    wire [15:0] sum_y [15:0];
    wire [15:0] sum_z [15:0];

    wire [15:0] y_co;

    reg [15:0] alpha[15:0];

    initial begin
        // same alpha table initialization as before
        alpha[0]=16'h1921; alpha[1]=16'h0ed6; alpha[2]=16'h07d6; 
        alpha[3]=16'h03fa; alpha[4]=16'h01ff; alpha[5]=16'h00ff; 
        alpha[6]=16'h007f; alpha[7]=16'h003f; alpha[8]=16'h001f; 
        alpha[9]=16'h000f; alpha[10]=16'h0007; alpha[11]=16'h0003; 
        alpha[12]=16'h0001; alpha[13]=16'h0001; alpha[14]=16'h0001; 
        alpha[15]=16'h0000;
    end

    // Stage 0 - load inputs
    Register rx0(x_reg[0], Xin, clk);
    Register ry0(y_reg[0], Yin, clk);
    Register rz0(z_reg[0], Zin, clk);

    assign x_reg_sh[0] = x_reg[0] >>> 0;
    assign y_reg_sh[0] = y_reg[0] >>> 0;

    not n0(y_co[0], y_reg[0][15]);  // Direction control based on sign of Y

    adder_sub ax0(sum_x[0], , x_reg[0], y_reg_sh[0], y_reg[0][15]);
    adder_sub ay0(sum_y[0], , y_reg[0], x_reg_sh[0], y_reg[0][15]);
    adder_sub az0(sum_z[0], , z_reg[0], alpha[0], y_co[0]);

    genvar i;
    generate
        for (i=1; i<16; i=i+1) begin : vectoring_stages
            Register rx(x_reg[i], sum_x[i-1], clk);
            Register ry(y_reg[i], sum_y[i-1], clk);
            Register rz(z_reg[i], sum_z[i-1], clk);

            assign x_reg_sh[i] = x_reg[i] >>> i;
            assign y_reg_sh[i] = y_reg[i] >>> i;

            not yn(y_co[i], y_reg[i][15]);

            adder_sub ax(sum_x[i], , x_reg[i], y_reg_sh[i], y_reg[i][15]);
            adder_sub ay(sum_y[i], , y_reg[i], x_reg_sh[i], y_reg[i][15]);
            adder_sub az(sum_z[i], , z_reg[i], alpha[i], y_co[i]);
        end
    endgenerate

    // Output registered values
    Register rx16(X0, sum_x[15], clk);
    Register ry16(Y0, sum_y[15], clk);
    Register rz16(Z0, sum_z[15], clk);

endmodule



// Conditional Adder/Subtractor Module
// Performs sum = in1 ± in2 depending on direction bit (cin)
// If cin = 0: sum = in1 + in2
// If cin = 1: sum = in1 - in2
module adder_sub(
    output signed [15:0] sum,
    output               carry,    // Carry output (not used in many CORDIC designs)
    input  signed [15:0] in1,
    input  signed [15:0] in2,
    input                cin       // Direction control: 0-add, 1-subtract
);
    assign carry = 0;  // Carry is not used here
    assign sum = cin ? (in1 - in2) : (in1 + in2);
endmodule


// 16-bit Register Module (Pipelining Register)
// Captures input on rising clock edge
module Register(
    output reg [15:0] q,
    input      [15:0] d,
    input             clk
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule
