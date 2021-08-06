# 65C02 based computer/assembly project.
In this directory, one will find all the work done on the 65C02 based computer, inspired by the Youtube channel of [Ben Eater](https://www.youtube.com/watch?v=LnzuMJLZRdU&list=PLowKtXNTBypFbtuVMUVXNR0z1mu7dp7eH) on the same topic.  
In case of any issue, please open an issue on the repo or contact us at `supaerocsclub@gmail.com`.

| ![schematics.png](https://github.com/Supaero-Computer-Science-Club/6502-assembly/blob/main/res/schematics.png) | 
|:--:| 
| *Original Schematics of the 65C02 computer* |


## Table Of Content.
- [1  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#1-monitor-the-computer-toc                               ) Monitor the computer.
- [2  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#2-write-byte-code-to-the-computer-toc                    ) Write byte-code to the computer.
- [2.1](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#21-focus-on-the-syntax-inside-a-source-byte-code-file-toc) Focus on the syntax inside a source byte-code file.
- [3  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#3-the-6502-assembly-toc                                  ) The 6502 assembly.
- [3.1](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#31-the-assembler-toc                                     ) The assembler.
- [3.2](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#32-examples-toc                                          ) Examples.
- [3.3](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#33-assembling-with-vasm-toc                              ) Assembling with vasm.
- [4  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#4-looking-at-the-byte-code-toc                           ) Looking at the byte-code.
- [5  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#5-writing-code-to-the-eeprom-toc                         ) Writing code to the eePROM.
- [5.1](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#51-windows-toc                                           ) Windows.
- [5.2](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#52-linux--macos-toc                                      ) Linux / MacOS.
- [6  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#6-source-codes-toc                                       ) Source codes.
- [7  ](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#7-tips-and-tricks-toc                                    ) Tips and tricks.
- [7.1](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#71-shortcuts-toc                                         ) Shortcuts.
- [7.2](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#72-on-the-6502-oldstyle-syntax-toc                       ) On the 6502 oldstyle syntax.
 
## 1 Monitor the computer. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
To monitor the 6502 computer, one is encouraged to use the `tools/monitor/monitor.ino` arduino file.  
Given as default in the project, one should connect the 6502 to an arduino mega (at least with enough digital I/O pins to monitor everything usefull) as follows:  
	- connect the address lines (MSB->LSB) to `pins 52, 50, 48, 46, 44, 42, 40, 38, 36, 34, 32, 30, 28, 26, 24, 22`.  
	- connect the data lines (MSB->LSB) to `pins 53, 51, 49, 47, 45, 43, 41, 39`.  
	- connect the clock signal of the computer to `pin 2`.  
	- connect the R/W pin of the CPU to `pin 3`.  
One can easily change all these values, depending on the project and the arduino, in `tools/monitor/monitor.ino` between lines `14` and `19`.


To actually monitor the computer, after all the pins are connected, run the code inside the Arduino IDE or run the following commands in the terminal. Do not forget to adapt the arguments to your particular needs:
 - upload: `arduino --board arduino:avr:mega:cpu=atmega2560 --port /path/to/device --upload /path/to/sketch/sketch.ino`  
 - monitor: `screen /path/to/device <baud>`  
 - clear: `<Ctrl>aC`
 - return: `<Ctrl>aky`  

One might encounter permission issues regarding the USB ports of the machine used to upload, either with the IDE or in command line. To solve the problem, **giving writing permissions to the USB port** appears to be enough. One could for instance run `chmod a+rw /path/to/device`.  
To know what the path to the arduino is, one should be able to run the `tools/getports` script by using a `./script` run command.


## 2 Write byte-code to the computer. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
If one wants to make some low-level tests and does not want to use the CPU's assembly, one could use the custom `makerom.py` (see code [here](tools/makerom.py)) script to create a ROM file from a raw text file.  
To access full help for this script, please run `python /path/to/makerom.py -h`. One can give an input file, an output size and an output name to the code.

## 2.1 Focus on the syntax inside a source byte-code file. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
By default, the `makerom` script uses ',' as a separator and ';' as comment head. Below is an example code for the 6502 CPU:

```
0xa9, 0xff,         ; lda #$ff
0x8d, 0x02, 0x60,   ; sta $6002

0xa9, 0x55,         ; lda #$55
0x8d, 0x00, 0x60,   ; sta $6000

0xa9, 0xaa,         ; lda #$aa
0x8d, 0x00, 0x60,   ; sta $6000

0x4c, 0x05, 0x80,   ; jmp $8005
```
The file extension does not matter for the `makerom` script. However, for file consistency, the `.bco` extension is being used here for custom byte-code files.

## 3 The 6502 assembly. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
### 3.1 The assembler. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
The assembler used here for the 6502 is called `vasm`. The source code, download site and documentation can be found at [the official vasm website](http://sun.hasenbraten.de/vasm/index.php?view=main).  
Also note that the `CPU=6502` and `SYNTAX=oldstyle` were used to compile all the source codes in this project.  
Running `make CPU=6502 SYNTAX=oldstyle` in the terminal after extracting the source code of `vasm` will be required to compile the assembler.  

**Tip from the writer**: if one does not want to depend on the location of the `vasm` executable, one could do the following.  
Create or append to the `~/.bash_aliases` system file the line below: 
`alias vasm='/path/to/executable/vasm<CPU>_<syntax>'`.  
Then run `source ~/.bashrc` or restart a terminal to be able to run the `vasm` assembler from anywhere on your personal machine by simply calling `vasm`.

### 3.2 Examples. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
Examples are provided throughout this project. Feel free to read them, assemble them and see what they do.  
See [example.bco](src/000_example.bco), [other sources](src) and section [6](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#6-source-codes-toc) for more information.

### 3.3 Assembling with vasm. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
Once you have your source assembly code available, run `vasm -Fbin <source>.s` to assemble the code.  
**Note**: if you ommit the `-Fbin` flag, the file won't be usable for the CPU and rather be in a textfile format. The use of this flag is adviced as a default flag. One can see the content of the binary anyway by following section [4](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#4-looking-at-the-byte-code-toc).

## 4 Looking at the byte-code. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
To look at the resulting byte-code, one can simply run `hexdump -C <romfile>`.

## 5 Writing code to the eePROM. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
### 5.1 Windows. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
The [TL866 II Plus eePROM Programmer](https://eater.net/6502) comes with an MS-Windows software.

### 5.2 Linux / MacOS. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
Please install the `minipro` tool [here](https://gitlab.com/DavidGriffith/minipro).  
Write the code to the eePROM by running, `minipro -p AT28C256 -w <romfile>`

## 6 Source codes. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
Some code are already available in this project:
- `src/000_example.bco.s`                   : byte code example of LED roll.                                                        ([here](src/000_example.bco))
- `src/001_LED-roll.s`                      : real 6502 assembly LED roll.                                                          ([here](src/001_LED-roll.s))
- `src/002_hello-world.s`                   : a suboptimized "hello world!" program.                                                ([here](src/002_hello-world.s))
- `src/003_print-string.s`                  : enhanced "hello world!" program that prints any string.                               ([here](src/003_print-string.s))
- `src/004_hex-print.s`                     : a script to print numbers in hexadecimal.                                             ([here](src/004_hex-print.s))
- `src/005_dec-print.s`                     : a script to print numbers in decimal.                                                 ([here](src/005_dec-print.s))
- `src/005_true-division.s`                 : a script that computes and prints true division of two integers.                      ([here](src/005_true-division.s))
- `src/006_increment-on-push.s`             : a script that increments a 16-bit counter on any button push.                         ([here](src/006_increment-on-push.s))
- `src/007_read-buttons.s`                  : a script that shows the buttons reads of the 5 buttons.                               ([here](src/007_read-buttons.s))
- `src/008_pseudo-random-number-generator.s`: a script that shows a simple pseudo-random number generator using Linear Congruency.  ([here](src/008_pseudo-random-number-generator.s))
- `src/009_lcd-cgram-write.s`               : a script that allows to write custom characters to the CGRAM of the LCD.              ([here](src/009_lcd-cgram-write.s))

## 7 Tips and tricks. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
### 7.1 Shortcuts. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
To compress the previous 3 sections: ([3](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#3-the-6502-assembly-toc)) The 6502 assembly, ([4](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#4-looking-at-the-byte-code-toc)) Looking at the byte-code, ([5](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#5-writing-code-to-the-eeprom-toc)) Writing code to the eePROM, one can use the `makefile` provided with this 65C02 project.  
- `make assemble` to assemble the source code.
- `make hexdump` to see the content of the assembled object file.
- `make write` to write to the eePROM.  

To control what the source is, where the bin file goes and what not, the user may find some tweakable parameters:
- `ASM`: the path to the assembler (defaults to ~/Documents/vasm/vasm/vasm6502_oldstyle).
- `ASMFLAGS`: flags given to the assembler (defaults to -Fbin -dotir -c02).
- `WRITER`: the programmer used for writing to the eePROM (defaults to minipro).
- `DEVICE` the name of the eePROM (defaults to AT28C256).
- `SRC`: the source file (is required).
- `OBJ_DIR`: the output directory (defaults to bin).
- `OBJ`: the object file (defaults to a.out).

To modify such a parameter, simply run something like  
`make assemble SRC=src/source.s` or  
`make SRC=src/source.s OBJ=source.o`  
The general rule is `make <target> <PARAM1>=<value1> <PARAM2>=<value2>`.

### 7.2 On the 6502 oldstyle syntax. [[toc](https://github.com/Supaero-Computer-Science-Club/6502-assembly/tree/main#table-of-content)]
- an introduction to the 65C02 features [here](http://www.obelisk.me.uk/65C02/): addressing modes explained [here](http://www.obelisk.me.uk/65C02/addressing.html) and instructions detailed [here](http://www.obelisk.me.uk/65C02/reference.html).
- the documentation of the **vasm** assembler [here](http://sun.hasenbraten.de/vasm/release/vasm.html): with a special focus on the *Oldstyle Syntax Module* (**6**), *Simple binary output module* (**15**) and *6502 cpu module* (**22**) tabs.
