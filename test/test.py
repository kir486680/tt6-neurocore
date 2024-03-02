import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_neural_chip(dut):
    dut._log.info("Start of test")

    # Setup clock
    clock = Clock(dut.clk, 10, units="us")  # Adjust the clock period as necessary
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Resetting")
    dut.ena.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)  # Wait for a few cycles to ensure reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)  # Wait for reset to propagate

    # Define the 8-bit numbers to send, one bit at a time
    input_values = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]  # Example 8-bit numbers

    dut._log.info("Sending data to the NeuralChip, one bit at a time")
    for value in input_values:
        # Send each bit of the 8-bit value
        for bit_position in range(8):
            bit_value = (value >> bit_position) & 1
            dut.ui_in[0].value = bit_value  # Sending one bit at a time through RXD (ui_in[0])
            await ClockCycles(dut.clk, 1)  # Wait one clock cycle between each bit

    # Wait for the NeuralChip to signal completion
    dut._log.info("Waiting for block_multiply_done signal")
    await RisingEdge(dut.neural_chip_inst.block_multiply_done)

    # Check if block_multiply_done signal is asserted
    assert dut.neural_chip_inst.block_multiply_done.value == 1, "Multiply operation did not complete as expected."

    dut._log.info("Test completed successfully")
