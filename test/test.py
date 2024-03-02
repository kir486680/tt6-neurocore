import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_neural_chip(dut):
    dut._log.info("Start of test")

    # Setup clock
    clock_frequency = 20_000_000  # 20 MHz
    baud_rate = 9600  # Baud rate for data transmission
    clock_period_ns = 1_000_000_000 / clock_frequency  # Clock period in nanoseconds
    clock = Clock(dut.clk, clock_period_ns, units="ns")
    cocotb.start_soon(clock.start())

    cycles_per_bit = clock_frequency / baud_rate  # Calculate cycles per bit

    # Reset
    dut._log.info("Resetting")
    dut.ena.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, int(cycles_per_bit))
    dut.rst_n.value = 1

    # Define the 8-bit numbers to send
    input_values = [0xFE, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0xFF]

    dut._log.info("Sending data at 9600 baud")
    for value in input_values:
        # Send each bit of the 8-bit value, LSB first
        for bit_position in range(8):
            bit_value = (value >> bit_position) & 1
            dut.ui_in[0].value = bit_value
            await ClockCycles(dut.clk, int(cycles_per_bit))  # Wait calculated cycles between bits

    # Wait an additional period to process the last bit
    await ClockCycles(dut.clk, int(cycles_per_bit))

    # Manual check for MULT_DONE signal
    dut._log.info("Checking for MULT_DONE signal on uo_out[1]")
    mult_done_status = dut.uo_out[1].value
    assert mult_done_status == 1, "Multiply operation did not complete as expected."

    dut._log.info("Test completed successfully")
