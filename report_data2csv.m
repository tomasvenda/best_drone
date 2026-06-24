% Extract signals
ts_pos = out.current_position;
ts_ctrl = out.controller;
ts_err = out.error_position;

% Common time vector (assumes same length)
t = ts_pos.Time;

% Fix error_position shape: [3 x 1 x 497] -> [497 x 3]
err = squeeze(ts_err.Data);      % -> [3 x 497]
err = err.';                     % -> [497 x 3]

% Build table
T = table();

T.Time = t;

% current position (497x3)
T.current_position_1 = ts_pos.Data(:,1);
T.current_position_2 = ts_pos.Data(:,2);
T.current_position_3 = ts_pos.Data(:,3);

% controller (497x3)
T.controller_1 = ts_ctrl.Data(:,1);
T.controller_2 = ts_ctrl.Data(:,2);
T.controller_3 = ts_ctrl.Data(:,3);

% error position (fixed 497x3)
T.error_position_1 = err(:,1);
T.error_position_2 = err(:,2);
T.error_position_3 = err(:,3);

% Export
writetable(T, 'simulink_output.csv');