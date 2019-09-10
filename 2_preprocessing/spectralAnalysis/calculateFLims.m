function [FLim_cpm] = calculateFLims(df, freqBands_hz)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Determines the frequency limits of brady-, normo- and tachy-
    %   gastria given the dominant frequency
    %
    %   INPUTS
    %   ===================================================================
    %   df                 :  (double) DF determined after ANOVA in R in cpm
    %   freqBands_hz       :  (1xn) vector of frequency bins in Hz
    %
    %   USAGE
    %   ===================================================================
    %   calculateFLims(9.1, 0.1:0.005:0.25)
    
    freqBands_cpm = freqBands_hz*60;
    bradyLim = df + ([-3,-1]);
    normoLim = df + ([-1,1]);
    tachyLim = df + ([1,3]);
    
    bradyLim(bradyLim<freqBands_cpm(1)) = freqBands_cpm(1);
    normoLim(normoLim<freqBands_cpm(1)) = freqBands_cpm(1);
    tachyLim(tachyLim<freqBands_cpm(1)) = freqBands_cpm(1);
    
    bradyLim(bradyLim>freqBands_cpm(end)) = freqBands_cpm(end);
    normoLim(normoLim>freqBands_cpm(end)) = freqBands_cpm(end);
    tachyLim(tachyLim>freqBands_cpm(end)) = freqBands_cpm(end);
    
    FLim_cpm = struct('bradyLim',bradyLim,'normoLim',normoLim,'tachyLim',tachyLim);
end
