function hand_scoring_TFpeaks(data, Fs, stages)
%TFSIGMA PEAK HANDSCORING - Plot and handscore TF peaks on multitaper spectrograms     
%   
%   This is a lite-version of TFsigma peak hand scoring function used to
%   manually identify TFsigma peaks on multitaper spectrograms. 
%
%   Usage: 
%       hand_scoring_TFpeaks(data, Fs, stages)
%   
%   Inputs:
%       data:   1 x <number of samples> vector - time series data -- required
%       Fs:     double - sampling frequency in Hz  -- required
%       stages: 1 x <number of stage samples> vector - vector of scored
%               sleep stages. The interval can be different from that of
%               data, but it should start and end matching the data vector.  
%
%   Hotkeys:
%       There are several useful hotkeys to facilitate scoring once the
%       multitaper spectrogram is plotted: 
%   
%       backspace/delete: delete selected bounding box
%       space: advance forward in time window (with 10% overlapping)
%       s: after pressing s, left-clicking on the spectrogram will begin
%       marking the bounding box as a TFpeak
%       u: after pressing u, left-clicking on the spectrogram will begin
%       marking the bounding box as an unknown event
%       p: call the zooming panel
%       c: call the colorscale adjustment panel
%       
%   Labels:
%       Saving and loading of labelled events can be done using the Labels
%       tab on the toolbar menu. Select the corresponding menu action to
%       save or load handscored events. 
%   
%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Michael Prerau
%% ***********************************************************************
frequency_range = [.5 25];
taper_params = [2 3];
min_NFFT = 2^10;
window_params = [1 .1];
detrend_opt = 'constant';
plot_on=false;
verbose = true;

[spect, stimes, sfreqs]=multitaper_spectrogram_release(data, Fs, frequency_range, taper_params, window_params, min_NFFT, detrend_opt, plot_on, verbose);
t=(1:length(data))/Fs;

%Create figure
f=figure('color','w');%,'visible','off');
ax=figdesign(7,1,'merge',{1:2, 3:6},'margins',[.05,.1,.05,.05,.05]);

axes(ax(1))
hypnoplot((1:length(data)/length(stages):length(data))/Fs,stages);

%Plot image (spectrogram)
axes(ax(2))
imagesc(stimes,sfreqs,pow2db(spect'));
axis xy
xbounds=stimes([1 end]);
ybounds=sfreqs([1 end]);
climscale;
colormap jet;
hline(9);
hline(17);

%Plot time domain
axes(ax(3))
plot(t,data);
axis tight

%Call event marker class to mark on the image
% obj=EventMarker(<axis>,<xbounds>,<ybounds>
em=EventMarker(ax(2),xbounds, ybounds);

%Add events
%obj.add_event_type(EventObject(<event type name>, <event ID>, <region? vs. point>, <bounded to yaxis?>)
em.add_event_type(EventObject('Spindle',1,true,false));
em.add_event_type(EventObject('Unsure',2,true,false));

%Add the main and label axes to the axis vector
ax = [ax(:); em.main_ax; em.label_ax];
linkaxes(ax,'x');
%Scroll axes
scrollzoompan(ax);

set(f,'KeyPressFcn',@(src,event)handle_keys(event,em),'units','normalized','position',[0 0 1 1],'visible','on');

%Make menu item to put in fixed time scale
m=uimenu('Label','Markers');
%Change the time scale
uimenu(m,'Label','Save Events...','callback',@(src,evnt)em.save,'accelerator','s');
uimenu(m,'Label','Load Events...','callback',@(src,evnt)em.load,'accelerator','s');

handles.spect = spect;
handles.stimes = stimes;
handles.sfreqs = sfreqs;
handles.hfig = gcf;
handles.ax = ax;

guidata(gcf, handles);
end

%************************************************************
%                      HANDLE HOTKEYS
%************************************************************

function handle_keys(event, em)
switch event.Key
    case {'backspace','delete'}
        em.delete_selected;
    case {'space'}
        cur_window = xlim;
        cur_size = diff(xlim);
        xlim([cur_window(2)-cur_size*0.1, cur_window(2)+cur_size*0.9]);
end

%Check for hotkeys pressed
switch lower(event.Character)
    case 's'
        em.mark_event(1);
    case 'u'
        em.mark_event(2);
    case 'p'
        zoom_popout();
    case 'c'
        handles = guidata(gcf);
        axes(handles.ax(2));
        clims;
end
end

function zoom_popout()
handles = guidata(gcf);
xl = xlim(handles.ax(2));

stimes = handles.stimes;
sfreqs = handles.sfreqs;
sinds = stimes>xl(1) & stimes<xl(2);

figure
surface(stimes(sinds), sfreqs, pow2db(handles.spect(sinds,:))','edgecolor','none');
xlabel('Times (s)');
ylabel('Frequency (Hz)');
zlabel('Power (dB)');
colormap(jet)
climscale;
view(3);
climscale;
camlight left
camlight right
material dull
lighting phong
shading interp
end
