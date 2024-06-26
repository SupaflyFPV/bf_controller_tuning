%
% This file is part of pichim's controller tuning framework.
%
% This sofware is free. You can redistribute this software
% and/or modify this software under the terms of the GNU General
% Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later
% version.
%
% This software is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
% See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public
% License along with this software.
%
% If not, see <http:%www.gnu.org/licenses/>.
%
%%
clc, clear variables
addpath ../../bf_function_libary/
%%

linewidth = 1.2;

% create different sampling times
% Ts      = para.looptime * 1.0e-6;             % gyro
% Ts_cntr = para.pid_process_denom * Ts;        % cntrl
% Ts_log  = para.frameIntervalPDenom * Ts_cntr; % logging

Ts = 1 / 8.0e3;

% bf settings
chirp_lag_freq_hz = 3;
chirp_lead_freq_hz = 30;
chirp_amplitude_roll = 230;
chirp_amplitude_pitch = 230;
chirp_amplitude_yaw = 180;
chirp_frequency_start_deci_hz = 2;
chirp_frequency_end_deci_hz = 6000;
chirp_time_seconds = 20;


%%

% bf interal variables
chirpLagFreqHz = chirp_lag_freq_hz;
chirpLeadFreqHz = chirp_lead_freq_hz;
chirpAmplitude = chirp_amplitude_roll;
% chirpAmplitude[FD_ROLL] = chirp_amplitude_roll;
% chirpAmplitude[FD_PITCH] = chirp_amplitude_pitch;
% chirpAmplitude[FD_YAW]= chirp_amplitude_yaw;
chirpFrequencyStartHz = chirp_frequency_start_deci_hz / 10.0;
chirpFrequencyEndHz = chirp_frequency_end_deci_hz / 10.0;
chirpTimeSeconds = chirp_time_seconds;


% input shaping
[Gll, Bll, All] = get_filter('leadlag1', ...
                             [chirpLeadFreqHz, chirpLagFreqHz], ...
                             Ts);

figure(1)
bode(Gll, 2*pi*logspace(-1, 3, 1e4)), title('LLC')
set(findall(gcf, 'type', 'line'), 'linewidth', linewidth)


% chirp signal generator
[exc, fchirp, sinarg] = get_chirp_signals(chirpFrequencyStartHz, ...
    chirpFrequencyEndHz, ...
    chirpTimeSeconds, ...
    Ts);

N = length(exc);
time = (0:(N - 1)).' * Ts;

% you can also feed in time directly
% [exc_, fchirp_, sinarg_] = get_chirp_signals(chirpFrequencyStartHz, ...
%     chirpFrequencyEndHz, ...
%     chirpTimeSeconds, ...
%     time);

figure(2)
subplot(311)
plot(time, exc), grid on, ylabel('exc')
subplot(312)
plot(time, sinarg, 'r'), grid on, ylabel('sinarg (rad)')
subplot(313)
plot(time, fchirp, 'color', [0, 0.5, 0]), grid on, ylabel('fchirp (Hz)')
set(findall(gcf, 'type', 'line'), 'linewidth', linewidth)

chirp = chirpAmplitude * exc;
chirp_filtered = filter(Bll, All, chirp);

figure(3)
ax(1) = subplot(311);
plot(ax(1), fchirp, gradient(chirp_filtered, time), 'color', [0 0.5 0]), grid on
ylabel('Derivative'), set(gca, 'xScale', 'log')
ax(2) = subplot(312);
plot(ax(2), fchirp, [chirp, chirp_filtered]), grid on
set(gca, 'xScale', 'log')
legend('Chirp', 'Chirp after LLC', 'location', 'best')
ax(3) = subplot(313);
plot(ax(3), fchirp, cumtrapz(time, chirp_filtered), 'color', [0 0.5 0]), grid on
ylabel('Integral'), xlabel('Time (sec)'), set(gca, 'xScale', 'log')
linkaxes(ax, 'x'); clear ax; xlim([chirpFrequencyStartHz, chirpFrequencyEndHz])
set(findall(gcf, 'type', 'line'), 'linewidth', linewidth)


Nest     = round(5.0 / Ts);
koverlap = 0.9;
Noverlap = round(koverlap * Nest);
window   = hann(Nest);
[pxx, freq] = estimate_spectras([chirp, chirp_filtered], window, Noverlap, Nest, Ts);
spectra = sqrt(pxx); % power -> amplitude (dc needs to be scaled differently)

figure(4)
plot(freq, spectra), grid on, ylabel('Signal Spectra'), xlabel('Frequency (Hz)')
set(gca, 'YScale', 'log'), set(gca, 'XScale', 'log')
legend('Chirp', 'Chirp after LLC', 'location', 'best')
xlim([0 1/2/Ts])
set(findall(gcf, 'type', 'line'), 'linewidth', linewidth)
