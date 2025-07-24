clear all;
close all;
clc;

% Parameters
freq = 3.5e9;               % Hz
lambda = 3e8 / freq;        % m
G_rx = 6;                   % dBi
G_tx = 6;                   % dBi
d_rx = 1.3;                 % m
d_tx = 3;                   % m
P_tx = 1;                   % dBm
L_tx = 0;                   % dB (Tx cable loss)
L_rx = 0;                   % dB (Rx cable loss)

% Known reference target RCS (metal plate 570 mm × 420 mm at 3.5 GHz)
rcs_ref_dBsm = 19.91;                         % dBsm
rcs_ref_linear = 10^(rcs_ref_dBsm / 10);      % linear scale

% File list
a = dir('*.txt');

% Manually assigned incidence angles (°)
theta_deg = [-60, -44, -30, 0, 30, 45, 60];   % Adjust if needed

rcs_ris_linear = zeros(numel(a)-1, 1);  % Skip reference target

% Reference measurement (assumed first)
ref_raw = readmatrix(a(1).name, 'NumHeaderLines', 33);
P_rx_ref_dBm = max(ref_raw(:,2));

% Convert to EIRRP including Rx cable loss
EIRRP_ref_dBm = P_rx_ref_dBm - G_rx - L_rx - 20*log10(lambda / (4 * pi * d_rx));
EIRRP_ref_linear = 10^(EIRRP_ref_dBm / 10);

% Preallocate
EIRRP_ris_dBm = cell(1, numel(a) - 1);
PRRP_ris_dBm = zeros(1, numel(a) - 1);
RCS_ris_dBsm = zeros(1, numel(a) - 1);
rcs_ris_linear = zeros(1, numel(a) - 1);

num_theta = 46; % 46 for theta from 0° to 90° in 2° steps
num_phi = 180;   % 180 for phi from 0° to 360° in 2° steps

TRRP = zeros(1, numel(a) - 1);
D_RIS = zeros(1, numel(a) - 1);

% Loop through RIS measurements
for i = 2:numel(a)
    ris_raw = readmatrix(a(i).name, 'NumHeaderLines', 33);
    P_rx_ris_dBm = max(ris_raw(:,2));

    % Store full PRRP (EIRRP) values as a vector
    EIRRP_ris_dBm{i-1} = ris_raw(:,2) - G_rx - L_rx - 20*log10(lambda / (4 * pi * d_rx));

    % Compute single peak PRRP
    PRRP_ris_dBm(i-1) = P_rx_ris_dBm - G_rx - L_rx - 20*log10(lambda / (4 * pi * d_rx));

    % Compute RIS RCS relative to reference (in dBsm)
    RCS_ris_dBsm(i-1) = rcs_ref_dBsm + (PRRP_ris_dBm(i-1) - EIRRP_ref_dBm);

    % Convert to linear
    rcs_ris_linear(i-1) = 10^(RCS_ris_dBsm(i-1) / 10);

    % Convert from dB to linear
    PRRP_lin = 10.^(EIRRP_ris_dBm{i-1} / 10);  % Vector of length 90
    N = numel(PRRP_lin);
    theta_vec = linspace(0, pi/2, N).';        % Elevation from 0 to 90 degrees
    sin_theta = sin(theta_vec);
    
    % Total Re-Radiated Power (TRRP), assuming that both polarizations are equal
    TRRP_lin = (4 * pi / N) * sum(PRRP_lin .* sin_theta);  % linear scale
    TRRP(i-1) = 10 * log10(TRRP_lin);                       % dB scale

    % Directivity (dB) at main lobe direction
    D_RIS(i-1) = PRRP_ris_dBm(i-1) - TRRP(i-1) + 10*log10(4*pi);
end

% Normalize RCS
rcs_ris_norm = rcs_ris_linear / max(rcs_ris_linear);
cos2_model = cosd(theta_deg).^2;
cos2_model = cos2_model / max(cos2_model);

% Plot
figure;
plot(theta_deg, rcs_ris_norm, 'r:x', 'LineWidth', 2, 'DisplayName', 'Measured RIS RCS (normalized)');  % red crosses with dotted line
hold on;
plot(theta_deg, cos2_model, 's--', 'LineWidth', 2, 'DisplayName', 'cos^2(\theta)');  % blue squares dashed line
xlabel('Incidence Angle (deg)');
ylabel('Normalized RCS');
title('RIS RCS (via Reference Target Method) vs. cos^2(\theta)');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 12);
