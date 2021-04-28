function clim_h = clims(ax)
% CLIMS - Launches a gui for scaline color axes
%
%   Usage:
%       clim_h = clims(ax)
%
%   Input:
%       ax: handle to axis -- required (default: gca)
%
%   Output:
%       clim_h: handle to the clim figure
%
%   Example:
%      ax = gca;
%      imagesc(peaks(500);
%      clims;
%
%
%   Copyright 2021 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%********************************************************************

if nargin==0
    ax=gca;
end

%Create the position interaction figure
clim_h = figure('Position',[1329         897         350         130],...
    'MenuBar','none','NumberTitle','off',...
    'Name','Adjust Color Limits');

if length(ax)==1
clims=get(ax,'clim');
else
    clims=get(ax(1),'clim');
end

bound=(clims(2)-clims(1))/2-.0001;

%Create the sliders
minslider_h = uicontrol(clim_h,'units','pixel','Style','slider',...
    'Max',clims(1)+bound,'Min',clims(1)-bound,'Value',clims(1),...
    'SliderStep',[0.05 0.2],...
    'Position',[25 75 300 20]);
maxslider_h = uicontrol(clim_h,'units','pixel','Style','slider',...
    'Max',clims(2)+bound,'Min',clims(2)-bound,'Value',clims(2),...
    'SliderStep',[0.05 0.2],...
    'Position',[25 25 300 20]);

sliders=[maxslider_h minslider_h];

%Create the edit boxes for manual entry of parameter values
minedit_h=uicontrol(gcf,'units','pixel','Style','edit','string',get(maxslider_h,'value'),'Position',[120 47 70 20],'backgroundcolor',get(gcf,'color'),'horizontalalign','right');
maxedit_h=uicontrol(gcf,'units','pixel','Style','edit','string',get(minslider_h,'value'),'Position',[120 97 70 20],'backgroundcolor',get(gcf,'color'),'horizontalalign','right');

%Array of all edit box handles
editboxes=[maxedit_h minedit_h];

%Set continuous callbaxs for the sliders
addlistener(maxslider_h,'ContinuousValueChange',@(src,evnt)slider_update(sliders,editboxes,ax));
addlistener(minslider_h,'ContinuousValueChange',@(src,evnt)slider_update(sliders,editboxes,ax));

uicontrol(gcf,'units','pixel','Style','text','string','Clim Max','Position',[25 45 100 20],'backgroundcolor',get(gcf,'color'),'horizontalalign','left');
uicontrol(gcf,'units','pixel','Style','text','string','Clim Min','Position',[25 95 100 20],'backgroundcolor',get(gcf,'color'),'horizontalalign','left');

%Set the edit box callbacks
set(maxedit_h,'callback',@(src,evnt)edit_update(sliders,editboxes,ax));
set(minedit_h,'callback',@(src,evnt)edit_update(sliders,editboxes,ax));





function slider_update(sliders,editboxes,ax)
maxval=get(sliders(1),'value');
minval=get(sliders(2),'value');

if maxval<=get(sliders(2),'value')
    maxval=get(sliders(2),'value')+1e-10;
end

if minval>=get(sliders(1),'value')
    minval=get(sliders(1),'value')-1e-10;
end

clims=[minval maxval];

% disp(clims);
set(ax,'clim',clims);
set(editboxes(1),'string',num2str(clims(1)));
set(editboxes(2),'string',num2str(clims(2)));


function edit_update(sliders,editboxes,ax)
%Get the new value from the edited text box
minval=str2double(get(editboxes(1),'string'));
maxval=str2double(get(editboxes(2),'string'));

if maxval<=get(sliders(2),'value')
    maxval=get(sliders(2),'value')+.001;
end

if minval>=get(sliders(1),'value')
    minval=get(sliders(1),'value')-.001;
end

clims=[minval maxval];

if maxval>get(sliders(1),'max')
    set(sliders(1),'max',maxval,'value',maxval);
elseif maxval<get(sliders(1),'min')
    set(sliders(1),'min',maxval,'value',maxval);
end

if minval>get(sliders(2),'max')
    set(sliders(2),'max',minval,'value',minval);
elseif minval<get(sliders(2),'min')
    set(sliders(2),'min',minval,'value',minval);
end

set(sliders(1),'value',maxval);
set(sliders(2),'value',minval);
set(editboxes(1),'string',minval);
set(editboxes(2),'string',maxval);
set(ax,'clim',clims);


