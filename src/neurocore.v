

module NeuralChip (
    input 	     CLK, // system clock 
    input 	     RESET, // reset button
    input 	     RXD, // UART receive
    output [7:0] logs, // UART receive error
    output [7:0] rx_data_test // UART receive data
    );

    //assign rx_data_test to a dummy wire 
    assign rx_data_test = 1;
    
    //if rxd is high, assign all log bits to 1 on the rising edge of the clock
    always @(posedge CLK) begin
        if (RXD == 1) begin
            logs <= 8;
        end else begin
            logs <= 5;
        end
    end
endmodule
