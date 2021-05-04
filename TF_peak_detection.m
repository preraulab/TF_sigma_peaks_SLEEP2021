function [ tfpeak_table, mt_spect, fpeak_proms, fpeak_properties, tpeak_properties, noise_peak_times, lowbw_TFpeaks, fh ] = TF_peak_detection(EEG, Fs, sleep_stages, varargin)
%
%   Copyright 2021 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Mingjian He, Tanya Dimitrov, Michael Prerau
%% ***********************************************************************
%% SEE HELPER FUNCTION TF_peak_inputparse() FOR INPUT PARAMETERS
TF_peak_tic = tic; % start timer

%% Parse input variables
[ input_arguments, input_flags ] = TF_peak_inputparse(EEG,Fs,sleep_stages,varargin{:}); % helper function for input parameters
eval(['[', sprintf('%s ', input_flags{:}), '] = deal(input_arguments{:});']); % compact way of instantiating parameter variables

%% Multitaper spectrogram computation
disp('Creating the spectrogram by using the multitaper_spectrogram function...');
[ spect, stimes, sfreqs ] = compute_multitaper(EEG, Fs, MT_freq_max, MT_taper, MT_window, MT_min_NFFT, MT_detrend, verbose);

%% Artifact detection and valid time points selection
if artifact_detect
    disp('Detecting Artifacts and setting up indices...');
else
    disp('Setting up indices...');
end
% marking valid time points based on specified detection stages and exclude
% artifacts - significantly speeds up findpeaks by skipping invalid time points.
[ detection_inds, normalization_inds, stages_in_stimes ] = select_time_indices(sleep_stages, EEG, Fs, stimes, [], detection_stages, artifact_detect);

%% TF Peak Detection - main algorithm
disp('Finding frequency peaks...'); % frequency domain findpeaks
[ fpeak_proms, fpeak_freqs, fpeak_bandwidths, fpeak_bandwidth_bounds, spectrogram_used ] = find_frequency_peaks(spect,stimes,sfreqs,...
    'valid_time_inds',detection_inds, 'peak_freq_range',peak_freq_range, 'find_freq_range',find_freq_range,...
    'in_db',in_db, 'smooth_Hz',smooth_Hz, 'verbose', verbose, 'findpeaks_version', 'linear');

disp('Finding time peaks...'); % time domain findpeaks
[ fpeak_proms, tpeak_proms, tpeak_times, tpeak_durations, tpeak_center_times,...
    tpeak_central_frequencies, tpeak_bandwidths, tpeak_bandwidth_bounds]...
    = find_time_peaks(fpeak_proms, fpeak_freqs, fpeak_bandwidths, fpeak_bandwidth_bounds, stimes,...
    'valid_time_inds', detection_inds, 'MinPeakWidth_sec',MinPeakWidth_sec, 'MinPeakDistance_sec',MinPeakDistance_sec, 'smooth_sec',smooth_sec);

% create a struct to output multitaper spectrogram results (added on Jan 8th 2021)
mt_spect = struct; % multitaper spectrogram results
mt_spect.spect = spectrogram_used;
mt_spect.stimes = stimes;
mt_spect.sfreqs = sfreqs;
mt_spect.stages_in_stimes = stages_in_stimes;

% create a struct to output tpeak properties (added on July 18th 2020)
fpeak_properties = struct; % frequency domain peak parameters
fpeak_properties.freqs = fpeak_freqs;
fpeak_properties.bandwidths = fpeak_bandwidths;
fpeak_properties.bandwidth_bounds = fpeak_bandwidth_bounds;

tpeak_properties = struct; % time domain peak parameters
tpeak_properties.proms = tpeak_proms;
tpeak_properties.times = tpeak_times;
tpeak_properties.durations = tpeak_durations;
tpeak_properties.center_times = tpeak_center_times;
tpeak_properties.central_frequencies = tpeak_central_frequencies;
tpeak_properties.bandwidths = tpeak_bandwidths;
tpeak_properties.bandwidth_bounds = tpeak_bandwidth_bounds;

