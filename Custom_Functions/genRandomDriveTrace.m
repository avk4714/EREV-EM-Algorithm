init = 1;
lPt = init;
lPt1 = lPt;
lPt2 = lPt;
UL = 5;
LL = 0;
for k = 1:100
pd = makedist('Normal','mu',lPt,'sigma',1);
pd1 = makedist('Normal','mu',lPt1,'sigma',1);
pd2 = makedist('Normal','mu',lPt2,'sigma',1);
nPt = random(pd);
nPt1 = random(pd1);
while(nPt1 < LL || nPt1 > UL)
    nPt1 = random(pd1);
end
nPt2 = random(pd2);
scatter(k,nPt,'filled','b')
hold on
scatter(k,nPt1,'filled','r')
scatter(k,nPt2,'filled','g')
lPt = nPt;
lPt1 = nPt1;
lPt2 = nPt2;

end