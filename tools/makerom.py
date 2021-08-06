#
# Please see this video for details:
# https://www.youtube.com/watch?v=yl8vPW5hydQ
#
import argparse


def load_byte_code(source_path, sep=',', comments=';'):
    """
        Reads the content of the file located ad 'source_path'.
        Parses the file and convert all the characters to bytes.

        File must follow some rules:
            - the parsing is applied line by line.
            - comments begin with ';'. Thus, the end of a line, after a ';' will be treated as
            a comment. The comment separator can be modified with arguments.
            - an empty line is treated as a comment.
            - bytes are ',' separated by default. This can be changed with arguments.
            - any number of ',' can be inserted between two bytes, but at least one is required.
            - the usual hexadecimal syntax is used, i.e. 0xHL.

        Args
        ----
        source_path : str
            the path to the byte code.
        sep : str, optional
            the separator between two bytes.
        comments : str, optional
            the comment separator.

        Returns
        -------
        bytes : bytearray
            the bytes in the source byte code given.
    """
    with open(source_path, 'r') as byte_code_file:
        lines = byte_code_file.readlines()
        bytes = []
        for i, line in enumerate(lines):
            line = line.strip()
            print(f"compiling line {i:>{len(str(len(lines)))}}: {line}")
            tokens = line.split(comments)[0].strip()  # remove comments.
            if tokens:  # discard the empty lines.
                _bytes = tokens.split(sep)  # cut where the separator is.
                _bytes = [byte for byte in _bytes if byte]  # remove empty bytes.
                try:
                    _bytes = list(map(lambda b: int(b, 16), _bytes))  # convert to hex.
                except ValueError as ve:
                    print(f"syntax error at line {i}.\n"
                          f"make sure the bytes you wrote are complete and have form '0xHL'.")
                    exit()
                bytes += _bytes  # line compiled, add to all the bytes.
    return bytearray(bytes)


def main():
    parser = argparse.ArgumentParser("some options to compile byte code.")

    parser.add_argument("--source", "-i", type=str, default='',
                        help="the location of the source byte code (defaults to no source).")
    parser.add_argument("--size", "-s", type=int, required=True,
                        help="the size of the ROM file, usually a power of 2 (is required).")
    parser.add_argument("-output", "-o", default="rom.bin", 
                        help="the location of the final ROM file (default to rom.bin).")

    args = parser.parse_args()

    # some code in the ROM, starting at address 0x8000 from the CPU's point of view.
    if args.source:
        code = load_byte_code(source_path=args.source)
    else:
        code = bytearray([])
    # complete the ROM with noop instructions, opcode 0xea.
    rom = code + bytearray([0xea] * (args.size - len(code)))

    # set the starting PC to be the top of the ROM.
    rom[0x7ffc] = 0x00
    rom[0x7ffd] = 0x80

    # write to the rom file.
    with open(args.output, "wb") as out_file:
        print(f"saving byte code to ROM inside the {args.output} file.")
        out_file.write(rom)
        print(f"hexdump -C {args.output}")


if __name__ == "__main__":
    main()

