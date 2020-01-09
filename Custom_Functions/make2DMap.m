function map = make2DMap(xbptvec,ybptvec,xvalvec,yvalvec)
%MAKE2DMAP Summary of this function goes here
%   Detailed explanation goes here

%% Initialization

initMap = zeros([length(ybptvec) length(xbptvec)]);

%% Map formation

for i = 1:length(ybptvec)
    for j = 1:length(xbptvec)
        if ((i == 1) && (j == 1))
            ll_x = 0;
            ul_x = xbptvec(j);
            ll_y = 0;
            ul_y = ybptvec(i);
        elseif ((i == 1) && (j ~= 1))
            ll_x = xbptvec(j-1);
            ul_x = xbptvec(j);
            ll_y = 0;
            ul_y = ybptvec(i);
        elseif ((i ~= 1) && (j == 1))
            ll_x = 0;
            ul_x = xbptvec(j);
            ll_y = ybptvec(i-1);
            ul_y = ybptvec(i);
        else
            ll_x = xbptvec(j-1);
            ul_x = xbptvec(j);
            ll_y = ybptvec(i-1);
            ul_y = ybptvec(i);
        end
        
        idx1 = find((xvalvec(:,1) >= ll_x) & (xvalvec(:,1) ...
            <= ul_x));
        idx2 = find((yvalvec(:,1) >= ll_y) & (yvalvec(:,1) ...
            <= ul_y));
        
        [C,~,~] = intersect(idx1,idx2);
        
        if isempty(C)
            initMap(i,j) = NaN;
        else
            initMap(i,j) = mean(xvalvec(C,2));
        end
        
    end
end

map = initMap;

end

