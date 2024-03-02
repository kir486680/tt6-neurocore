import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotbext.uart import UartSource

@cocotb.test()
async def test_neural_chip(dut):
    dut._log.info("Start of test")

    # Setup clock
    clock_frequency = 20_000_000  # 20 MHz
    baud_rate = 9600  # Baud rate for data transmission
    clock_period_ns = 1_000_000_000 / clock_frequency  # Clock period in nanoseconds
    clock = Clock(dut.clk, clock_period_ns, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize UART Source
    uart_source = UartSource(dut.ui_in[0], baud=9600, bits=8)

    # Reset
    dut._log.info("Resetting")
    dut.ena.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)  # Ensure a proper reset
    dut.rst_n.value = 1

    # Define the 8-bit numbers to send
    input_values = [0xFE, 0x01, 0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0xFF]



    dut._log.info("Sending data via UART")
    # Convert input values to bytes and send via UART
    await uart_source.send(bytes(input_values))
    # Optionally wait for the transmit operation to complete
    await uart_source.wait()

    load = dut.uo_out[2].value
    print(f"Load: {load}")



    # Wait an additional period to ensure data is processed
    await ClockCycles(dut.clk, 100)
    # Manual check for MULT_DONE signal
    dut._log.info("Checking for MULT_DONE signal on uo_out[1]")
    mult_done_status = dut.uo_out[1].value
    assert mult_done_status == 1, "Multiply operation did not complete as expected."

    dut._log.info("Test completed successfully")
