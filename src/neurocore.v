


module NeuralChip (
    input 	     CLK, // system clock 
    input 	     RESET, // reset button
    input 	     RXD, // UART receive
    output [7:0] logs, // UART receive error
    output [7:0] rx_data_test // UART receive data
    );

    //assign rx_data_test to a dummy wire 
    assign rx_data_test = 0;
    
    //if rxd is high, assign all log bits to 1
    assign logs = RXD ? 8'b11111111 : 8'b00000000;

endmodule
