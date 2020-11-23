%Select the best row and column configuration for subplots
function [rows cols]=spconfig(num,landscape)
%
%   Copyright 2020 Michael J. Prerau, Ph.D. - http://www.sleepEEG.org
%   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
%   (http://creativecommons.org/licenses/by-nc-sa/4.0/)
%
%   Authors: Michael Prerau
%% ***********************************************************************
if nargin==1
    landscape=true;
end

switch num
    case 1
        rows=1;cols=1;
    case 2
        rows=1;cols=2;
    case 3
        rows=1;cols=3;
    case 4
        rows=2;cols=2;
    case 5
        rows=2;cols=3;
    case 6
        rows=2;cols=3;
    case 7
        rows=2;cols=4;
    case 8
        rows=2;cols=4;
    case 9
        rows=3;cols=3;
    case 10
        rows=2;cols=5;
    otherwise
        %Find the configuration that minimizes empty space
        %and maximizes squareness
        c=[1:ceil(sqrt(num));ceil(num./(1:ceil(sqrt(num))))];
        [~,ind]=min(diff(c)/2+2*(prod(c)-num));
        rows=min(c(:,ind));
        cols=max(c(:,ind));
end

%Flip row and column if portrait
if ~landscape
    temp=rows;
    rows=cols;
    cols=temp;
end
