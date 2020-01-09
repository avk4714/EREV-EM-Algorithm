function [time, spd] = randomizeDrive(in_time, in_spd, sigma, delta, randType, distType)
% RANDOMIZEDRIVE This function generates a random drive pattern.
% SUMMARY The function is designed to take a drive cycle (time, speed) and
% generate a randomized speed pattern around that subjected to standard
% deviation from the input speed and bounds on the speed variation.

%% - Check missing input arguments -
    if ~exist('distType','var')
        distType = 'normal';    % Defaults to normal distribution
    end
    if ~exist('randType','var')
        randType = 'simple';    % simple: Defaults to randomizing about the input speed
                                % limit: Creates a band within which any
                                % speed is possible
    end
    if ~exist('delta','var')    % speed delta from the average
        delta = 2;
    end
%% Actual logic                                
    sz = length(in_time);
    switch randType
        case 'simple'
            for i = 1:sz
                pd = makedist(distType,'mu',in_spd(i),'sigma',sigma);
                spd(i,1) = random(pd);
            end
        case 'limit'
            %delta = 10;          % Speed in mph
            ul = in_spd + delta;
            ll = in_spd - delta;
            ll(ll < 0) = 0;
            init_spd = in_spd(1);
            for i = 2:sz
                pd = makedist(distType,'mu',init_spd,'sigma',sigma);
                nSpd = random(pd);
                ctr = 10;
                while(nSpd < ll(i) || nSpd > ul(i))
                    nSpd = random(pd);
                    ctr = ctr - 1;
                    if ctr == 0
                        init_spd = (init_spd + in_spd(i))*0.5;
                        pd = makedist(distType,'mu',init_spd,'sigma',sigma);
                        nSpd = random(pd);
                        ctr = 10;
                    end
                end
                spd(i,1) = nSpd;
                init_spd = spd(i,1);
            end
    end
    time = in_time;
end
