import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, Edge


import numpy as np

def float16_to_8bit_bytes(value):
    if not isinstance(value, np.float16):
        raise TypeError("Input must be a numpy float16.")
    int_representation = np.frombuffer(value.tobytes(), dtype=np.uint16)[0]
    high_byte = int_representation >> 8
    low_byte = int_representation & 0xFF
    return (high_byte, low_byte)

def binary_strings_to_float16(high_byte_str, low_byte_str):
    if len(high_byte_str) != 8 or len(low_byte_str) != 8:
        raise ValueError("Both strings must be 8 bits long.")
    high_byte = int(high_byte_str, 2)
    low_byte = int(low_byte_str, 2)
    int_representation = (high_byte << 8) | low_byte
    float_value = np.frombuffer(np.array([int_representation], dtype=np.uint16).tobytes(), dtype=np.float16)[0]
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

    # Send the initial start byte (0xFE)
    await send_byte(dut, '11111110')
    await Timer(104.167, units='ns')

    # Generate and send float16 values
    for i in range(8):
        float16 = np.float16(i+1)
        high, low = float16_to_8bit_bytes(float16)

        # Send the high byte of the float
        await send_byte(dut, format(high, '08b'))
        await Timer(104.167, units='ns')
        # Send the low byte of the float
        await send_byte(dut, format(low, '08b'))
        await Timer(104.167, units='ns')

    await send_byte(dut, '11111111')
    await Timer(104.167, units='ns')
    print(dut.uo_out[1].value)
    assert dut.uo_out[1].value == 1


async def send_byte(dut, byte):
    print("Byte to send:", byte)

    # Send start bit
    dut.ui_in[0].value = 0
    print("Sending start bit")
    await Timer(104.167, units='us')  # Delay for 1 bit time at 9600 baud

    # Send data bits
    for i in range(7, -1, -1):
        dut.ui_in[0].value = int(byte[i])
        print(f"Sending bit {7-i+1}: {dut.ui_in[0].value}")
        await Timer(104.167, units='us')  # Delay for 1 bit time at 9600 baud

    # Send stop bit
    dut.ui_in[0].value = 1
    print("Sending stop bit")
    await Timer(104.167, units='us')  # Delay for 1 bit time at 9600 baud