
import serial
import sys
import time

def wait_for_response(ser, expected, response, timeout=5.0):
    deadline = time.monotonic() + timeout
    while True:
        if expected == b'.':
            response[:] = response.lstrip(b'\r\n')
            position = 0 if response.startswith(expected) else -1
            if position < 0 and b'INFO:' in response:
                print("\nERROR: Bootloader restarted instead of acknowledging the record.")
                return False
        else:
            position = response.find(expected)

        error_position = response.find(b'ERROR')
        if error_position >= 0 and (position < 0 or error_position < position):
            print("\nERROR: Bootloader rejected the upload.")
            return False
        if position >= 0:
            del response[:position + len(expected)]
            return True
        if time.monotonic() >= deadline:
            print(f"\nERROR: Timed out waiting for {expected.decode('ascii').strip()!r}.")
            return False
        data = ser.read(ser.in_waiting or 1)
        if data:
            response.extend(data)
            print(data.decode('utf-8', errors='replace'), end='', flush=True)

def flash_hex(port, baudrate, hex_file):
    try:
        with open(hex_file, 'r') as f:
            lines = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"\nERROR: HEX file not found: '{hex_file}'")
        return False
    except OSError as e:
        print(f"\nERROR: Could not open HEX file '{hex_file}'.")
        print(f"Reason: {e}")
        return False

    if not lines:
        print(f"\nERROR: HEX file is empty: '{hex_file}'")
        return False

    print(f"Connecting to {port} at {baudrate} baud...")
    try:
        print("Initializing USB-UART bridge...")
        with serial.Serial(port, baudrate, timeout=0.1,
                   write_timeout=2.0, exclusive=True):
            pass
        ser = serial.Serial(port, baudrate, timeout=0.1,
                            write_timeout=2.0, exclusive=True)
    except (serial.SerialException, OSError) as e:
        print(f"\nERROR: Could not open serial port '{port}'.")
        print(f"Reason: {e}")
        return False

    try:
        print("Waiting for bootloader readiness...")
        response = bytearray()
        ser.write(b'?')
        ser.flush()
        if not wait_for_response(ser, b'READY\n', response):
            print("Reset the FPGA to enter the bootloader; its bitstream must support the READY handshake.")
            return False

        print(f"Sending {len(lines)} Intel HEX records over UART...")
        for i, line in enumerate(lines, start=1):
            ser.write((line + '\r\n').encode('ascii'))
            ser.flush()
            if not wait_for_response(ser, b'.', response):
                print(f"ERROR: No valid acknowledgment for Intel HEX record {i}.")
                return False

        if not wait_for_response(
                ser, b'INFO: Programmed device successfully!\n', response):
            return False
        print("\nFirmware transfer finished successfully!")
        return True
    except (serial.SerialException, OSError, UnicodeError) as e:
        print(f"\nERROR: UART communication failed: {e}")
        return False
    finally:
        ser.close()


if __name__ == "__main__":
    port = sys.argv[1] if len(sys.argv) > 1 else "/dev/ttyUSB1"
    baud = int(sys.argv[2]) if len(sys.argv) > 2 else 115200
    hex_path = sys.argv[3] if len(sys.argv) > 3 else "build/test/c/running_led/out.hex"

    sys.exit(0 if flash_hex(port, baud, hex_path) else 1)
