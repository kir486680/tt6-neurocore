

module NeuralChip (
    input 	     CLK, // system clock 
    input 	     RESET, // reset button
    input 	     RXD, // UART receive
    output [7:0] logs, // UART receive error
    output [7:0] rx_data_test // UART receive data
    );

    //assign rx_data_test to a dummy wire 
    assign rx_data_test = 1;
    reg [7:0] log_out;
    assign logs = log_out;
    
    //if rxd is high, assign all log bits to 1
    always @ (posedge CLK or negedge RESET)
    begin
        if (RESET == 0)
        begin
            log_out <= 4;
        end
        else if (RXD == 1)
        begin
            log_out <= 8;
        end
    end
endmodule
