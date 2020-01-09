% Filter out the elevation data-points for distance delta less than 4 * Car
% Length. This value is nearly equal to 20m.

%% Setting up variables
sum = 0;
j = 1;
for i = 1:1357
    if i == 1
        RtFiltDat(j,:) = RouteData(i,1:4);
    else
        sum = sum + RouteData(i,4);
        if (sum > 20) 
            j = j + 1;
            RtFiltDat(j,:) = RouteData(i,1:4);
            sum = 0;
        end
    end           
end