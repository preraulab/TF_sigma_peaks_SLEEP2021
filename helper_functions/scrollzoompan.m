function [zslider, pslider, zl, pl]=scrollzoompan(ax,dir,zoom_fcn,pan_fcn, bounds)
%SCROLLZOOMPAN  Adds pan and zoom scroll bars to an axis
%               mouse wheel = pan, shift + mouse wheel = zoom
%
%   Usage:
%   [zslider, pslider]=scrollzoompan
%   [zslider, pslider]=scrollzoompan(ax)
%   [zslider, pslider]=scrollzoompan(ax, dir)
%   [zslider, pslider]=scrollzoompan(ax, dir, zoom_fcn, pan_fcn)
%
%   Input:
%   ax: Axis to zoom and pan (default: gca)
%   dir: Zoom/pan direction {'x','y'} (default: 'x')
%   zslider/pslider: Handles to slider object handles (default: creates at figure bottom)
%   zoom_fcn/pan_fcn: Handles to functions to be called on zoom or pan
%
%   Output:
%   zslider: Zoom slider handle
%   pslider: Pan slider handle
%
%   Example:
%
%     figure
%     axes('position',[.05 .15 .9 .8]);
%     plot(randn(1,1000));
%     scrollzoompan;
%
%     figure
%     axes('position',[.05 .15 .9 .8]);
%     imagesc(peaks(1000));
%     scrollzoompan(gca,'y');
%
%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Michael Prerau
%
%   Last modified 03/17/2015
%% ***********************************************************************
%Set default axes to current
if nargin==0
    ax=gca;
end

%Set default direction to x
if nargin<2
    dir=lower('x');
end

if nargin<3
    zoom_fcn=[];
end

if nargin<4
    pan_fcn=[];
end



%Get full data limits depending on direction
if strcmpi(dir,'x')
    xl=xlim(ax(1));   

    amin=xl(1);
    amax=xl(2);
else
    yl=xlim(ax(1));
    
    amin=yl(1);
    amax=yl(2);
end

%Impose bounds if defined
if nargin<5
    bounds=[nan nan];
end

if ~isnan(bounds(1))
    amin=bounds(1);
end

if ~isnan(bounds(2))
    amax=bounds(2);
end

handle=guidata(gcf);
handle.shift_down=false;
guidata(gcf,handle);

%Create zoom slider
zslider = uicontrol('style','slider','units','normalized','position',[.05 .025 .9 .025],'slider',[1 5]/amax,'min',amin,'max',amax,'value',amax);
pslider = uicontrol('style','slider','units','normalized','position',[.05 .055 .9 .025],'slider',[1 5]/amax,'min',amin,'max',amax,'value',(amax-amin)/2+amin,'sliderstep',(amax-amin)/amax*[.5 1]);

%Add listeners for continuous value changes
zl=addlistener(zslider,'ContinuousValueChange',@(src,evnt)zoom_slider(ax, zslider, pslider, dir,zoom_fcn));
pl=addlistener(pslider,'ContinuousValueChange',@(src,evnt)pan_slider(ax, pslider, dir,pan_fcn));
set(gcf,'WindowKeyPressFcn',{@handle_keys,ax, zslider, pslider, dir, zoom_fcn, pan_fcn},'WindowKeyReleaseFcn',@key_off);

set(gcf,'WindowScrollWheelFcn',{@figScroll,ax, zslider, pslider, dir, zoom_fcn, pan_fcn});

annotation(gcf,'textbox',...
    [0.0286396181384249 0.054140127388535 0.019689737470167 0.023416135881104],...
    'String',{'Pan'},...
    'FitBoxToText','off',...
    'LineStyle','none');

% Create textbox
annotation(gcf,'textbox',...
    [0.0238663484486874 0.0265392781316348 0.0238663484486873 0.023416135881104],...
    'String',{'Zoom'},...
    'FitBoxToText','off',...
    'LineStyle','none');


%***********************************************************
%***********************************************************
%                  SLIDER FUNCTIONS
%***********************************************************
%***********************************************************
%-----------------------------------------------------------
%           CALLBACK TO HANDLE TIME SCALE ZOOM
%-----------------------------------------------------------
function zoom_slider(ax, zslider, pslider, dir, zoom_fcn)
%Keep the window center with window width determined by slider value
newlims=get(pslider,'value')+(get(zslider,'value')-get(zslider,'min'))/2*[-1 1];

amin=get(zslider,'min');
amax=get(zslider,'max');

%Sets a minimum window width
if newlims(2)<=newlims(1)
    newlims(2)=newlims(1)+1e-10;
end

%Set sliderbounds so that you can't go past limits
if get(pslider,'value')-abs(diff(xlim(ax(1))))/2<amin
    newpos=amin+abs(diff(xlim(ax(1))))/2;
    set(pslider,'value', newpos);
    newlims(1)=amin;
elseif get(pslider,'value')+abs(diff(xlim(ax(1))))/2>amax
    newpos=amax-abs(diff(xlim(ax(1))))/2;
    set(pslider,'value', newpos);
    newlims(2)=amax;
