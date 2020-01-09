% This script is used to query path/location coordinates from Google Maps
% API to obtain distance, elevation and additional information. This
% particular test script is used to query distance and elevation
% information for a vehicle drive test path.

%% Use Authentication Information
key = "AIzaSyA09fBytuZD51zbFASykzp9YZagjfrxQxM";   % Enter the GoogleAPI key
url_dist = "https://maps.googleapis.com/maps/api/distancematrix/"; % outputFormat?parameters'
url_elev = "https://maps.googleapis.com/maps/api/elevation/";
outputFormat = "json?";
param1 = "origins=";
param2 = "destinations=";
param3 = "key=";
param4 = "locations=";
param5 = "path=";
param6 = "samples=";
%% User Specified Information
cellNo = 3;

%% Loop Parameters
len_dist = length(GMapDat{1,cellNo}.coords);
%apiDatSet2 = zeros([len_dist 4]);

%% Passing Coordinates for Query
tic
for i = 1:1
    if i == 1
        qCoordDest = string(GMapDat{1,cellNo}.coords(1,:));
        str_elev = strcat(url_elev,outputFormat,param4,qCoordDest(1,1),",",...
            qCoordDest(1,2),"&",param3,key);
        tempelevdat = urlread(str_elev);
        elev_strct = jsondecode(tempelevdat);
        dist_strct.rows.elements.distance.value = 0;
    else
        qCoordOrig = string(GMapDat{1,cellNo}.coords(i-1,:));
        qCoordDest = string(GMapDat{1,cellNo}.coords(i,:));
        str_dist = strcat(url_dist,outputFormat,param1,qCoordOrig(1,1),",",...
            qCoordOrig(1,2),"&",param2,qCoordDest(1,1),",",qCoordDest(1,2),...
            "&",param3,key);
        str_elev = strcat(url_elev,outputFormat,param4,qCoordDest(1,1),",",...
            qCoordDest(1,2),"&",param3,key);
        tempdistdat = urlread(str_dist);
        tempelevdat = urlread(str_elev);
        dist_strct = jsondecode(tempdistdat);
        elev_strct = jsondecode(tempelevdat);
    end

    %% Saving required data in common matrix
%     apiDatSet2(i,1) = str2num(qCoordDest(1,1));     % Latitude
%     apiDatSet2(i,2) = str2num(qCoordDest(1,2));     % Longitude
%     apiDatSet2(i,3) = elev_strct.results.elevation; % Elevation in meters
%     apiDatSet2(i,4) = dist_strct.rows.elements.distance.value;   % Distance Delta in meters
%     pause(1)
end
toc