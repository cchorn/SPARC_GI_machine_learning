function [val_feature, windowStarts_min, sig_window] = MovingWinFeats(wf, fs, featFn, varargin)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Calculates windowed features for input signal
    %
    %   INPUTS
    %   ===================================================================
    %   wf          :  (string) subject name
    %   fs          :  (cell) cell array of trial types
    %   featFn      :  (string) emg/se/bp/CA/PA/bPA
    %
    %   OPTIONAL INPUTS
    %   ===================================================================
    %   windowSize_min  :   (int) window size in minutes
    %   overlap_min     :   (int) overlap duration in minutes
    %   freqBins        :   (1xn) vector of frequencies for spectrogram
    
    
    DEFINE_CONSTANTS
    windowSize_min = 1;
    overlap_min = 0;
    freqBins = (6:0.3:15)/60;
    END_DEFINE_CONSTANTS
    
    if strcmp(featFn,'spectro')
        valsPerWindow = length(freqBins);
    else
        valsPerWindow = 1;
    end
     
    windowSize_samples = round(windowSize_min*60*fs-1);
    duration_min = round(length(wf)/fs/60);
    winDisplace = windowSize_min - overlap_min;
    
    NumWins = @(signalLen_min, winLen, winDisp) floor((signalLen_min-winLen)/(winDisp))+1;
    numWindows = NumWins(duration_min, windowSize_min, winDisplace);
    windowStarts_min = (0:(windowSize_min-overlap_min):duration_min-windowSize_min);
    windowStarts_idx = round(windowStarts_min*60*fs+1);
    if windowStarts_idx(end) + windowSize_samples > length(wf)          % im okay with partial windows that are upto 50% of windowsize 
        windowStarts_idx = windowStarts_idx(1:end-1);                   % this check is necessary so there is no edge artifact due to short windows
        numWindows = numWindows-1;
        windowStarts_min = windowStarts_min(1:end-1);
    end
    
    sig_window = zeros(windowSize_samples+1, numWindows);
    val_feature = zeros(valsPerWindow, numWindows);
    
    for iWin = 1:numWindows
        signalWindow = wf(windowStarts_idx(iWin)+(0:windowSize_samples));
        sig_window(:,iWin) = signalWindow;

        if strcmp(featFn,'spectro')
            [val_feature(:,iWin), ~] = pwelch(signalWindow,length(signalWindow),0,freqBins,fs);
        else
            val_feature(:,iWin) = featFn(signalWindow);
        end
    end
end