%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Mingjian He, Tanya Dimitrov, Michael Prerau
%% ***********************************************************************
close all
clear all
clc

% simply run
load('example_data')

% run the TF_peak_detection wrapper function
[ spindle_table, spectrogram_used, fpeak_proms, noise_peak_times, lowbw_TFpeaks, fh ]...
    = TF_peak_detection(EEG, Fs, {stage_times, stages}, 'to_plot', false);




