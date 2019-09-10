function [meanDF_cpm] = getWindowAverageDF(wfspectro, freqBand, winstart, winrange)

    %   DESCRIPTION
    %   ===================================================================
    %   Evaluates the average DF across multiple windows of a spectrogram
    %   using the frequency bin with the maximum power.
    %
    %   INPUTS
    %   ===================================================================
    %   wfspectro   :  (nxm) spectrogram array for n time windows and m
    %                        frequency bins
    %   freqBand    :  (1xp) vector of frequency bins in Hz
    %   winstart    :  (1xn) array of spectrogram window start times
    %   winrange    :  (1x2) start and stop times within which to calculate
    %                   DF
    %
    %   USAGE
    %   ===================================================================
    %   getWindowAverageDF(wf_spectroPower, freqBands_Hz, 0:20, [5,15])
    
    idx = winstart >= winrange(1) & winstart < winrange(2);
    temp_wf_spectroPower = wfspectro(:,idx);
    [~, idx] = max(temp_wf_spectroPower);
    meanDF_cpm = mean(freqBand(idx)*60);
    fprintf('averaged  DF: %0.1f\n', meanDF_cpm)
end