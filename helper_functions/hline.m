%HLINE  Draw a horizontal line
%
%   Usage:
%   [h] = hline(yvals)
%   [h] = hline(yvals, width)
%   [h] = hline(yvals, width, color)
%   [h] = hline(yvals, width, color, style)
% 
%   Input:
%   yvals: y coordinate(s) of line (scalar or vector)
%   width: width of line
%   color: color of line
%   style: line style
% 
%   Output:
%   h: handle for line
% 
%   Example:
%         % Create a new figure
%         figure;
%         % Draw a thick red line at x=1
%         h=hline([-1 3 4.2],3,'r','--');
%
%   See also hline, line
%
%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Michael Prerau
%   
%   Last modified 9/21/2011
%% ***********************************************************************

function h=hline(yvals, width, color,style)
if nargin==1
    width=1;
    color='k';
    style='-';
elseif nargin==2
    color='k';
    style='-';
elseif nargin==3
    style='-';
end

hold on;
h=line(xlim,[yvals(:) yvals(:)], 'linewidth',width,'color',color,'linestyle',style);