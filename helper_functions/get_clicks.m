function pos = get_clicks(varargin)
if nargin == 0
    h_ax = gca;
    num_clicks = 1;
end

if nargin == 1
    h_ax = gca;
    num_clicks = varargin{1};
end

if nargin == 2
    h_ax =  varargin{1};
    num_clicks = varargin{2};
end

h_fig = h_ax.Parent;

pos = zeros(num_clicks, 2);

iptPointerManager(h_fig);
iptSetPointerBehavior(h_ax, @(hfig, currentPoint)set(hfig, 'Pointer', 'cross'));

clicks = 0;
while clicks<num_clicks
    w = waitforbuttonpress;
    if ~w
        clicks = clicks + 1;
        p = get(h_ax,'CurrentPoint');
        pos(clicks,:) = p(1,1:2);
    end
end

iptSetPointerBehavior(h_ax, @(hfig, currentPoint)set(hfig, 'Pointer', 'arrow'));

