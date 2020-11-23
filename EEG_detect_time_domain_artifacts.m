function [artifacts, hf_artifacts, bb_artifacts, high_detrend, broad_detrend] = EEG_detect_time_domain_artifacts(data, Fs, method, hf_crit, hf_pass, bb_crit, bb_pass, smooth_duration, verbose, histogram_plot)
%EEG_DETECT_TIME_DOMAIN_ARTIFACTS  Detect artifacts in the time domain by iteratively removing data above a given z-score criterion
%
%   Usage:
%   Direct input:
%   artifacts = detect_time_domain_artifacts(data, Fs, hf_crit, hf_pass, bb_crit, bb_pass, smooth_duration, verbose, histogram_plot)
%
%   Input:
%   data: 1 x <number of samples> vector - time series data-- required
%   Fs: double - sampling frequency in Hz  -- required
%   method: string 'std' to use iterative method (default) or a strict threshold on 'MAD',defined as K*MEDIAN(ABS(A-MEDIAN(A)))
%   hf_crit: double - high frequency criterion - number of stds/MAD above the mean to remove (default: 4)
%   hf_pass: double - high frequency pass band - frequency for high pass filter in Hz (default: 25 Hz)
%   bb_crit: double - broadband criterion - number of stds/MAD above the mean to remove (default: 4)
%   bb_pass: double - broadband pass band - frequency for high pass filter in Hz (default: .1 Hz)
%   smooth_duration: double - time (in seconds) to smooth the time series (default: 2 seconds)
%   verbose: logical - verbose output (default: false)
%   histogram_plot: logical - plot histograms for debugging (default: false)
%
%   Output:
%   artifacts: 1xT logical of times flagged as artifacts (logical OR of hf and bb artifacts)
%   hf_artifacts: 1xT logical of times flagged as high frequency artifacts
%   bb_artifacts: 1xT logical of times flagged as broadband artifacts
%
%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Mingjian He, Michael Prerau 
%% ***********************************************************************
%Force column vector for uniformity
if ~iscolumn(data)
    data=data(:);
end

%Force to double for filtfilt
if ~isa(data,'double')
    data = double(data);
end

if nargin<2
    error('Data vector and sampling rate required');
end

if nargin < 3 || isempty(method)
    method = 'median';
end

if nargin < 4 || isempty(hf_crit)
    hf_crit = 4;
end

if nargin < 5 || isempty(hf_pass)
    hf_pass = 25;
end

if nargin < 6 || isempty(bb_crit)
    bb_crit = 4;
end


if nargin < 7 || isempty(bb_pass)
    bb_pass = .1;
end

if nargin < 8 || isempty(smooth_duration)
    smooth_duration = 2;
end

if nargin < 9 || isempty(verbose)
    verbose = false;
end

if nargin < 10 || isempty(histogram_plot)
    histogram_plot = false;
end

switch lower(method)
    case {'median', 'std'}
        mstring = 'STDs';
    case {'outlier', 'mad'}
        mstring = 'MADs';
    otherwise
        error('Bad method');
end

if verbose
    disp('Performing artifact detection:')
    disp(['     High Frequency Criterion: ' num2str(hf_crit) ' ' mstring ' above the mean']);
    disp(['     High Frequency Passband: ' num2str(hf_pass) ' Hz']);
    disp(['     Broadband Criterion: ' num2str(bb_crit) ' ' mstring ' above the mean']);
    disp(['     Broadband Passband: ' num2str(bb_pass) ' Hz']);
    disp('    ');
end

%% Create filters
hpFilt_high = designfilt('highpassiir','FilterOrder',8, ...
    'PassbandFrequency',hf_pass,'PassbandRipple',0.2, ...
    'SampleRate',Fs);

hpFilt_broad = designfilt('highpassiir','FilterOrder',8, ...
    'PassbandFrequency',bb_pass,'PassbandRipple',0.2, ...
    'SampleRate',Fs);

%% Get bad indicies
%Get bad indices
bad_inds = (isnan(data) | isinf(data) | find_flat(data));

%Interpolate big gaps in data
t = 1:length(data);
data_fixed = interp1([0, t(~bad_inds), length(data)+1], [0; data(~bad_inds); 0], t)';

%% Get high frequency artifacts
[ hf_artifacts, high_detrend ] = compute_artifacts(hpFilt_high, hf_crit, data_fixed, smooth_duration, Fs, bad_inds, verbose,...
    'high frequency', histogram_plot, method);

%% Get broad band frequency artifacts
[ bb_artifacts, broad_detrend ] = compute_artifacts(hpFilt_broad, bb_crit, data_fixed, smooth_duration, Fs, bad_inds, verbose,...
    'broadband frequency', histogram_plot, method);

%% Join artifacts from different frequency bands 
artifacts = hf_artifacts | bb_artifacts;
% sanity check before outputting
assert(length(artifacts) == length(data), 'Data vector length is inconsistent. Please check.')


%Compute zscore but robust to NAN vlaues
function z = nanzscore(x)
z = x - nanmedian(x);
z = z ./ nanstd(z);

%Find all the flat areas in the data
function binds = find_flat(data, min_size)
if nargin<2
    min_size = 100;
end

%Get consecutive values equal values
[clen, cind] = getchunks(data);

%Return indices
if isempty(clen)
    inds = [];
else
    size_inds = clen>=min_size;
    clen = clen(size_inds);
    cind = cind(size_inds);
    
    flat_inds = cell(1,length(clen));
    
    for ii = 1:length(clen)
        flat_inds{ii} = cind(ii):(cind(ii)+(clen(ii)-1));
    end
    
    inds = cat(2,flat_inds{:});
end

binds = false(size(data));
binds(inds) = true;

function [ detected_artifacts, y_detrend ] = compute_artifacts(filter_coeff, crit, data_fixed, smooth_duration, Fs, bad_inds, verbose, verbosestring, histogram_plot, method)
%% Get artifacts for a particular frequency band

%Perform a high pass filter
filt_data = filtfilt(filter_coeff, data_fixed);

%Look at the data envelope
y_hilbert = abs(hilbert(filt_data));

%Smooth data
y_smooth = movmean(y_hilbert, smooth_duration*Fs);

% We should smooth then take log
y_log = log(y_smooth);

%Spline detrend data
y_detrend = spline_detrend(y_log, Fs, [], 300)';

% Set bad indices to nan before z-scoring
y_signal = y_detrend;
y_signal(bad_inds) = nan;

%Take z-score
y_signal = nanzscore(y_signal);

if verbose
    num_iters = 1;
    disp(['Running ', verbosestring, ' detection...']);
end

if histogram_plot
    figure
    set(gca,'nextplot','replacechildren');
    histogram(y_signal,100);
    title(['Iteration: ' num2str(num_iters)]);
    pause(.5)
end

switch lower(method)
    case {'median', 'std'}
        %Keep removing until all values under criterion
        while any(abs(y_signal)>crit)
            y_signal(abs(y_signal)>crit) = nan;
            
            y_signal = nanzscore(y_signal);
            
            if verbose
                num_iters = num_iters + 1;
            end
            
            if histogram_plot
                histogram(y_signal,100);
                title(['Iteration: ' num2str(num_iters)]);
                pause(.5)
            end
        end
        
        if verbose
            disp(['     Ran ' num2str(num_iters) ' iterations']);
        end
    case {'outlier', 'mad'}
        y_signal(isoutlier(y_signal,'thresholdfactor',crit)) = nan;
        
        if histogram_plot
            histogram(y_signal,100);
            title('Outliers Removed');
        end
    otherwise
        error('Invalid method');
end

detected_artifacts = isnan(y_signal);
