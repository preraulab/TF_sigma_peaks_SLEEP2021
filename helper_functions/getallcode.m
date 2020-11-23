%
%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Mingjian He, Michael Prerau
%% ***********************************************************************
% get all the codes 
addpath(genpath('/data/preraugp/code/labcode'))
rmpath(genpath('/data/preraugp/code/labcode/utils/fileio'))

%
dest = '/data/preraugp/projects/spindle_phenomenology/github_code';

% multitaper spectrogram estimation
packagecode('/data/preraugp/code/labcode/multitaper/multitaper_spectrogram_release.m',...
    fullfile(dest, 'multitaper'), false);

% artifact rejection
packagecode('/data/preraugp/code/labcode/eeg_analysis/artifact_detection/EEG_detect_time_domain_artifacts.m',...
    fullfile(dest, 'artifact_rejection'), false);

% hand scoring of TF peaks
packagecode('/data/preraugp/projects/spindle_phenomenology/spectrogram_spindle_scoring/spectrogram_spindle_scoring.m',...
    fullfile(dest, 'TFpeak_hand_scoring'), false);

% auto detection of TF peaks
packagecode('/data/preraugp/code/labcode/spindle_detection/TF_peak_toolbox/example_script_use_TF_peak_detection.m',...
    fullfile(dest, 'Property_extraction_and_TFpeak_Auto'), false);