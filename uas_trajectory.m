%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MIT License
% 
% Copyright (c) 2021 David Wuthier (dwuthier@gmail.com)
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialization
% close all
% clear
% clc

% Trajectory generation

knots = [0 40];
waypoints = cell(1,2);
waypoints{1} = [0 ; 0 ; 0.35];
waypoints{2} = [0 ; 0 ; 0.35];
% waypoints{2} = [9 ; 9 ; 1];
% Fix this...
order = 7;
corridors.times = [1 4];
corridors.x_lower = [-1 8];
corridors.x_upper = [1 10];
corridors.y_lower = [-1 8];
corridors.y_upper = [1 10];
corridors.z_lower = [0 0];
corridors.z_upper = [2 2];


corridors.times = 1:(size(route,1)-1);

margin = 0.2;

corridors.x_lower = min(route(1:end-1,1), route(2:end,1)) - margin;
corridors.x_upper = max(route(1:end-1,1), route(2:end,1)) + margin;

corridors.y_lower = min(route(1:end-1,2), route(2:end,2)) - margin;
corridors.y_upper = max(route(1:end-1,2), route(2:end,2)) + margin;

corridors.z_lower = min(route(1:end-1,3), route(2:end,3)) - margin;
corridors.z_upper = max(route(1:end-1,3), route(2:end,3)) + margin;

knots = linspace(0,50,size(route,1));

waypoints = cell(1,size(route,1));
for k = 1:size(route,1)
    waypoints{k} = route(k,:)';
end

% ...until here
make_plots = true;

poly_traj = uas_minimum_snap(knots, order, waypoints, corridors, make_plots);
