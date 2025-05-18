# Urbana_Board_Micro_Sd_Card_Reader
This project allows you to read a 320x240 image from a micro SD card into the Urbana Board FPGA and display it onto HDMI. The switches create different filters.

How to use:
1. Clone the repository to your local directory.
2. Assuming you have Vivado installed and are using the Urbana Board (Xilinx Spartan-7 XC7S50-CSGA324 FPGA), open the Urbana_Board.xpr file and generate bitstream.
3. Convert your micro-sd card into FAT16 or FAT32 format.
4. Save a 320x240 image inside the micro-sd card. Name it "example.RGB" else it won't work.
5. After bitstream is done generating, plug your FPGA into your computer and connect the micro-sd card to the FPGA.
6. Program the FPGA and plug your FPGA into an HDMI display. Wait for a few seconds and you should see your image displayed.
7. The switches create different filters for your image
   - sw0: color invert
   - sw1: grain filter (to use this filter, turn on switch1 and reprogram your FPGA while the switch is turned on)
   - sw2: grayscale
   - sw3: contrast (turn on sw3 while also toggling switches 9-14 for different contrast levels.
     - sw9: 0.65
     - sw10: 0.7
     - sw11: 0.75
     - sw12: 0.8
     - sw13: 0.9
     - sw14: 1.5
   - sw4: funky1
   - sw5: funky2
   - Suggestion: use the grain filter along with the contrast filter at 0.7 to create a vintage filter
