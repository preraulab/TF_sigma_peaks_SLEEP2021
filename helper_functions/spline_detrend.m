%SPLINE_DETREND  A fast spline fit detrending for removing the DC component in EEG data
%
%   Usage:
%   detrended=spline_detrend(eegdata, Fs)
%   detrended=spline_detrend(eegdata, Fs, num_knots)
%
%   Input:
%   eegdata: <channels>x<samples> matrix of eeg data
%   Fs: sampling rate in Hz
%   num_knots: number of spline knots to use in the detrending (default one every 2 minutes)
%
%   Output:
%   detrended: <channels>x<samples> matrix of detrended data
%
%   Example:
%         %Create sample AR1 process
%         Fs=500;
%         N=Fs*60*10; %10 min of data
%         t=(1:N)/Fs;
%         eegdata=zeros(1,N);
%         eegdata(1)=0;
%         for i=2:N
%             eegdata(i)=eegdata(i-1)+randn;
%         end
% 
%         %Detrend the data
%         detrended=spline_detrend(eegdata, Fs);
% 
%         %Plot the data
%         hold on
%         plot(t,eegdata);
%         plot(t,detrended,'r','linewidth',2);
%         xlabel('Time (s)');
% 
%         legend('Original','Detrended');
%
%   See also visfilt_eeg, eeg_lowpass, eegfilt
%
%   Copyright 2011 Michael J. Prerau, Ph.D.
%
%   Last modified 02/10/2011
%********************************************************************
function detrended=spline_detrend(eegdata, Fs, num_knots, knot_spacing)
eegdata=eegdata(:)';

%Get eegdata length
N=length(eegdata);

%Make windows by default
if nargin<4
    knot_spacing=30;
end

if nargin<3 | isempty(num_knots)
    num_knots=N/(Fs*knot_spacing);
end

% Do not fit a spline to really short data
if N/Fs<=20
    warning('Data too short. Returning detrended data');
    detrended=detrend(eegdata);
    return;
end

%Allow for 2
num_knots=max(num_knots,1);

%Downsample at roughly one second, including endpoints
downsamp_x=round(linspace(1,N,round(N/Fs)));
downsamp_y=eegdata(downsamp_x);

%Compute spline fit
w = ones(size(downsamp_x)); %w([1 end]) = 1000;
spline_struct = spap2(num_knots,3,downsamp_x,downsamp_y,w);

%Detrend eegdata
detrended=eegdata-fnval(spline_struct,1:N);
