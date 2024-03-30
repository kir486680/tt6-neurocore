import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, Edge
import struct

def float16_to_8bit_bytes(value):
    if not isinstance(value, float):
        raise TypeError("Input must be a float.")
    binary_representation = struct.pack('>e', value)
    int_representation = int.from_bytes(binary_representation, byteorder='big', signed=False)
    high_byte = int_representation >> 8
    low_byte = int_representation & 0xFF
    return (high_byte, low_byte)

def binary_strings_to_float16(high_byte_str, low_byte_str):
    if len(high_byte_str) != 8 or len(low_byte_str) != 8:
        raise ValueError("Both strings must be 8 bits long.")
    high_byte = int(high_byte_str, 2)
    low_byte = int(low_byte_str, 2)
    int_representation = (high_byte << 8) | low_byte
    binary_representation = int_representation.to_bytes(2, byteorder='big', signed=False)
    float_value = struct.unpack('>e', binary_representation)[0]
    return float_value

@cocotb.test()
async def test_neural_chip(dut):
    clock_period = 83.33
    clock = Clock(dut.clk, clock_period, units="ns")

    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    cocotb.start_soon(uart_receive(dut))
    cocotb.start_soon(wait_for_load(dut))

    # Send the initial start byte (0xFE)
    await send_bit(dut)
    await Timer(104.167, units='ns')
    print(dut.uo_out[1].value)
    #assert dut.uo_out[1].value == 1
    await RisingEdge(dut.clk)

async def send_bit(dut):

    dut.ui_in[0].value = int(1)
    print(f"Sending bit : {dut.ui_in[0].value}")
    await Timer(104.167, units='us')  # Delay for a little 

#asynchronously wait for change in uio_out and then read the value of it 
async def uart_receive(dut):
    while True:
        await Edge(dut.uio_out)
        byte = ""
        byte += str(dut.uio_out.value)
        print("UART received:", byte)



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
