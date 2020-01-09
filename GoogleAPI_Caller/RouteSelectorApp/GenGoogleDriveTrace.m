%           #### ROUTE SELECTOR APPLICATION SCRIPT ####
%           #### WRITTEN BY: Aman Ved Kalia        ####
%           #### LAST UPDATED: 11/25/2019          ####
%% GUI for User Origin and Destination Input

gui.prompt = {'[Origin]::Street/Location Name','City','State',...
                '[Destination]::Street/Location Name','City','State'};
gui.dlgtitle = 'Route Input';
gui.dims = [1 60;1 30;1 5;1 60;1 30;1 5];
gui.defInput = {'Mechanical Engineering Building','Seattle','WA',...
                'Seattle-Tacoma International Airport','Seattle','WA'};
            %gui.defInput = {'12026 32ND AVE NE','Seattle','WA',...
             %   'Mechanical Engineering Building','Seattle','WA'};
dlgout = inputdlg(gui.prompt,gui.dlgtitle,gui.dims,gui.defInput);
tempOrigin = strcat(dlgout{1, 1}," ",dlgout{2, 1}," ",dlgout{3, 1});
tempDest = strcat(dlgout{4, 1}," ",dlgout{5, 1}," ",dlgout{6, 1});
gui.strOrigin = strrep(tempOrigin,' ','+');
gui.strDest = strrep(tempDest,' ','+');

tic
%% Google API - Get Directions
[pathCoords, pathLength, pathDuration] = getDirections(gui.strOrigin,gui.strDest);
    % pathCoords is an N -by- 4 matrix where,
    %   [Column 1]: Start Latitude
    %   [Column 2]: Start Longitude
    %   [Column 3]: End Latitude
    %   [Column 4]: End Longitude
    % pathLength is an N -by- 1 vector where,
    %   [Column 1]: Distance in meters
    % pathDuration is an N -by- 1 vector where,
    %   [Column 1]: Duration in seconds
N = length(pathLength);

% - Make path vector with lat,long as columns
pathVector = zeros([N+1 2]);
for i = 1:N+1
    if i ~= N+1
        pathVector(i,:) = [pathCoords(i,1), pathCoords(i,2)];
    else
        pathVector(i,:) = [pathCoords(i-1,3), pathCoords(i-1,4)];
    end
end

%% Google API - Get Elevation

DIST_RES = 50;    % resolution in meters.
SAMPLE_VEC = zeros([N 1]);
SAMPLE_VEC = round(pathLength/DIST_RES);
% -- SAMPLE_VEC Breakdown 
% --- Due to the 100 point query limit, the SAMPLE_VEC values and vector
% --- size is readjusted
EX_LIM = find(SAMPLE_VEC > 100);
SAMPLE_VEC(EX_LIM) = 100;
% ---
QUERY_COORDS = zeros([2 2]);
% --- 
FinalPath.lat = [];
FinalPath.lng = [];
FinalPath.elev = [];

for i = 1:N
    QUERY_COORDS(1,:) = pathCoords(i,1:2);
    QUERY_COORDS(2,:) = pathCoords(i,3:4);
    if i == 1
        [FinalPath.lat, FinalPath.lng, FinalPath.elev] = ...
            getElevation(QUERY_COORDS,SAMPLE_VEC(i),'path');
    else
        [temp_lat, temp_lng, temp_elev] = ...
            getElevation(QUERY_COORDS,SAMPLE_VEC(i),'path');
        FinalPath.lat = [FinalPath.lat(1:end-1); temp_lat];
        FinalPath.lng = [FinalPath.lng(1:end-1); temp_lng];
        FinalPath.elev = [FinalPath.elev(1:end-1); temp_elev];
    end  
end


%% Google API - Snap to Road (multiple requests)

MAX_PATH_LEN = 100;
N_FINALPATH = length(FinalPath.lat);
ctr = 1;
while(ctr < N_FINALPATH)
    if (N_FINALPATH - ctr + 1) > MAX_PATH_LEN
        snappedData = snap2road(FinalPath.lat(ctr:(ctr - 1 + MAX_PATH_LEN)),...
            FinalPath.lng(ctr:(ctr - 1 + MAX_PATH_LEN)));
    else
        snappedData = snap2road(FinalPath.lat(ctr:N_FINALPATH),...
            FinalPath.lng(ctr:N_FINALPATH));
    end
    SNPD_LEN = length(snappedData.snappedPoints);
    if ctr == 1
        for k = 1:SNPD_LEN
            SnappedPath.lat(k,1) = snappedData.snappedPoints(k).location.latitude;
            SnappedPath.lng(k,1) = snappedData.snappedPoints(k).location.longitude;
        end
    else
        for k = 1:SNPD_LEN
            tempSnpd.lat(k,1) = snappedData.snappedPoints(k).location.latitude;
            tempSnpd.lng(k,1) = snappedData.snappedPoints(k).location.longitude;
        end
        SnappedPath.lat = [SnappedPath.lat; tempSnpd.lat];
        SnappedPath.lng = [SnappedPath.lng; tempSnpd.lng];
    end
    ctr = ctr + MAX_PATH_LEN;
end

N_SNPDPATH = length(SnappedPath.lat);
%% Google API - Get Distance
 % - need to work on this
