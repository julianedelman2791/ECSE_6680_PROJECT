** FIR Filter Design and Implementation

This project demonstrates the design, implementation, and analysis of a low-pass FIR filter. The objective of the project is to construct a FIR filter using MATLAB and implement various architectures in Verilog. Although the original specification called for a 100-tap filter, a 320-tap filter was chosen to meet the stringent requirements of a transition region from 0.2π to 0.23π rad/sample and at least 80 dB stopband attenuation.

Project Overview

MATLAB Design:
MATLAB was used to generate and analyze the FIR filter coefficients using the equiripple design method. The design process included a thorough pole-zero analysis, frequency response analysis (magnitude and phase), and quantization of coefficients to ensure that the filter meets performance criteria. The MATLAB code and associated plots (z-plane, magnitude/phase, impulse responses) are available in the FIR_MATLAB_DESIGN folder.
Verilog Implementation:
The FIR filter is implemented in Verilog with various architectural approaches including:
A basic non-pipelined design (FIR Standard)
A pipelined design to reduce critical path delay
Parallel architectures with L=2 and L=3 for increased throughput
A combined pipelined and parallel (L=3) design
All main Verilog code, along with test benches for simulation and verification, are contained in the FIR_CODE folder.
Folder Structure

FIR_CODE
Contains the main Verilog source files and test benches for all the different FIR filter architectures. This includes the pipelined, parallel (L=2 and L=3), and the combined pipelined parallel (L=3) designs.
FIR_MATLAB_DESIGN
Contains all MATLAB code used for the filter design, including the scripts for generating the filter coefficients, and scripts for analyzing the frequency response, impulse responses, and quantization effects.
How to Use

MATLAB Design:
Open the MATLAB files in the FIR_MATLAB_DESIGN folder to review the filter design process, view the generated plots, and see the quantization method applied.
Verilog Implementation:
The Verilog source code and test benches in the FIR_CODE folder can be compiled and simulated using your preferred FPGA design environment (Xilinx, Altera, etc.) or via a tool such as Synopsys Design Compiler. Detailed documentation within the code explains the pipelined, parallel, and combined architectures.
Simulation and Testing:
Run the provided test benches to verify the functionality of the FIR filter implementations and observe the simulation outputs, including impulse responses and frequency responses.
This project is documented thoroughly on GitHub and is intended to serve as a comprehensive reference for both academic evaluation and potential industry review.
