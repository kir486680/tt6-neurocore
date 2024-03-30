


module NeuralChip (
    input 	     CLK, // system clock 
    input 	     RESET, // reset button
    input 	     RXD, // UART receive
    output [7:0]received_state, // UART receive error
    output 	    reg  load_arr,         // UART transmit
    output [7:0] rx_data_test
    );



// UART stuff 
    wire [7:0] rx_data;
    
    wire       rx_ready;
    wire       rx_ack;
    assign received_state[6] = rx_ready;
    assign received_state[7] = rx_ack;
    UART #(
        .FREQ(12_000_000),
        .BAUD(9600)
    ) uart (
        .reset(RESET),
        .clk(CLK),
        .rx_i(RXD),
        .rx_data_o(rx_data),
        .rx_ready_o(rx_ready),
        .rx_ack_i(rx_ack)
    );

    reg [7:0] received_data;
    reg data_received;
    assign rx_data_test = received_data;
    reg data_processed;

    localparam IDLE = 0, DUMMY_STATE = 1;
    //now need to keep track of the state of the data that is being received
    
    reg [5:0] state_receive = IDLE;
    assign received_state[5:0] = state_receive[5:0];

    always @(posedge CLK) begin
        if (!RESET ) begin
            data_received <= 1'b0;
            data_processed <= 1'b0;
            received_data <= 8'h00;
            state_receive <= IDLE;

        end
        else begin
        if (rx_ready && !data_received) begin
            // New data is available and not yet processed
            received_data <= rx_data; // Store the incoming data
            data_received <= 1'b1;    // Set flag to indicate data is ready to be processed
        // state machine to receive the data
            case (state_receive)
            IDLE: begin
                $display("Waiting for data");
                if (rx_data == 8'b11111110) begin
                    data_processed <= 1'b1;
                    state_receive <= DUMMY_STATE;
                    load_arr = 1'b1;
                end
            end
        endcase
        end
    end
        // Once data is processed, reset the flag
        if (data_processed) begin // Assuming data_processed is set once you're done processing
            data_received <= 1'b0;
            data_processed <= 1'b0;
        end
    end

// Acknowledge reception to UART module
    assign rx_ack = rx_ready && !data_received;


    reg data_available;
    
    


endmodule

//send all ones 11111111 from pc to show that the mult result data has been sent 
//send all ones 11111111 from controller to show the last piece of the data has been sent to pc 
// send b111111110 from controller to how that we are beginning to send the data to pc.


/* 

Receiver Half:

input rx_i: This is the input signal for the receiver. It represents the incoming serial data line. The receiver samples this signal to receive data.
output [7:0] rx_data_o: This is an 8-bit output signal that holds the received data byte. When a complete byte is received, rx_data_o is updated with the received data.
output rx_ready_o: This is an output signal that indicates when a complete byte has been received and is ready to be read. It is asserted (goes high) when the receiver has successfully received a byte and is in the RX_FULL state.
input rx_ack_i: This is an input signal used to acknowledge the receipt of the received data. When the receiver is in the RX_FULL state and rx_ack_i is asserted, the receiver transitions back to the RX_IDLE state, ready to receive the next byte.
output rx_error_o: This is an output signal that indicates if an error occurred during the reception of a byte. It is asserted when the receiver is in the RX_ERROR state, which can happen if the stop bit is not detected correctly.

Transmitter Half:

output tx_o: This is the output signal for the transmitter. It represents the outgoing serial data line. The transmitter drives this signal to send data.
input [7:0] tx_data_i: This is an 8-bit input signal that holds the data byte to be transmitted. When tx_ready_i is asserted, the transmitter latches the value of tx_data_i and starts the transmission process.
input tx_ready_i: This is an input signal that indicates when a new byte is ready to be transmitted. When tx_ready_i is asserted and the transmitter is in the TX_IDLE state, the transmitter starts the transmission of the byte.
output tx_ack_o: This is an output signal that acknowledges the transmitter is ready to accept a new byte for transmission. It is asserted when the transmitter is in the TX_IDLE state, indicating that it has completed the previous transmission and is ready for a new byte.
These signals are triggered and updated based on the state machines and strobes in the UART module:

The receiver state machine samples rx_i on the rising edge of rx_sampler_clk and transitions through the states (RX_IDLE, RX_START, RX_DATA, RX_STOP, RX_FULL, RX_ERROR) to receive a byte.
The transmitter state machine updates tx_o on the rising edge of tx_sampler_clk and transitions through the states (TX_IDLE, TX_START, TX_DATA, TX_STOP0, TX_STOP1) to transmit a byte.
The strobes (rx_strobe and tx_strobe) are generated based on the respective sampler clocks and are used to control the timing of the state transitions and data sampling/updating.
*/



module UART #(
        parameter FREQ  = 1_000_000,
        parameter BAUD  = 9600
    ) (
        input           reset,
        input           clk,
        // Receiver half
        input           rx_i,
        output [7:0]    rx_data_o,
        output          rx_ready_o,
        input           rx_ack_i,
        output          rx_error_o,
        // Transmitter half
        output          tx_o,
        input  [7:0]    tx_data_i,
        input           tx_ready_i,
        output          tx_ack_o
    );

    // RX oversampler
    reg        rx_sampler_reset = 1'b0;
    wire       rx_sampler_clk;
    ClockDiv #(
        .FREQ_I(FREQ),
        .FREQ_O(BAUD * 3),
        .PHASE(1'b1),
        .MAX_PPM(50_000)
    ) rx_sampler_clk_div (
        .reset(rx_sampler_reset),
        .clk_i(clk),
        .clk_o(rx_sampler_clk)
    );

    reg  [2:0] rx_sample  = 3'b000;
    wire       rx_sample1 = (rx_sample == 3'b111 ||
                             rx_sample == 3'b110 ||
                             rx_sample == 3'b101 ||
                             rx_sample == 3'b011);
    always @(posedge rx_sampler_clk or negedge rx_sampler_reset)
        if(!rx_sampler_reset)
            rx_sample <= 3'b000;
        else
            rx_sample <= {rx_sample[1:0], rx_i};

    (* fsm_encoding="one-hot" *)
    reg  [1:0] rx_sampleno  = 2'd2;
    wire       rx_samplerdy = (rx_sampleno == 2'd2);
    always @(posedge rx_sampler_clk or negedge rx_sampler_reset)
        if(!rx_sampler_reset)
            rx_sampleno <= 2'd2;
        else case(rx_sampleno)
            2'd0: rx_sampleno <= 2'd1;
            2'd1: rx_sampleno <= 2'd2;
            2'd2: rx_sampleno <= 2'd0;
            default: rx_sampleno <= 2'd0;
        endcase

    // RX strobe generator
    reg  [1:0] rx_strobereg = 2'b00;
    wire       rx_strobe    = (rx_strobereg == 2'b01);
    always @(posedge clk or negedge reset)
        if(!reset)
            rx_strobereg <= 2'b00;
        else
            rx_strobereg <= {rx_strobereg[0], rx_samplerdy};

    // RX state machine
    localparam RX_IDLE  = 3'd0,
               RX_START = 3'd1,
               RX_DATA  = 3'd2,
               RX_STOP  = 3'd3,
               RX_FULL  = 3'd4,
               RX_ERROR = 3'd5;
    reg  [2:0] rx_state = 3'd0;
    reg  [7:0] rx_data  = 8'b00000000;
    reg  [2:0] rx_bitno = 3'd0;
    always @(posedge clk or negedge reset)
        if(!reset) begin
            rx_sampler_reset <= 1'b0;
            rx_state <= RX_IDLE;
            rx_data <= 8'b00000000;
            rx_bitno <= 3'd0;
        end else case(rx_state)
            RX_IDLE:
                if(!rx_i) begin
                    rx_sampler_reset <= 1'b1;
                    rx_state <= RX_START;
                end
                
            RX_START:
                if(rx_strobe)
                    rx_state <= RX_DATA;
            RX_DATA:
                if(rx_strobe) begin
                    if(rx_bitno == 3'd7)
                        rx_state <= RX_STOP;
                    rx_data <= {rx_sample1, rx_data[7:1]};
                    rx_bitno <= rx_bitno + 3'd1;
                end
            RX_STOP:
                if(rx_strobe) begin
                    rx_sampler_reset <= 1'b0;
                    if(rx_sample1 == 1'b0)
                        rx_state <= RX_ERROR;
                    else
                        rx_state <= RX_FULL;
                end
            RX_FULL:
                if(rx_ack_i)
                    rx_state <= RX_IDLE;
                else if(!rx_i)
                    rx_state <= RX_ERROR;
            default:
                rx_state <= RX_IDLE;
        endcase

    assign rx_data_o  = rx_data;
    assign rx_ready_o = (rx_state == RX_FULL);
    assign rx_error_o = (rx_state == RX_ERROR);

    // TX sampler
    reg        tx_sampler_reset = 1'b0;
    wire       tx_sampler_clk;
    ClockDiv #(
        .FREQ_I(FREQ),
        // Make sure TX baud is exactly the same as RX baud, even after all the rounding that
        // might have happened inside rx_sampler_clk_div, by replicating it here.
        // Otherwise, anything that sends an octet every time it receives an octet will
        // eventually catch a frame error.
        .FREQ_O(FREQ / ((FREQ / (BAUD * 3) / 2) * 2) / 3),
        .PHASE(1'b0),
        .MAX_PPM(50_000)
    ) tx_sampler_clk_div (
        .reset(tx_sampler_reset),
        .clk_i(clk),
        .clk_o(tx_sampler_clk)
    );

    // TX strobe generator
    reg  [1:0] tx_strobereg = 2'b00;
    wire       tx_strobe    = (tx_strobereg == 2'b01);
    always @(posedge clk or negedge reset)
        if(!reset)
            tx_strobereg <= 2'b00;
        else
            tx_strobereg <= {tx_strobereg[0], tx_sampler_clk};

    // TX state machine
    localparam TX_IDLE  = 3'd0,
               TX_START = 3'd1,
               TX_DATA  = 3'd2,
               TX_STOP0 = 3'd3,
               TX_STOP1 = 3'd4;
    reg  [2:0] tx_state = 3'd0;
    reg  [7:0] tx_data  = 8'b00000000;
    reg  [2:0] tx_bitno = 3'd0;
    reg        tx_buf   = 1'b1;
    always @(posedge clk or negedge reset)
        if(!reset) begin
            tx_sampler_reset <= 1'b0;
            tx_state <= 3'd0;
            tx_data <= 8'b00000000;
            tx_bitno <= 3'd0;
            tx_buf <= 1'b1;
        end else case(tx_state)
            TX_IDLE:
                if(tx_ready_i) begin
                    tx_sampler_reset <= 1'b1;
                    tx_state <= TX_START;
                    tx_data <= tx_data_i;
                end
            TX_START:
                if(tx_strobe) begin
                    tx_state <= TX_DATA;
                    tx_buf <= 1'b0;
                end
            TX_DATA:
                if(tx_strobe) begin
                    if(tx_bitno == 3'd7)
                        tx_state <= TX_STOP0;
                    tx_data <= {1'b0, tx_data[7:1]};
                    tx_bitno <= tx_bitno + 3'd1;
                    tx_buf <= tx_data[0];
                end
            TX_STOP0:
                if(tx_strobe) begin
                    tx_state <= TX_STOP1;
                    tx_buf <= 1'b1;
                end
            TX_STOP1:
                if(tx_strobe) begin
                    tx_sampler_reset <= 1'b0;
                    tx_state <= TX_IDLE;
                end
            default:
                tx_state <= TX_IDLE;
        endcase

    assign tx_o       = tx_buf;
    assign tx_ack_o   = (tx_state == TX_IDLE);

endmodule


module ClockDiv #(
        parameter FREQ_I  = 2,
        parameter FREQ_O  = 1,
        parameter PHASE   = 1'b0,
        parameter MAX_PPM = 1_000_000
    ) (
        input  reset,
        input  clk_i,
        output clk_o
    );

    // This calculation always rounds frequency up.
    localparam INIT = FREQ_I / FREQ_O / 2 - 1;
    localparam ACTUAL_FREQ_O = FREQ_I / ((INIT + 1) * 2);
    localparam PPM = 64'd1_000_000 * (ACTUAL_FREQ_O - FREQ_O) / FREQ_O;
    generate
        if(INIT < 0)
            _ERROR_FREQ_TOO_HIGH_ error();
        if(PPM > MAX_PPM)
            _ERROR_FREQ_DEVIATION_TOO_HIGH_ error();
    endgenerate

    reg [$clog2(INIT):0] cnt = 0;
    reg                  clk = PHASE;
    always @(posedge clk_i or negedge reset)
        if(!reset) begin
            cnt <= 0;
            clk <= PHASE;
        end else begin
            if(cnt == 0) begin
                clk <= ~clk;
                cnt <= INIT;
            end else begin
                cnt <= cnt - 1;
            end
        end

    assign clk_o = clk;

endmodule