end

%Compute the new limits
if strcmpi(dir,'x')
    set(ax,'xlim',newlims);
    set(pslider,'sliderstep',diff(xlim(ax(1)))/amax*[.5 1]);
else
    set(ax,'ylim',newlims);
    set(pslider,'sliderstep',diff(xlim(ax(1)))/amax*[.5 1]);
end

if ~isempty(zoom_fcn)
    feval(zoom_fcn);
end


%-----------------------------------------------------------
%           CALLBACK TO HANDLE TIME SCALE SCROLL
%-----------------------------------------------------------
function pan_slider(ax, pslider, dir, pan_fcn)
amin=get(pslider,'min');
amax=get(pslider,'max');

%Set the limits to the slider value center
if strcmpi(dir,'x')
    %Set sliderbounds so that you can't go past limits
    if get(pslider,'value')-abs(diff(xlim(ax(1))))/2<amin
        set(pslider,'value',amin+abs(diff(xlim(ax(1))))/2);
    elseif get(pslider,'value')+abs(diff(xlim(ax(1))))/2>amax
        set(pslider,'value',amax-abs(diff(xlim(ax(1))))/2);
    end
    
    set(ax, 'xlim', get(pslider,'value')+[-1 1]*abs(diff(xlim(ax(1))))/2);
else
    %Set sliderbounds so that you can't go past limits
    if get(pslider,'value')-abs(diff(xlim(ax(1))))/2<amin
        set(pslider,'value',amin+abs(diff(xlim(ax(1))))/2);
    elseif get(pslider,'value')+abs(diff(xlim(ax(1))))/2>amax
        set(pslider,'value',amax-abs(diff(xlim(ax(1))))/2);
    end
    set(ax, 'ylim', get(pslider,'value')+[-1 1]*abs(diff(xlim(ax(1))))/2);
end

if ~isempty(pan_fcn)
    feval(pan_fcn);
end

%-----------------------------------------------------------
%           CALLBACK TO HANDLE SCROLL WHEEL
%-----------------------------------------------------------
function figScroll(~,callbackdata,ax, zslider, pslider, dir, zoom_fcn, pan_fcn)
handle=guidata(gcf);

%Scroll if shift not pressed
if ~(handle.shift_down)
    amin=get(pslider,'min');
    amax=get(pslider,'max');
    if callbackdata.VerticalScrollCount > 0
        set(pslider,'value',min(get(pslider,'value')*(1+.025*callbackdata.VerticalScrollAmount),amax));
        pan_slider(ax, pslider, dir, pan_fcn);
    elseif callbackdata.VerticalScrollCount < 0
        set(pslider,'value',max(get(pslider,'value')*(1-.025*callbackdata.VerticalScrollAmount),amin));
        pan_slider(ax, pslider, dir, pan_fcn)
    end
%Zoom if shift is pressed
else
    amin=get(zslider,'min');
    amax=get(zslider,'max');
    if callbackdata.VerticalScrollCount > 0
        set(zslider,'value',max(get(zslider,'value')*(1-.025*callbackdata.VerticalScrollAmount),amin));
        zoom_slider(ax, zslider, pslider, dir, zoom_fcn);
    elseif callbackdata.VerticalScrollCount < 0
        set(zslider,'value',min(get(zslider,'value')*(1+.025*callbackdata.VerticalScrollAmount),amax));
        zoom_slider(ax, zslider, pslider, dir, zoom_fcn);
    end
end

%-----------------------------------------------------------
%           SCROLL AND ZOOM WITH KEYS
%-----------------------------------------------------------
function handle_keys(~,event,ax, zslider, pslider, dir, zoom_fcn, pan_fcn)
handle=guidata(gcf);

%Check if shift is bing pressed
handle.shift_down=(strcmpi(event.Key,'shift'));

switch event.Key
    %Scroll left
    case 'rightarrow'
        amax=get(pslider,'max');
        set(pslider,'value',min(get(pslider,'value')*(1+.025),amax));
        pan_slider(ax, pslider, dir, pan_fcn);
    %Scroll right    
    case 'leftarrow'
        amin=get(pslider,'min');
        set(pslider,'value',max(get(pslider,'value')*(1-.025),amin));
        pan_slider(ax, pslider, dir, pan_fcn)
    %Zoom in  
    case 'downarrow'
        amin=get(zslider,'min');
        set(zslider,'value',max(get(zslider,'value')*(1-.025),amin));
        zoom_slider(ax, zslider, pslider, dir, zoom_fcn);
    %Zoom out
    case 'uparrow'
        amax=get(zslider,'max');
        set(zslider,'value',min(get(zslider,'value')*(1+.025),amax));
        zoom_slider(ax, zslider, pslider, dir, zoom_fcn);
end

guidata(gcf,handle);

%-----------------------------------------------------------
%                TURN OFF SHIFT
%-----------------------------------------------------------
function key_off(~,~)
handle=guidata(gcf);
handle.shift_down=false;
guidata(gcf,handle);
