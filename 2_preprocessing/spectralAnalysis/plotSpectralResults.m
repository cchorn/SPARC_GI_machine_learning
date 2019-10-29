function [] = plotSpectralResults(result_md, result, varargin)

    %   DESCRIPTION
    %   ===================================================================
    %   Generates summary report including raw signal, PSD bar plots and
    %   waterfall plots for each input signal. 
    %   See analyzeSignalFeatures.m for details on inputs
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    varargin = sanitizeVarargin(varargin);
    DEFINE_CONSTANTS
    save_figure = false;
    END_DEFINE_CONSTANTS

    if isempty(fieldnames(result))
        error('Empty result argument. Check inputs to function...')
    end
    subject = result_md.subject;
    trialnum = result_md.trial;
    trialType = result_md.trialType;
    chanLabel = result_md.chanLabel;
    chanLoc = result_md.chanLocation;
    fs = result_md.fs;
    trialObj = mdf.load('mdf_type','trial','subject',subject,'trial',trialnum);
    winStart = result.winFeat.winStart;
    wf = result.wf;
    freqBands_Hz = result.winFeat.freqBins;
    wfLen = length(wf);
    time = linspace(0,wfLen/fs,wfLen)/60;
    [evt, evtLabel] = getAllEvents(trialObj);
    
    targetWinIdx = winStart<=result.winFeat.lastWinStart;
    spectroMat = result.winFeat.wf_spectroPower(:,targetWinIdx)*10^-6;
    
%%     plot results
    
    h = figure;
    subplot(2,4,1:2)
    hold on
    plot(time, wf,'k')
    for iEvt = 1:length(evt)
        line([evt; evt], [min(wf) max(wf)]/2,'LineWidth',1.5)
    end
    legend({'wf',evtLabel{:}})
    xlabel('Time (min)')
    axis tight
    
    subplot(2,4,5:6)
    plotPSDbars((result.FFT))
    
    subplot(2,4,[3,4,7,8])
    plotWaterfall(spectroMat, winStart, freqBands_Hz)
    zLim = get(gca,'zlim');
    for iEvt = 1:length(evt)
        line([6,6],[evt; evt], [0 zLim(2)],'LineWidth',1.5)
    end
    suptitle(sprintf('Subject: %s; Trial: %d (%s), Paddle: %s (%s)', subject, trialnum, trialType, chanLabel,chanLoc))
    set(h,'Position',[404 309 1200 572])
    drawnow
    
    if save_figure
        saveas(h, fullfile('R:\users\amn69\Projects\ferret\manuscript_draft\tempEPS',sprintf('%s_%s_%d_%s.eps', subject, trialType, trialnum, chanLabel)),'epsc')
    end
    
    
%%     Time domain analysis results

%         DF = freqBands_Hz(:,maxPowerIdx);
%         h3 = figure;
%         subplot(4,1,1)
%         hold on
%         plot(time, wf)
%         axis tight
%         subplot(4,1,2)
%         plot(winStart+0.5,DF*60)
%         xlim([0 winStart(end)+1])
%         ylim([5, 20])
%         ylabel('DF (cpm)')
%         subplot(4,1,3)
%         plot(winStart+0.5,totPower)
%         xlim([0 winStart(end)+1])
%         ylabel('total power')
%         subplot(4,1,4)
%         bar(winStart+0.5,[result.winFeat.lineLen/max(result.winFeat.lineLen);...
%             result.winFeat.area/max(result.winFeat.area);...
%             result.winFeat.energy/max(result.winFeat.energy);...
%             result.winFeat.zeroX/max(result.winFeat.zeroX);]')
%         xlim([0 winStart(end)+1])
%         ylabel('normalized T features')
%         legend('LL', 'A', 'E', 'ZX')
%         title(paddleLabels)
%         set(h3,'Position',[604 309 810 572])

end