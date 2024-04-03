`default_nettype none
`include "define.v"
`include "neurocore.v"


module tt_um_neurocore #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


// Hypothesis: the ports are not connected correctly. try different permutations of the io's and see if the testbench can drive the signals
// Procedure: try uio_in and uio_out


    NeuralChip neural_chip_inst (
        .CLK(clk),
        .RESET(rst_n),
        .RXD(uio_in[0]),
        .logs(uo_out[7:0]),
        .rx_data_test(uio_out)
    );

    // All output pins must be assigned. If not used, assign to 0.
    //assign uo_out[1:0] = 2'b0;  // Assign ou_out[7:3] to 0 as it's not used for output
    //assign uio_out[7:0] = 8'b0;     // Assign uio_out to 0 as it's not used for output
    assign uio_oe = 0;      // Assign uio_oe to 0 to configure uio pins as input or disable them for output 

endmodule


