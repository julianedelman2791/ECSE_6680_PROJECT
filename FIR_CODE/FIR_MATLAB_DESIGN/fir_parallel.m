%% FIR Filter Design & Parallel Processing Simulation (Impulse Input)
% This script designs a FIR filter and simulates parallel processing
% by splitting the convolution into polyphase branches (L=2 and L=3).
% The input is an impulse and the resulting impulse responses are plotted.

clear; close all; clc;

%% Filter Design
% Define filter design parameters
% Here we design an FIR filter with 321 coefficients (order 320)
nTaps = 321;         % Total number of coefficients
f = [0 0.2 0.23 1];   % Normalized frequency bands
a = [1 1 0 0];       % Desired amplitude response

% Note: firpm takes the filter order (which is nTaps-1)
b = firpm(nTaps-1, f, a);

% Plot filter responses (optional)
figure;
freqz(b, 1, 1024);
title('Frequency Response of Unquantized FIR Filter (Parallel)');

figure;
zplane(b, 1);
title('Zero-Pole Plot of FIR Filter (Parallel)');

figure;
stem(b, 'filled');
title('Filter Coefficients (Impulse Response)'); 
xlabel('Tap Index'); ylabel('Amplitude');

%% Impulse Input Generation
% Create an impulse input signal
N = 300;           % Number of input samples for simulation
x = zeros(1, N);
x(1) = 1;          % Impulse at the first sample

% Standard FIR impulse response (for reference)
y_standard = filter(b, 1, x);

%% L=2 Parallel Processing Implementation (Polyphase Decomposition)
% Split coefficients into two branches:
b0 = b(1:2:end);   % Even-indexed taps
b1 = b(2:2:end);   % Odd-indexed taps

% Process each branch using filter with impulse input
y0 = filter(b0, 1, x);
y1 = filter(b1, 1, x);

% To align the branches, delay the odd branch by 1 sample:
y1_delayed = [0, y1(1:end-1)];

% Combine the two branch outputs
y_parallel2 = y0 + y1_delayed;

%% L=3 Parallel Processing Implementation (Polyphase Decomposition)
% Split coefficients into three branches:
b0_3 = b(1:3:end);
b1_3 = b(2:3:end);
b2_3 = b(3:3:end);

% Process each branch using filter with impulse input
y0_3 = filter(b0_3, 1, x);
y1_3 = filter(b1_3, 1, x);
y2_3 = filter(b2_3, 1, x);

% Delay branches appropriately to align the outputs:
y1_3_delayed = [0, y1_3(1:end-1)];       % delay by 1 sample
y2_3_delayed = [0, 0, y2_3(1:end-2)];      % delay by 2 samples

% Combine the three branch outputs
y_parallel3 = y0_3 + y1_3_delayed + y2_3_delayed;

%% Plot Comparison of Impulse Responses
figure;
subplot(4,1,1);
stem(y_standard, 'filled');
title('Standard FIR Impulse Response');
xlabel('Sample Index'); ylabel('Amplitude');

subplot(4,1,2);
stem(y_parallel2, 'filled');
title('Parallel FIR Impulse Response (L=2)');
xlabel('Sample Index'); ylabel('Amplitude');

subplot(4,1,3);
stem(y_parallel3, 'filled');
title('Parallel FIR Impulse Response (L=3)');
xlabel('Sample Index'); ylabel('Amplitude');

subplot(4,1,4);
plot(y_standard, 'b', 'LineWidth', 1.5); hold on;
plot(y_parallel2, 'r--', 'LineWidth', 1.5);
plot(y_parallel3, 'g:', 'LineWidth', 1.5);
title('Comparison of FIR Impulse Responses');
xlabel('Sample Index'); ylabel('Amplitude');
legend('Standard','Parallel L=2','Parallel L=3');
