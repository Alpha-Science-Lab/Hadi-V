
import serial
import sys
import time

def flash_hex(port, baudrate, hex_file):
    print(f"Connecting to {port} at {baudrate} baud...")

    try:
        ser = serial.Serial(port, baudrate, timeout=1.0)
    except serial.SerialException as e:
        print(f"\nERROR: Could not open serial port '{port}'.")
        print(f"Reason: {e}")
        return False

    print("Serial port opened successfully.")
    time.sleep(2.0)

    try:
        with open(hex_file, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"\nERROR: HEX file not found: '{hex_file}'")
        ser.close()
        return False
    except OSError as e:
        print(f"\nERROR: Could not open HEX file '{hex_file}'.")
        print(f"Reason: {e}")
        ser.close()
        return False

    print(f"Sending {len(lines)} Intel HEX records over UART...")

    # Read initial bootloader header if available
    if ser.in_waiting:
        header = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
        print(f"[UART RX]: {header.strip()}")

    for i, line in enumerate(lines):
        line_clean = line.strip()

        if not line_clean:
            continue

        try:
            ser.write((line_clean + '\r\n').encode('utf-8'))
            ser.flush()
        except serial.SerialException as e:
            print(f"\nERROR: UART communication failed at line {i+1}.")
            print(f"Reason: {e}")
            ser.close()
            return False

        time.sleep(0.005)

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
    print("\nFirmware transfer finished successfully!")
    return True


if __name__ == "__main__":
    port = sys.argv[1] if len(sys.argv) > 1 else "/dev/ttyUSB1"
    baud = int(sys.argv[2]) if len(sys.argv) > 2 else 115200
    hex_path = sys.argv[3] if len(sys.argv) > 3 else "build/test/c/running_led/out.hex"

    flash_hex(port, baud, hex_path)
