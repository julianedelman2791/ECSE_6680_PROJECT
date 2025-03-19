%% Combined Pipelining & L=3 Parallel Processing FIR Filter Simulation
% This script designs a 320-tap low-pass FIR filter using firpm and 
% simulates a combined architecture.
% The filter is partitioned into 3 polyphase branches (L=3) and then each
% branch is processed with a pipelined FIR function.
% The branch outputs are delayed appropriately and summed to emulate the 
% combined pipelining and L=3 parallel processing FIR filter.
%
% An impulse input is used for simulation. The standard FIR impulse 
% response and the combined architecture impulse response are plotted for 
% comparison.

clear; close all; clc;

%% Filter Design
nTaps = 320;                     % Total number of coefficients
f = [0 0.2 0.23 1];              % Normalized frequency bands: passband, transition, stopband
a = [1 1 0 0];
% Note: firpm requires the filter order = nTaps - 1
b = firpm(nTaps-1, f, a);

% Plot filter responses (optional)
figure;
freqz(b, 1, 1024);
title('Frequency Response of Unquantized FIR Filter');

figure;
zplane(b, 1);
title('Zero-Pole Plot of FIR Filter');

%% Generate an Impulse Input Signal
N = 300;                       % Number of simulation samples
x = zeros(1, N);               % Create an impulse input vector
x(1) = 1;                      % Impulse at the first sample

% Standard FIR impulse response for reference
y_standard = filter(b, 1, x);

%% Polyphase Decomposition for L=3
% Partition the full coefficient vector into three branches.
b0 = b(1:3:end);   % Branch 0: indices 0, 3, 6, ...
b1 = b(2:3:end);   % Branch 1: indices 1, 4, 7, ...
b2 = b(3:3:end);   % Branch 2: indices 2, 5, 8, ...

% Define the number of pipeline stages to emulate in each branch.
numStages = 2;  % Chosen for simulation purposes

% Process each branch with the pipelined FIR function.
y0_pipe = pipelined_filter(x, b0, numStages);
y1_pipe = pipelined_filter(x, b1, numStages);
y2_pipe = pipelined_filter(x, b2, numStages);

% Delay the branches appropriately to align their outputs:
y1_pipe_delayed = [zeros(1,1), y1_pipe(1:end-1)];   % Delay branch 1 by 1 sample
y2_pipe_delayed = [zeros(1,2), y2_pipe(1:end-2)];     % Delay branch 2 by 2 samples

% Combine the branch outputs to produce the overall filter output.
y_combined = y0_pipe + y1_pipe_delayed + y2_pipe_delayed;

%% Plot Comparison of Impulse Responses
figure;
subplot(2,1,1);
stem(y_standard, 'filled');
title('Standard FIR Impulse Response');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(2,1,2);
stem(y_combined, 'filled');
title('Combined Pipelined & L=3 Parallel FIR Impulse Response');
xlabel('Sample Index');
ylabel('Amplitude');

%% Helper Function: pipelined_filter
function y_pipe = pipelined_filter(x, b, numStages)
% pipelined_filter simulates a pipelined FIR filter by partitioning the 
% coefficient vector b into numStages segments, filtering the input x with 
% each segment, delaying the resulting output, and summing the delayed outputs.
%
% Inputs:
%   x         - Input signal vector.
%   b         - FIR filter coefficient vector (for one polyphase branch).
%   numStages - Number of pipeline stages to simulate.
%
% Output:
%   y_pipe    - Filtered output signal (same length as x).

    N = length(b);
    stageLen = ceil(N / numStages);
    y_pipe = zeros(1, length(x));
    for stage = 1:numStages
        start_index = (stage - 1) * stageLen + 1;
        end_index = min(stage * stageLen, N);
        seg = b(start_index:end_index);
        
        % Compute the partial FIR output for this segment
        y_partial = filter(seg, 1, x);
        
        % Delay the partial output by (start_index - 1) samples to mimic pipeline delay
        delay = start_index - 1;
        y_partial_delayed = [zeros(1, delay), y_partial];
        y_partial_delayed = y_partial_delayed(1:length(x));  % Ensure matching length
        
        % Sum the delayed partial outputs
        y_pipe = y_pipe + y_partial_delayed;
    end
end
