function [legCoords, legDist, legDuration] = getDirections(origin,destination)
%GETDIRECTIONS Uses Google API to obtain directions.
%   This function uses the Origin and Destination coordinates to obtain
%   "Driving" directions from Google API.

%% Function Test Case Parameter
% origin = "12026+32ND+AVE+NE+Seattle+WA";
% destination = "Rhein+Haus+Seattle+Seattle+WA";

%% Function Body

key = "AIzaSyA09fBytuZD51zbFASykzp9YZagjfrxQxM";   % Enter the GoogleAPI key
url_dist = "https://maps.googleapis.com/maps/api/directions/"; % outputFormat?parameters'
trafficModelType = "best_guess";
depTime = "now";
outputFormat = "json?";
param1 = "origin=";
param2 = "destination=";
param3 = "key=";
param4 = "traffic_model=";
param5 = "departure_time=";
%% Compute Direction
str_dist = strcat(url_dist,outputFormat,param1,origin,...
            "&",param2,destination,"&",param5,depTime,"&",...
            param4,trafficModelType,"&",param3,key);
tempdirdat = webread(str_dist);
%dir_strct = jsondecode(tempdirdat);
legLength = length(tempdirdat.routes.legs.steps);
legCoords = zeros([legLength 4]);
legDist = zeros([legLength 1]);
legDuration = zeros([legLength 1]);
for i = 1:legLength
    legCoords(i,1) = tempdirdat.routes.legs.steps{i, 1}.start_location.lat;
    legCoords(i,2) = tempdirdat.routes.legs.steps{i, 1}.start_location.lng;
    legCoords(i,3) = tempdirdat.routes.legs.steps{i, 1}.end_location.lat;
    legCoords(i,4) = tempdirdat.routes.legs.steps{i, 1}.end_location.lng;
    legDist(i,1) = tempdirdat.routes.legs.steps{i, 1}.distance.value;   % unit is meters
    legDuration(i,1) = tempdirdat.routes.legs.steps{i, 1}.duration.value;     % unit is seconds
end
end