if extract_property
    % if extract_property is set true, TF_peak_detection will output the
    % frequency and time domain peak parameters of ALL detected peaks
    % and skip running kmeans clustering that identifies signal events.
    tfpeak_table = [];
    noise_peak_times = [];
    lowbw_TFpeaks = [];
    fh = [];
    [~, stage_index] = ismember(tpeak_center_times, stimes);
    temp_stages = stages_in_stimes(stage_index)';
    canonical_stages = categorical(zeros(size(temp_stages)));
    canonical_stages(temp_stages==1) = 'Stage3';
    canonical_stages(temp_stages==2) = 'Stage2';
    canonical_stages(temp_stages==3) = 'Stage1';
    canonical_stages(temp_stages==4) = 'REM';
    canonical_stages(temp_stages==5) = 'Wake';
    canonical_stages(temp_stages==0) = 'Undefined';
    tpeak_properties.stages = canonical_stages;
    
else
    % extract_property is false, proceed to identify signal events
    disp('Selecting TF peaks...');
    
    % prepare for kmeans clustering
    candidate_signals = log(tpeak_proms);
    
    % calculate spectral resolution
    spectral_resol = MT_taper(1)*2 / MT_window(1);
    if bandwidth_cut % with or without bandwidth cutoff
        bandwidth_data = tpeak_bandwidths;
    else
        bandwidth_data = [];
    end
    
    % identify signal events using kmeans (default on log prominence only)
    [ tfpeak_times, noise_peak_times, clustering_idx, clustering_prom_order, lowbw_TFpeaks ] = ...
        TF_peak_selection(candidate_signals, tpeak_times, 'detection_method',detection_method,...
        'bandwidth_data',bandwidth_data, 'spectral_resol',spectral_resol, 'num_clusters',num_clusters,...
        'prominence_column', 1, 'threshold_percentile',threshold_percentile, 'verbose', verbose);
    
    % append clustering results to time domain peak parameter structure
    tpeak_properties.clustering_order = clustering_prom_order;
    tpeak_properties.clustering_idx = clustering_idx;
    
    %% Create the output table
    tfpeak_table = create_output_tbl(stimes, stages_in_stimes, tfpeak_times, clustering_idx, clustering_prom_order, tpeak_center_times, tpeak_central_frequencies, tpeak_bandwidth_bounds, tpeak_proms);
    
    %% Post processing of tfpeak_table
    % filter to spindle frequency range (added on July 18th 2020)
    valid_tfpeaks = tfpeak_table.Freq_Central >= spindle_freq_range(1) & tfpeak_table.Freq_Central <= spindle_freq_range(2);
    tfpeak_table(~valid_tfpeaks,:) = []; % remove signals outside specified frequency range
    if verbose; disp(['Number of TF peaks dropped due to exceeding bandwidth bounds: ', num2str(sum(~valid_tfpeaks))]); end
    
    %% Plot the spectrogram with TF peaks
    if to_plot
        fh = TF_peak_plot(spect, stimes, sfreqs, stages_in_stimes, tfpeak_table);
    else
        fh = [];
    end
end

%% TF_peak_detection completed
if verbose
    disp('Time taken in running TF_peak_detection:')
    toc(TF_peak_tic) % report time taken in processing
end

end

%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%

function [ input_arguments, input_flags ] = TF_peak_inputparse(EEG,Fs,sleep_stages,varargin)
%% Inputs using input parser
p = inputParser;

% TF_peak_detection wrapper parameters
check_sleep_stages = @(x) sum(size(x)==2)==1;
default_detection_stages = [1 2 3]; % 0:Undefined, 5: Wake, 4:REM, 3:N1, 2:N2, 1:N3
check_detection_stages = @(x) length(unique(x))==length(x) & all(x<=5);
default_to_plot = true;
default_verbose = true;
default_spindle_freq_range = [0, Fs/2];
default_extract_property = false;
default_artifact_detect = true;

% find frequency peaks parameters
default_peak_freq_range = [9 17];
default_find_freq_range = [ ];
check_freq_range = @(x) isempty(x) | ((size(x,1)*size(x,2)==2) & (x(2)>=x(1)) & (x(1)>=0) & (x(2)<=Fs/2));
default_in_db = false;
default_smooth_Hz = 0; %Hz
check_smooth_Hz = @(x) isnumeric(x) & (x>=0) & (x<=Fs/2);

