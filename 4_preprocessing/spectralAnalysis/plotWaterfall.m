function [] = plotWaterfall(spectroPower, winStart, freqBands_Hz)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Generates a waterfall plot for the input spectrogram
    %
    %   INPUTS
    %   ===================================================================
    %   spectroPower    :  (nxm) spectrogram array for n time windows and m
    %                            frequency bins
    %   freqBands_Hz    :  (1xp) vector of frequency bins in Hz
    %   winStart        :  (1xn) array of spectrogram window start times
    %
    
    spectroPower(1,:) = 0;
    spectroPower(end,:) = 0;
    prevMean = 1000;
    prevFeat = zeros(1,size(spectroPower,2));
    for iWin = 1:size(spectroPower,2)
        currentMean = mean(spectroPower(:,iWin));
        if  currentMean > 10*prevMean
          for iFreq = 1:length(spectroPower(:,iWin))                % find offending value and dampen
              if spectroPower(iFreq,iWin) > 10*prevFeat(iFreq)
                  spectroPower(iFreq,iWin) = prevFeat(iFreq);
              end
          end
        end
        prevFeat = spectroPower(:,iWin);
        prevMean = currentMean;
    end
    
    tmp = zeros(size(spectroPower));
    hold on
    for i = 1:size(spectroPower,2)
        fill3(freqBands_Hz*60, winStart(i)*ones(size(freqBands_Hz)),spectroPower(:,i),[spectroPower(:,i)/max(spectroPower(:,i))])
%         tmp(:,i) = spectroPower(:,i)/max(spectroPower(:,i));
    end
%     imagesc(tmp)
%     set(gca,'XTickLabel',0:2.5:20)
%     set(gca,'YTick',1:31, 'YTickLabel',freqBands_Hz*60)
%     xlabel('time (min)')
%     ylabel('Frequency (cpm)')
    
    xlabel('Frequency (cpm)')
    ylabel('Time (min)')
    axis tight
    grid on
    set(gca, 'View',[23 44])
end