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

% File list
a = dir('*.txt');
N_files = numel(a);
N_angles = (N_files - 1) / 2;  % 1 file is reference, rest split into θ and φ pol

% Assign theta angles (example)
theta_deg = [-60, -44, -30, 0, 30, 45, 60];

% Read reference (first file)
ref_raw = readmatrix(a(1).name, 'NumHeaderLines', 33);
P_rx_ref_dBm = max(ref_raw(:,2));
EIRRP_ref_dBm = P_rx_ref_dBm - G_rx - L_rx - 20*log10(lambda / (4 * pi * d_rx));
EIRRP_ref_linear = 10^(EIRRP_ref_dBm / 10);

% Initialise PRRP arrays
PRRP_theta_dBm = zeros(N_angles, 1);
PRRP_phi_dBm = zeros(N_angles, 1);
PRRP_total_dBm = zeros(N_angles, 1);
D_RIS_dBi = zeros(N_angles, 1);
TRRP_dBm = zeros(N_angles, 1);

% Read θ polarization (files 2 to N_angles+1)
for i = 1:N_angles
    ris_raw = readmatrix(a(i+1).name, 'NumHeaderLines', 33);
    P_rx_ris_dBm = max(ris_raw(:,2));
    EIRRP_ris_dBm = P_rx_ris_dBm - G_rx - L_rx - 20*log10(lambda / (4 * pi * d_rx));
    PRRP_theta_dBm(i) = EIRRP_ris_dBm;
end

% Read φ polarization (files N_angles+2 to end)
for i = 1:N_angles
    ris_raw = readmatrix(a(N_angles+1+i).name, 'NumHeaderLines', 33);
    P_rx_ris_dBm = max(ris_raw(:,2));
    EIRRP_ris_dBm = P_rx_ris_dBm - G_rx - L_rx - 20*log10(lambda / (4 * pi * d_rx));
    PRRP_phi_dBm(i) = EIRRP_ris_dBm;
end

% Total PRRP (linear sum of both polarisations)
PRRP_theta_linear = 10.^(PRRP_theta_dBm / 10);
PRRP_phi_linear = 10.^(PRRP_phi_dBm / 10);
PRRP_total_linear = PRRP_theta_linear + PRRP_phi_linear;
PRRP_total_dBm = 10*log10(PRRP_total_linear);

% Compute TRRP (hemisphere approximation)
theta_rad = deg2rad(theta_deg);
sin_theta = sin(theta_rad);
M = 1;  % φ sampling: only 1 value per θ (since we're doing cuts)
N = N_angles;

% First part of TRRP: π/NM ∑ (PRRP_total × sinθ)
sum_integral = sum(PRRP_total_linear(1:end-1) .* sin_theta(1:end-1));
% Add 1/2 weight for last angle
last_term = 0.5 * PRRP_total_linear(end);

TRRP_linear = (pi / (N*M)) * (sum_integral + last_term);
TRRP_dBm_common = 10*log10(TRRP_linear);  % common TRRP for all angles

% Compute directivity D = PRRP / TRRP
D_RIS_linear = PRRP_total_linear ./ TRRP_linear;
D_RIS_dBi = 10*log10(D_RIS_linear);

% Sanity: reconstruct TRRP from D
TRRP_dBm = PRRP_total_dBm - D_RIS_dBi;

% Display result
%T = table(theta_deg(:), PRRP_total_dBm(:), D_RIS_dBi(:), ...
%    'VariableNames', {'Angle_deg', 'PRRP_dBm', 'Directivity_dBi'});
%disp(T);
