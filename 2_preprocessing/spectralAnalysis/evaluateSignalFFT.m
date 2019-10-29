function [X_mags, fax_Hz, DP, PSD] = evaluateSignalFFT(signal, fs, flim)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Evaluates the FFT and the power spectral density in the normo,
    %   brady and tachy gastria frequency bands
    %
    %   INPUTS
    %   ===================================================================
    %   signal   :  (1xn) GMA waveform
    %   fs       :  (double) sampling frequency
    %   flim     :  (struct) brady, normo and tachy frequency ranges
    %
    %   USAGE
    %   ===================================================================
    %   evaluateSignalFFT(wf, 2e3, baseline.F_lims)
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    N = length(signal);    
    X_mags = abs(fft(signal)); % [signal.*hann(N); zeros(10000-N,1)]
    bin_vals = [0 : N-1];
    fax_Hz = bin_vals*fs/N;
    N_2 = ceil(N/2);
    
    freqBands_cpm = (6:0.3:15);
    freqBands_Hz = freqBands_cpm/60;
    
    tempDF = zeros(size(freqBands_Hz));
    for p = 1:length(freqBands_Hz)-1
        freqIdx = fax_Hz(1:N_2)>freqBands_Hz(p) & fax_Hz(1:N_2)<freqBands_Hz(p+1);
        tempDF(p) = sum(X_mags(freqIdx));
    end
    [DP,idx] = max(tempDF);
%     figure; subplot(2,1,1); plot(signal); subplot(2,1,2); plot(freqBands_Hz*60, tempDF)   % plot(fax_Hz(1:N/2)*60, X_mags(1:N/2))
%     fprintf('averaged_method 2 DF: %0.1f\n', DF)
    
    bradyLim = flim.bradyLim;
    normoLim = flim.normoLim;
    tachyLim = flim.tachyLim;
    
    PSD = struct;
    PSD.brady = sum(X_mags(fax_Hz*60 > bradyLim(1) &  fax_Hz*60 <= bradyLim(2)).^2);
    PSD.normo = sum(X_mags(fax_Hz*60 > normoLim(1) &  fax_Hz*60 <= normoLim(2)).^2);
    PSD.tachy = sum(X_mags(fax_Hz*60 > tachyLim(1) &  fax_Hz*60 <= tachyLim(2)).^2);
    PSD.total = PSD.brady + PSD.normo + PSD.tachy;
    
end