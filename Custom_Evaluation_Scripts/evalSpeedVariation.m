% This script generates variations in speed trace obtained from Google API
% for evaluation.

%% Variations in sigma and delta
sigma = [0.25, 0.5, 0.75, 1];       % standard deviation
delta = [2, 5, 10];                % miles per hour

for i = 1:length(delta)
    for j = 1:length(sigma)
        [~, Nov202019181621.var_spd_mph(:,((i-1) * length(sigma)) + j)] = ...
            randomizeDrive(Nov202019181621.time_s,Nov202019181621.spd_mph,...
            sigma(j), delta(i),'limit');
    end
end
