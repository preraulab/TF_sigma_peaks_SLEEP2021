%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Mingjian He, Michael Prerau
%% ***********************************************************************
close all; clear all; clc

% This data is taken from channel 3 from NSS11_2_200Hz_clin_unfilt.mat 
load('example_data') % load the data 

% run the TF_peak_detection wrapper function to detect TF peaks during
% NREM2 sleep, with TF peak central frequencies confined to 10-16Hz
% Note: consider using clims.m to adjust color scale
[ TFpeaks_table, spectrogram_used, fpeak_proms, fpeak_properties, tpeak_properties ] = TF_peak_detection(EEG, Fs, [stage_times; stages]',...
        'to_plot',true, 'spindle_freq_range',[10,16], 'detection_stages',[2]);
