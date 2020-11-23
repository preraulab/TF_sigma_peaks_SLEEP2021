close all
clear all
clc

% simply run
load('example_data')

% run the TF_peak_detection wrapper function
[ spindle_table, spectrogram_used, fpeak_proms, noise_peak_times, lowbw_TFpeaks, fh ]...
    = TF_peak_detection(EEG, Fs, {stage_times, stages}, 'to_plot', false);




