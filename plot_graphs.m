% Read CSV file
filename = 'square_simulink_output.csv';  % change to your file name
data = readtable(filename);

% Extract variables
t = data.Time;

current_pos = [data.current_position_1, data.current_position_2, data.current_position_3];
error_pos   = [data.error_position_1, data.error_position_2, data.error_position_3];
controller  = [data.controller_1, data.controller_2, data.controller_3];

% Create figure
figure;

% Current position
tiledlayout(3,1)
nexttile
plot(t, current_pos)
title('Current Position')
xlabel('Time')
ylabel('Position')
legend('X','Y','Z')
grid on

% Error position
nexttile
plot(t, error_pos)
title('Error Position')
xlabel('Time')
ylabel('Error')
legend('X','Y','Z')
grid on

% Controller output
nexttile
plot(t, controller)
title('Controller Output')
xlabel('Time')
ylabel('Control Signal')
legend('1','2','3')
grid on