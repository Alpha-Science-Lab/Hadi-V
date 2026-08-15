#!/usr/bin/env python3
import sys
import time
import serial

def flash_hex(port, baudrate, hex_file):
    print(f"Connecting to {port} at {baudrate} baud...")
    ser = serial.Serial(port, baudrate, timeout=1.0)
    time.sleep(0.1)

    with open(hex_file, 'r') as f:
        lines = f.readlines()

    print(f"Sending {len(lines)} Intel HEX records over UART...")
    
    # Read initial bootloader header if available
    if ser.in_waiting:
        header = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
        print(f"[UART RX]: {header.strip()}")

    for i, line in enumerate(lines):
        line_clean = line.strip()
        if not line_clean:
            continue
        ser.write((line_clean + '\r\n').encode('utf-8'))
        ser.flush()
        time.sleep(0.005) # small line delay

        if ser.in_waiting:
            rx = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
            if "ERROR" in rx:
                print(f"\n[UART ERROR at line {i+1}]: {rx.strip()}")
                ser.close()
                return False
            elif rx.strip():
                print(f"[UART RX]: {rx.strip()}")

    time.sleep(0.2)
    if ser.in_waiting:
        rx = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
        print(f"[UART RX Final]: {rx.strip()}")

    ser.close()
    print("Firmware transfer finished successfully!")
    return True

if __name__ == "__main__":
    port = sys.argv[1] if len(sys.argv) > 1 else "/dev/ttyUSB1"
    baud = int(sys.argv[2]) if len(sys.argv) > 2 else 115200
    hex_path = sys.argv[3] if len(sys.argv) > 3 else "build/test/c/soccer_bot/soccer_bot.hex"
    flash_hex(port, baud, hex_path)
