% Anonymous function handles used for feature extraction

NumWins = @(signalLen_min, winLen, winDisp) floor((signalLen_min-winLen)/(winDisp))+1;
LLfn = @(y)  sum(abs(y(2:end)-y(1:(end-1))));
Afn = @(y)  sum(abs(y));
Efn = @(y)  sum(y.^2);
ZXfn = @(y)  sum((y(1:(end-1))-mean(y)<0) & (y(2:end)-mean(y)>0));