% find time peaks parameters
default_smooth_sec = 0.3; %sec
default_MinPeakWidth_sec = 0.3; %sec
default_MinPeakDistance_sec = 0; %sec

% TF_peak_selection parameters
default_detection_method = 'kmeans';
valid_detection_method = {'kmeans','threshold'};
default_bandwidth_cut = true;
default_num_clusters = 2 ;
default_threshold_percentile = 75;
check_threshold_percentile = @(x) (isnumeric(x)) & (x<=100) ;

% Multitaper parameters
default_MT_freq_max = 30;
default_MT_taper = [2 3];
default_MT_window = [1 0.05];
check_MT_vect = @(x) (size(x,1)*size(x,2))==2;
default_MT_min_NFFT = 2^10;
default_MT_detrend = 'constant';
valid_MT_detrend = {'linear','constant','off'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Construct parser
addRequired(p,'EEG', @isvector);
addRequired(p,'Fs', @isnumeric);
addRequired(p,'sleep_stages', check_sleep_stages); % 0:Undefined, 5: Wake, 4:REM, 3:N1, 2:N2, 1:N3
% TF_peak_detection wrapper parameters
addOptional(p,'detection_stages',default_detection_stages, check_detection_stages);
addOptional(p,'to_plot',default_to_plot, @islogical);
addOptional(p,'verbose',default_verbose, @islogical);
addOptional(p,'spindle_freq_range',default_spindle_freq_range, check_freq_range);
addOptional(p,'extract_property',default_extract_property, @islogical);
addOptional(p,'artifact_detect',default_artifact_detect, @islogical);
% find frequency peaks parameters
addOptional(p,'peak_freq_range',default_peak_freq_range, check_freq_range);
addOptional(p,'find_freq_range',default_find_freq_range, check_freq_range);
addOptional(p,'in_db',default_in_db, @islogical);
addOptional(p,'smooth_Hz',default_smooth_Hz, check_smooth_Hz);
% find time peaks parameters
addOptional(p,'smooth_sec',default_smooth_sec, @isnumeric);
addOptional(p,'MinPeakWidth_sec',default_MinPeakWidth_sec, @isnumeric);
addOptional(p,'MinPeakDistance_sec',default_MinPeakDistance_sec, @isnumeric);
% TF_peak_selection parameters
addOptional(p,'detection_method',default_detection_method, @isstring);
addOptional(p,'bandwidth_cut',default_bandwidth_cut, @logical);
addOptional(p,'num_clusters',default_num_clusters, @isinteger);
addOptional(p,'threshold_percentile',default_threshold_percentile, check_threshold_percentile);
% Multitaper parameters
addOptional(p,'MT_freq_max',default_MT_freq_max, @isnumeric);
addOptional(p,'MT_taper',default_MT_taper, check_MT_vect);
addOptional(p,'MT_window',default_MT_window, check_MT_vect);
addOptional(p,'MT_min_NFFT',default_MT_min_NFFT, @isnumeric);
addOptional(p,'MT_detrend',default_MT_detrend, @isstring);

%now parse the input variables
parse(p,EEG,Fs,sleep_stages,varargin{:});

% instantiate outputs
input_arguments = struct2cell(p.Results);
input_flags = fieldnames(p.Results);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Additional variable processing and modification of outputs
% handle the validatestring inputs
detection_method_index = find(cellfun(@(x) strcmp(x, 'detection_method'), input_flags)==1);
input_arguments{detection_method_index} = validatestring(input_arguments{detection_method_index}, valid_detection_method);
MT_detrend_index = find(cellfun(@(x) strcmp(x, 'MT_detrend'), input_flags)==1);
input_arguments{MT_detrend_index} = validatestring(input_arguments{MT_detrend_index}, valid_MT_detrend);

% validity check
threshold_percentile_index = find(cellfun(@(x) strcmp(x, 'threshold_percentile'), input_flags)==1);
if input_arguments{threshold_percentile_index}<1 && strcmp(input_arguments{detection_method_index}, 'threshold')
    warning('The current threshold percentile is <1. If this was intentional disregard this message. Otherwise use a percentile between 1 and 100.');
end

% set the default find_freq_range
find_freq_range_index = find(cellfun(@(x) strcmp(x, 'find_freq_range'), input_flags)==1);
if isempty(input_arguments{find_freq_range_index})
    peak_freq_range = input_arguments{find(cellfun(@(x) strcmp(x, 'peak_freq_range'), input_flags)==1)};
    MT_taper = input_arguments{find(cellfun(@(x) strcmp(x, 'MT_taper'), input_flags)==1)};
    MT_window = input_arguments{find(cellfun(@(x) strcmp(x, 'MT_window'), input_flags)==1)};
    Fs = input_arguments{find(cellfun(@(x) strcmp(x, 'Fs'), input_flags)==1)};
    spectral_resol = MT_taper(1)*2 / MT_window(1);
    default_find_freq_range = [max(0, peak_freq_range(1)-spectral_resol), min(Fs/2, peak_freq_range(2)+spectral_resol)];
    input_arguments{find_freq_range_index} = default_find_freq_range;
end

% flip sleep_stages into a matrix with two columns
sleep_stages_index = find(cellfun(@(x) strcmp(x, 'sleep_stages'), input_flags)==1);
if size(input_arguments{sleep_stages_index},1) == 2
    input_arguments{sleep_stages_index} = input_arguments{sleep_stages_index}';
end

% smoothing in find_frequency_peaks shouldn't be wider than frequency range
smooth_Hz_index = find(cellfun(@(x) strcmp(x, 'smooth_Hz'), input_flags)==1);
peak_freq_range_index = find(cellfun(@(x) strcmp(x, 'peak_freq_range'), input_flags)==1);
if input_arguments{smooth_Hz_index} > 0
    warning('Direct smoothing in frequency domain is not recommended. Consider using multitaper parameters with wider spectral resolution to achieve spectral smoothing.')
end
assert(input_arguments{smooth_Hz_index} <= diff(input_arguments{peak_freq_range_index}), 'Smoothing is wider than the frequency range for detecting frequency peaks.')

end

function [ spect,stimes,sfreqs ] = compute_multitaper(EEG, Fs, MT_freq_max, MT_taper, MT_window, MT_min_NFFT, MT_detrend, verbose)
% set up parameters for computing the multitaper spectrogram
spectrogram_parameters.frequency_max = MT_freq_max;
spectrogram_parameters.taper_params = MT_taper;
spectrogram_parameters.window_params = MT_window;
spectrogram_parameters.min_NFFT = MT_min_NFFT;
spectrogram_parameters.detrend = MT_detrend;
spectrogram_parameters.ploton = false;
spectrogram_parameters.verbose = verbose;

% this is using the _release version of multitaper function. preraulab
% Github repo has the newest multitaper along with a compiled mex version.
% The newer version has flipped dimensions of spect and an additional input
% argument for taper weighting compared to the current _release version.
[spect,stimes,sfreqs]=multitaper_spectrogram_release(single(EEG'), Fs,...
    [0 min([Fs/2 spectrogram_parameters.frequency_max])], ...
    spectrogram_parameters.taper_params,spectrogram_parameters.window_params, ...
    spectrogram_parameters.min_NFFT, spectrogram_parameters.detrend, ...
    spectrogram_parameters.ploton, spectrogram_parameters.verbose);
end

function [ detection_inds, normalization_inds, stages_in_stimes ] = select_time_indices(stages_input, EEG, Fs, stimes, normalization_stages, detection_stages, ifartifact)
%stages_input should be in the format [time at change, new stage] as two
%long column vectors, i.e., each row is [time at change, new stage].
stages_in_stimes = interp1(stages_input(:,1), stages_input(:,2), stimes, 'previous');

%detects artifacts, changes those times to wake periods in stages_stimes
if ifartifact
    artifacts = EEG_detect_time_domain_artifacts(EEG, Fs, [], [], 35, [], 2);
    artifacts_times = 0:1/Fs:(length(EEG)-1)/Fs;
    artifacts_in_stimes = interp1(artifacts_times, double(artifacts), stimes, 'previous');
    stages_in_stimes(artifacts_in_stimes == 1) = 5;
end

%extracting the valid normalization times
normalization_inds = ismember(stages_in_stimes, normalization_stages);

%extracting the valid detection times
% stages: 1xN vector of stage values (0:Undefined, 5: Wake, 4:REM, 3:N1, 2:N2, 1:N3)
detection_inds = ismember(stages_in_stimes, detection_stages);
end

function [ fh ] = TF_peak_plot(spect, stimes, sfreqs, stages_in_stimes, tfpeak_table)
% create a figure to visualize multitaper spectrogram and detected TF peaks
fh = figure;
ax = figdesign(5,1, 'type','usletter', 'margins', [.05 .15 .05 .05 .03], 'merge',{2:5});
set(fh, 'units','normalized','position',[0 0 1 1]);
linkaxes(ax,'x'); % link x axes for zooming in/out
h_timetextstart = uicontrol('style', 'text', 'String', 'Window: ---', 'units', 'normalized', ...
    'Position', [0.0051    0.9677    0.17    0.0305], 'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'left');
l_timetext = addlistener(ax(2), 'XLim', 'PostSet', @(src,evnt)update_time_range(ax(2), h_timetextstart));

axes(ax(1)); % hypnogram 
hypnoplot(stimes, stages_in_stimes);
title('Hypnogram');
set(gca, 'FontSize', 16)

axes(ax(2)); % spectrogram
imagesc(stimes, sfreqs, nanpow2db(spect'));
axis xy;
climscale;
colormap jet;
title('Spectrogram');
xlabel('Time (sec)');
ylabel('Frequency (Hz)');
set(gca, 'xtick', []);
set(gca, 'FontSize', 16)

hold on;
% mark the detected TF peaks using bounding boxes
for ii = 1:size(tfpeak_table,1)
    pos = [ tfpeak_table.Start_Time(ii), tfpeak_table.Freq_Low(ii),...
        tfpeak_table.Duration(ii), tfpeak_table.Freq_High(ii)-tfpeak_table.Freq_Low(ii) ];
    r(ii) = rectangle('Position', pos,'LineStyle',':','EdgeColor','k','LineWidth',2);
end
set(fh,'KeyPressFcn',@(src,event)handle_keys(event, r));
update_time_range(ax(2), h_timetextstart);
scrollzoompan;
msgbox('Press ''v'' to toggle visibility of TF-Peak bounding boxes');

end

function update_time_range(ax, h_timetext)
% helper function to put date time into nice formats for display
time_range = xlim(ax);
df = datenum([0 0 0 0 0 1]);
h_timetext.String = ['Window: ', datestr(df*time_range(1), 'HH:MM:SS'), ' - ', ...
    datestr(df*time_range(2), 'HH:MM:SS')];
end

function [ tfpeak_table ] = create_output_tbl(stimes, stages_in_stimes, tfpeak_times, clustering_idx, clustering_prom_order, tpeak_center_times, tpeak_central_frequencies, tpeak_bandwidth_bounds, tpeak_proms)
% set up TF peak parameters for identified signal events 
start_time = tfpeak_times(:,1);
end_time = tfpeak_times(:,2);
candidate_spindle_index = clustering_idx == clustering_prom_order(1);
center_time = tpeak_center_times(candidate_spindle_index);
central_freq = tpeak_central_frequencies(candidate_spindle_index);
duration = end_time - start_time;
freq_low = tpeak_bandwidth_bounds(candidate_spindle_index,1);
freq_high = tpeak_bandwidth_bounds(candidate_spindle_index,2);
prom_value = tpeak_proms(candidate_spindle_index);
[~, stage_index] = ismember(center_time, stimes);
spindle_stage = stages_in_stimes(stage_index)';

% instantiate the table
var_names = {'Start_Time','End_Time','Max_Prominence_Time','Prominence_Value','Duration','Freq_Central','Freq_Low','Freq_High','Stage'};
tfpeak_table = table(start_time, end_time, center_time, prom_value, duration, central_freq, freq_low, freq_high, spindle_stage, 'VariableNames', var_names);

end

function ydB = nanpow2db(y)
% helper function to handle nan values for pow2db()
ydB = (10.*log10(y)+300)-300;
ydB(y(:)<=0) = nan;
end

function [] = handle_keys(event, rh)
% check for hotkeys pressed
switch lower(event.Character)
    case 'v'
        if strcmp(rh(1).Visible, 'on') || all(rh(1).Visible==1)
            set(rh, 'Visible', false);
        else
            set(rh, 'Visible', true);
        end
end
end
