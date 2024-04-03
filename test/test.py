import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer, Edge
import struct

@cocotb.test()
async def test_neural_chip(dut):

    clock = Clock(dut.clk, 10, units="us")

    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    cocotb.start_soon(wait_for_load(dut))
    print("Multiply Done", dut.uo_out[1].value)
    # Send the initial start byte (0xFE)
    await send_bit(dut)
    await ClockCycles(dut.clk, 2)
    print("Multiply Done", dut.uo_out[1].value)
    #assert dut.uo_out[1].value == 1
    await RisingEdge(dut.clk)

async def send_bit(dut):

    dut.uio_in.value = 1
    print(f"Sending bit : {dut.uio_in[0].value}")
    await ClockCycles(dut.clk, 1)  # Delay for a little 


async def wait_for_load(dut):
    while True:
        await Edge(dut.uo_out)
        #now print the rest of the values
        print("log port 0", dut.uo_out[0].value)
        print("log port 1", dut.uo_out[1].value)
        print("log port 2", dut.uo_out[2].value)
        print("log port 3", dut.uo_out[3].value)
        print("log port 4", dut.uo_out[4].value)
        print("log port 5", dut.uo_out[5].value)
        print("log port 6", dut.uo_out[6].value)
        print("log port 7", dut.uo_out[7].value)
        break
