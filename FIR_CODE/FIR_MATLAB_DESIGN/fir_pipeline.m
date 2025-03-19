%% FIR Filter Design & Pipelined Simulation
% This script designs a 320-tap low-pass FIR filter using firpm and 
% simulates a pipelined implementation by partitioning the FIR filter
% into segments and delaying each segment’s convolution accordingly.

clear; close all; clc;

%% Filter Design
% Filter specifications
nTaps = 320;                % Number of taps
f = [0 0.2 0.23 1];         % Normalized frequency bands (0 corresponds to 0 rad/sample, 1 to π rad/sample)
a = [1 1 0 0];

% Design the FIR filter using the equiripple (Parks-McClellan) algorithm
b = firpm(nTaps, f, a);

% Plot filter responses
figure;
freqz(b, 1, 1024);
title('Frequency Response of Unquantized FIR Filter (Pipelining)');

figure;
zplane(b, 1);
title('Zero-Pole Plot of FIR Filter (Pipelining)');

figure;
stem(b, 'filled');
title('Impulse Response of FIR Filter (Pipelining)');
xlabel('Tap Index');
ylabel('Amplitude');

%% Pipelined FIR Filtering Simulation
% Generate a sample input signal (e.g., a random signal)
% x = randn(1, 500);
% Suppose b is your filter coefficient vector (length 321)
x = zeros(1,300);  % 300 samples
x(1) = 1;         % impulse at the first sample
y_matlab = filter(b, 1, x);
stem(y_matlab);


% Partition the filter coefficients into a number of segments (stages)
numStages = 4;
stageLen = ceil(length(b) / numStages);

% Initialize the pipelined output vector
y_pipeline = zeros(1, length(x));

% Process each stage: filter the input with the stage’s coefficients,
% delay the output by the stage’s starting index offset, and sum the results.
for stage = 1:numStages
    start_index = (stage - 1) * stageLen + 1;
    end_index = min(stage * stageLen, length(b));
    seg = b(start_index:end_index);
    
    % Compute the partial FIR output for this segment
    y_partial = filter(seg, 1, x);
    
    % Delay the partial output by (start_index - 1) samples to mimic the pipeline delay
    delay = start_index - 1;
    y_partial_delayed = [zeros(1, delay), y_partial];
    y_partial_delayed = y_partial_delayed(1:length(x)); % Truncate to match the input length
    
    % Sum the delayed partial output to form the overall pipelined output
    y_pipeline = y_pipeline + y_partial_delayed;
end

% Compute the standard FIR filter output for reference
y_standard = filter(b, 1, x);

% Plot and compare the outputs
figure;
plot(y_standard, 'b', 'LineWidth', 1.5); hold on;
plot(y_pipeline, 'r--', 'LineWidth', 1.5);
legend('Standard FIR Output', 'Pipelined FIR Output');
title('Comparison: Standard vs. Pipelined FIR Filter Outputs');
xlabel('Sample'); ylabel('Amplitude');

%% Export Quantized FIR Coefficients as a Plain Text File with Binary Two's Complement Data

% Get the directory where this script is located (or fallback to current folder)
fullPath = mfilename('/Users/julianedelman/Desktop/ECSE_6680/PROJECT');
if isempty(fullPath)
    scriptDir = pwd;
else
    [scriptDir, ~, ~] = fileparts(fullPath);
end
textFilePath = fullfile(scriptDir, 'fir_coefficients.txt');  % Changed filename extension

% Quantize coefficients using a fixed-point type (e.g., Q1.15 format, 16-bit)
T = numerictype(1, 16, 15);
b_fixed = fi(b, T);

% Extract the integer representation of coefficients (they are in two's complement)
coeff = b_fixed.int;
numCoeffs = length(coeff);
wordWidth = 16; % Adjust as needed

% Convert each coefficient to a binary string (two's complement)
% dec2bin only works for non-negative numbers, so if negative, add 2^wordWidth.
binaryCoeffs = cell(numCoeffs, 1);
for i = 1:numCoeffs
    value = coeff(i);
    if value < 0
        value = value + 2^wordWidth;
    end
    binaryCoeffs{i} = dec2bin(value, wordWidth);
end

% Open the plain text file for writing
fileID = fopen(textFilePath, 'w');
if fileID == -1
    error('Failed to open file for writing. Check your permissions or directory.');
end

% Write each coefficient on a new line (no header or addressing)
for i = 1:numCoeffs
    fprintf(fileID, '%s\n', binaryCoeffs{i});
end

fclose(fileID);

disp(['Plain text file saved to: ', textFilePath]);
