import contextlib
import io
import itertools
import unittest
from unittest.mock import Mock, mock_open, patch

import fw_upd


class FakeSerial:
    def __init__(self, responses):
        self.responses = list(responses)
        self.pending = []
        self.writes = []
        self.close = Mock()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    @property
    def in_waiting(self):
        return len(self.pending[0]) if self.pending else 0

    def write(self, data):
        if self.pending:
            raise AssertionError('Sent a record before reading the previous response')
        self.writes.append(data)
        if self.responses:
            self.pending = list(self.responses.pop(0))
        return len(data)

    def flush(self):
        pass

    def read(self, size):
        return self.pending.pop(0) if self.pending else b''


class FirmwareUploadTests(unittest.TestCase):
    def upload(self, responses, contents=':0000000000\n:00000001FF\n'):
        initialization = FakeSerial([])
        device = FakeSerial(responses)
        clock = itertools.count(step=0.05)
        output = io.StringIO()

        with patch('fw_upd.serial.Serial', side_effect=[initialization, device]) as serial_open, \
             patch('builtins.open', mock_open(read_data=contents)), \
             patch('fw_upd.time.monotonic', side_effect=lambda: next(clock)), \
             contextlib.redirect_stdout(output):
            result = fw_upd.flash_hex('mock', 115200, 'firmware.hex')

        self.assertEqual(serial_open.call_count, 2)
        initialization.close.assert_called_once()
        self.assertEqual(initialization.writes, [])
        return result, device, output.getvalue()

    def test_silent_board_is_not_success(self):
        result, device, output = self.upload([[]])
        self.assertFalse(result)
        self.assertEqual(device.writes, [b'?'])
        device.close.assert_called_once()

    def test_ready_and_acknowledgments_gate_records(self):
        result, device, output = self.upload([
            [b'INFO: Ready to receive .hex file...\n', b'RE', b'ADY\n'],
            [b'.'],
            [b'.INFO: Programmed device successfully!\n'],
        ])
        self.assertTrue(result)
        self.assertEqual(device.writes, [
            b'?', b':0000000000\r\n', b':00000001FF\r\n'])
        device.close.assert_called_once()

    def test_missing_ack_stops_before_next_record(self):
        result, device, output = self.upload([[b'READY\n'], []])
        self.assertFalse(result)
        self.assertEqual(len(device.writes), 2)
        device.close.assert_called_once()

    def test_restart_banner_is_not_an_ack(self):
        result, device, output = self.upload([
            [b'READY\n'],
            [b'INFO: Ready to receive .hex file...\n'],
        ])
        self.assertFalse(result)
        self.assertEqual(len(device.writes), 2)

    def test_fragmented_error_stops_upload(self):
        result, device, output = self.upload([
            [b'READY\n'], [b'ER', b'ROR: Wrong checksum\n'],
        ])
        self.assertFalse(result)
        self.assertEqual(len(device.writes), 2)

    def test_delayed_final_error_is_not_success(self):
        result, device, output = self.upload([
            [b'READY\n'], [b'.'], [b'.', b'ERROR: Wrong checksum\n'],
        ])
        self.assertFalse(result)
        device.close.assert_called_once()

    def test_application_error_after_completion_is_not_a_bootloader_error(self):
        result, device, output = self.upload([
            [b'READY\n'], [b'.'],
            [b'.INFO: Programmed device successfully!\nERROR: Application message\n'],
        ])
        self.assertTrue(result)
        device.close.assert_called_once()

    def test_missing_completion_is_not_success(self):
        result, device, output = self.upload([
            [b'READY\n'], [b'.'], [b'.'],
        ])
        self.assertFalse(result)

    def test_missing_file_does_not_open_serial(self):
        with patch('fw_upd.serial.Serial') as serial_open, \
             patch('builtins.open', side_effect=FileNotFoundError), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertFalse(fw_upd.flash_hex('mock', 115200, 'missing.hex'))
        serial_open.assert_not_called()

    def test_second_open_failure_closes_initial_connection(self):
        initialization = FakeSerial([])
        with patch('fw_upd.serial.Serial', side_effect=[
                initialization, fw_upd.serial.SerialException('Disconnected')]), \
             patch('builtins.open', mock_open(read_data=':00000001FF\n')), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertFalse(fw_upd.flash_hex('mock', 115200, 'firmware.hex'))
        initialization.close.assert_called_once()
        self.assertEqual(initialization.writes, [])


if __name__ == '__main__':
    unittest.main()