import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.uart import UartSource, UartSink

@cocotb.test()
async def test_neural_chip_uart(dut):
    dut._log.info("Start of UART test")

    # Setup clock (adjust the period to match your design's clock)
    clock = Clock(dut.clk, 10, units="ns")  # Example for a 100MHz clock
    cocotb.start_soon(clock.start())

    # Initialize UART source and sink
    uart_source = UartSource(dut.ui_in[0], baud=9600, bits=8)
    uart_sink = UartSink(dut.uo_out[0], baud=9600, bits=8)

    # Reset your DUT (adjust according to your DUT's reset logic)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)  # Wait enough cycles for reset to take effect
    dut.rst_n.value = 1

    # Send data to the DUT using the UART source
    test_data = b'test data'
    await uart_source.write(test_data)
    await uart_source.wait()  # Wait for the transmit operation to complete

    # Receive data from the DUT using the UART sink
    received_data = await uart_sink.read(len(test_data))  # Attempt to read back the sent data

    # Compare the sent and received data
    assert test_data == received_data, f"Data mismatch: sent {test_data}, received {received_data}"

    dut._log.info("UART test completed successfully")