%{
DIST_QUERY = zeros([2 2]);
pathDist = zeros([N_FINALPATH 1]);
for j = 2:N_FINALPATH
    DIST_QUERY(1,:) = [FinalPath.lat(j-1), FinalPath.lng(j-1)];
    DIST_QUERY(2,:) = [FinalPath.lat(j), FinalPath.lng(j)];
    pathDist(j) = pathDist(j-1) + getDistanceMat(DIST_QUERY,"walking");
end
%}
%% Google API - Get Speed and Generate Speed Trace
avgPathSpd_mps = pathLength./pathDuration;
% Initialize output vector
gmapSpeedTrace.time_s = 0;
gmapSpeedTrace.spd_mps = 0;
gmapSpeedTrace.dist_m = 0;
% Loop
ctr = 1;
for k = 1:N
    if k == 1
        gmapSpeedTrace.time_s = [gmapSpeedTrace.time_s; pathDuration(k)];
        gmapSpeedTrace.spd_mps = [gmapSpeedTrace.spd_mps; avgPathSpd_mps(k)];
        gmapSpeedTrace.dist_m = [gmapSpeedTrace.dist_m; pathLength(k)];
    else
        gmapSpeedTrace.time_s = [gmapSpeedTrace.time_s; gmapSpeedTrace.time_s(end) + 0.01; gmapSpeedTrace.time_s(end) + pathDuration(k)];
        gmapSpeedTrace.spd_mps = [gmapSpeedTrace.spd_mps; avgPathSpd_mps(k); avgPathSpd_mps(k)];
        gmapSpeedTrace.dist_m = [gmapSpeedTrace.dist_m; gmapSpeedTrace.dist_m(end); gmapSpeedTrace.dist_m(end) + pathLength(k)];
    end
end
toc 
%% Plotting

dataTime = string(datetime);


figure(1)
plot(SnappedPath.lng,SnappedPath.lat,'.b','MarkerSize',10)
plot_google_map
hold on
plot(FinalPath.lng,FinalPath.lat,'.g','MarkerSize',10)
plot_google_map
plot(pathVector(:,2),pathVector(:,1),'.r','MarkerSize',15)
plot_google_map
title(dataTime)
xlabel('Longitude')
ylabel('Latitude')
hold off


figure(2)
plot(gmapSpeedTrace.time_s, gmapSpeedTrace.spd_mps, 'linewidth', 2)
%hold on
%plot(FinalPath.elev
grid on
xlabel('Duration [seconds]')
ylabel('Average Speed [m/s]')
title(dataTime)
makePublishable(0)

figure(3)
%yyaxis left
plot(gmapSpeedTrace.dist_m * 0.001, gmapSpeedTrace.spd_mps, 'linewidth', 2)
ylabel('Average Speed [m/s]')
%yyaxis right
%plot(pathDist * 0.000621371, FinalPath.elev * 3.28084, 'linewidth', 1.5)
%ylabel('Elevation (above Sea Level) [ft]')
grid on
xlabel('Distance [km]')
title(dataTime)
makePublishable(0)

%% Save Drive Trace for Simulation
t_decimation = 1;       % 1 = 1 second, 10 = 0.1 second
CUSTOM_STRCT_NAME = [];
pt1 = char(dataTime);
CUSTOM_STRCT_NAME = strcat(string(pt1(4:6)),string(pt1(1:2)),...
    string(pt1(8:11)),string(pt1(13:14)),string(pt1(16:17)),...
    string(pt1(19:20)));

% Metadata section
temp.metadata.origin = tempOrigin;
temp.metadata.destination = tempDest;
temp.metadata.datetime = dataTime;

% Drive Trace data section
temp.time_s(:,1) = linspace(gmapSpeedTrace.time_s(1),...
    gmapSpeedTrace.time_s(end),(gmapSpeedTrace.time_s(end) * t_decimation) + 1);
temp.spd_mph = interp1(gmapSpeedTrace.time_s,gmapSpeedTrace.spd_mps,temp.time_s) * 2.2369 ;
temp.dist_mi = interp1(gmapSpeedTrace.time_s,gmapSpeedTrace.dist_m,temp.time_s) * 0.000621371;



% Randomize drive trace
[rand_time_s,rand_speed_mph] = randomizeDrive(temp.time_s,temp.spd_mph,0.25,5,'limit','normal');
% sigma = 0.5 <- old

temp.rand_spd_mph = rand_speed_mph;

eval([char(CUSTOM_STRCT_NAME),' = temp;'])

figure(4)
plot(gmapSpeedTrace.time_s, gmapSpeedTrace.spd_mps, 'linewidth', 2)
hold on
plot(rand_time_s, rand_speed_mph * 0.44704, 'linewidth', 2)
grid on
xlabel('Duration [seconds]')
ylabel('Average Speed [m/s]')
title(dataTime)
makePublishable(0)


%% Save data
pname = "/Users/amankalia/Documents/MATLAB/DocResWork/Simulation_Models/PreDrive_DP_Optimization/RouteSelectorApp/Google_Drive_Traces/";
fname = strcat(CUSTOM_STRCT_NAME,'.mat');
cname = strcat(pname,fname);
save(cname,CUSTOM_STRCT_NAME)

clear temp





