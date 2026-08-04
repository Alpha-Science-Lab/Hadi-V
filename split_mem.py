
"""
Split a [32-bitx8192] init.mem file into \
sixteen [8-bitx2048] memory initialization files.

Memory Organization
===================

The processor sees one contiguous memory consisting of 8192 32-bit words.

                    CPU Word Address Space
    ------------------------------------------------------
      0 ........ 2047    -> Region 0
   2048 ........ 4095    -> Region 1
   4096 ........ 6143    -> Region 2
   6144 ........ 8191    -> Region 3


Each region is implemented using FOUR independent 8-bit SRAM cells.

Little-endian byte mapping:

Region 0

    Byte[ 7: 0]  -> c0
    Byte[15: 8]  -> c1
    Byte[23:16]  -> c2
    Byte[31:24]  -> c3

Region 1

    Byte[ 7: 0]  -> c4
    Byte[15: 8]  -> c5
    Byte[23:16]  -> c6
    Byte[31:24]  -> c7

Region 2

    Byte[ 7: 0]  -> c8
    Byte[15: 8]  -> c9
    Byte[23:16]  -> c10
    Byte[31:24]  -> c11

Region 3

    Byte[ 7: 0]  -> c12
    Byte[15: 8]  -> c13
    Byte[23:16]  -> c14
    Byte[31:24]  -> c15


Each SRAM cell contains:

        2048 locations × 8 bits

The generated output files are:

        c0.mem
        c1.mem
        ...
        c15.mem

Each output file contains exactly 2048 bytes, one byte per line.

Usage
=====

Default output directory:

    ./split_mem.py build/init.mem

Specify a custom output directory:

    ./split_mem.py build/init.mem -o build/mem_inits




"""

import argparse
import os


# ============================================================================
# Memory configuration
# ============================================================================

# Number of words stored in each SRAM cell.
BYTES_PER_CELL = 2048

# Number of contiguous memory regions.
NUM_REGIONS = 4

# Four 8-bit SRAM cells per region.
CELLS_PER_REGION = 4

# Total SRAM cells.
NUM_CELLS = NUM_REGIONS * CELLS_PER_REGION

# Total processor-visible memory.
MAX_WORDS = BYTES_PER_CELL * NUM_REGIONS


# ============================================================================
# Read init.mem
# ============================================================================

def parse_init_mem(filename):
    """
    Read an init.mem file and return a list of 32-bit words.
    """

    words = []
    current_addr = 0

    with open(filename, "r") as f:

        for line in f:

            line = line.strip()

            if not line:
                continue

            # Address directive.
            if line.startswith("@"):

                current_addr = int(line[1:], 16)

                while len(words) < current_addr:
                    words.append("00000000")

                continue

            # One or more 32-bit words.
            for token in line.split():

                if len(token) != 8:
                    raise RuntimeError(f"Invalid 32-bit word: {token}")

                while len(words) < current_addr:
                    words.append("00000000")

                words.append(token.upper())
                current_addr += 1

    return words


# ============================================================================
# Main
# ============================================================================

def main():

    parser = argparse.ArgumentParser(
        description="Split a 32-bit init.mem into sixteen 8-bit SRAM initialization files."
    )

    parser.add_argument(
        "input",
        help="Path to input init.mem"
    )

    parser.add_argument(
        "-o",
        "--output-dir",
        default="synth/tang9k_mem_inits",
        help="Directory for generated c0.mem ... c15.mem "
             "(default: %(default)s)"
    )

    args = parser.parse_args()

    words = parse_init_mem(args.input)

    if len(words) > MAX_WORDS:
        raise RuntimeError(
            f"Input contains {len(words)} words, "
            f"maximum supported is {MAX_WORDS}."
        )

    # Pad the remaining memory with zeros.
    while len(words) < MAX_WORDS:
        words.append("00000000")

    os.makedirs(args.output_dir, exist_ok=True)

    # Allocate storage for each SRAM cell.
    cells = [[] for _ in range(NUM_CELLS)]

    # ------------------------------------------------------------------------
    # Split every 32-bit word into four byte-wide memories.
    # ------------------------------------------------------------------------

    for word_addr, word in enumerate(words):

        region = word_addr // BYTES_PER_CELL
        base = region * CELLS_PER_REGION

        # Extract bytes.
        b3 = word[0:2]   # Bits [31:24]
        b2 = word[2:4]   # Bits [23:16]
        b1 = word[4:6]   # Bits [15:8]
        b0 = word[6:8]   # Bits [7:0]

        # Little-endian mapping:
        #
        #   c0 <- Byte[7:0]
        #   c1 <- Byte[15:8]
        #   c2 <- Byte[23:16]
        #   c3 <- Byte[31:24]

        cells[base + 0].append(b0)
        cells[base + 1].append(b1)
        cells[base + 2].append(b2)
        cells[base + 3].append(b3)

    # ------------------------------------------------------------------------
    # Write output files.
    # ------------------------------------------------------------------------

    for cell_idx, data in enumerate(cells):

        filename = os.path.join(args.output_dir, f"c{cell_idx}.mem")

        with open(filename, "w") as f:
            f.write("\n".join(data))
            f.write("\n")

        print(f"Generated {filename}")


if __name__ == "__main__":
    main()
