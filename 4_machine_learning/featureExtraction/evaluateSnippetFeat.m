function [wf] = evaluateSnippetFeat(subject, trialnum, signalType, snippetState, windowRange_min, varargin) 
    
    %   DESCRIPTION
    %   ===================================================================
    %   Analyzes all features specified in featureFunctions for signal
    %   source
    %
    %   INPUTS
    %   ===================================================================
    %   subject         :  (string) subject name
    %   trialnum        :  (numeric) trial number
    %   signalType      :  (string) emg/se/bp/CA/PA/bPA
    %   snippetState    :  (numeric) 1xn array where n-1 is the number of
    %                       windows in windowRange and elements are 1:5
    %   windowRange_min :  (numeric) array with winStarts to segment
    %                       signal source; [15 25]
    %
    %   OPTIONAL INPUTS
    %   ===================================================================
    %   freqBands_Hz        :  (1xn) frequencies for spectrogram
    %
    %   NOTE
    %   ===================================================================
    %   possible signal sources are se, se-CA, se-PA, bp, bp-CA, bp-PA, PA,
    %   bPA, emg
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    varargin = sanitizeVarargin(varargin);
    DEFINE_CONSTANTS
    freqBands_Hz = (6:0.3:15)/60;
    END_DEFINE_CONSTANTS
    
    % init DB
    if ismember(subject, {'43-17','14-18','16-18','13-18','15-18','29-18','32-18','34-18'})
        mdf.init(3);      
    elseif ismember(subject, {'40-18','37-18','48-18'})
        mdf.init(4)
    else
        error('Invalid trial type')
    end
    
    % signal source
    summaryObj = mdf.load('subject',subject,'mdf_type','summary');
    if strcmp('PA',signalType)
        chanLabel = summaryObj.md.paddleLabels{:};
    elseif strcmp('bPA',signalType)
        chanLabel = summaryObj.md.paddlePairLabels{:};
    end
    
    featureFunctions();

    for iChan = 1:length(chanLabel)
        stomachLocation = getChannelLocation(subject, chanLabel{iChan});
        fprintf('Subject: %s; Trial: %d, %s: (%s)\n', subject, trialnum, chanLabel{iChan}, stomachLocation)
        
        resultObj = mdf.load('mdf_type','result','subject',subject,'trial',trialnum,'signalType',signalType,'chanLabel',chanLabel{iChan});
        DF = resultObj.FFT.baseline.DF;
        
        [wf, fs] = getSignalSourceWF(subject, trialnum, signalType, chanLabel(iChan), 'referenceWf', resultObj.referenceWf, 'artifact_subtract', resultObj.artifact_subtract, 'filter_signal', resultObj.filter_signal);
        
        wfLen_min = length(wf)/fs/60;  
        if length(snippetState) == 1 && isempty(windowRange_min)
            windowRange_min = [0 wfLen_min];
        end
        
        % evaluate features
        snip_spectroPower = resultObj.winFeat.wf_spectroPower(:,1:2:end);
        snipStart = resultObj.winFeat.winStart(1:2:end);
        snipWf = resultObj.winFeat.winSnips(:,1:2:end);
%         [snip_spectroPower, snipStart, snipWf] = MovingWinFeats(wf, fs, 'spectro', 'freqBins', freqBands_Hz);
%         plotWaterfall(snip_spectroPower, snipStart, freqBands_Hz)
                
        flims = calculateFLims(DF, freqBands_Hz);
        
        bradyLim = flims.bradyLim;
        normoLim = flims.normoLim;
        tachyLim = flims.tachyLim;
        
        stateLabel = zeros(1,length(snipStart));
        for iState = 1:length(snippetState)
            stateMask = windowRange_min(iState,1) <= snipStart & snipStart < windowRange_min(iState,2);
            stateLabel(stateMask) = snippetState(iState);
        end
        
        freqBins = freqBands_Hz*60;
        bradybin = bradyLim(1) <= freqBins  & freqBins < bradyLim(2);
        normobin = normoLim(1) <= freqBins  & freqBins < normoLim(2);
        tachybin = tachyLim(1) <= freqBins  & freqBins < tachyLim(2);
        
        resCell = struct;
        resCell.bradyPercent = sum(snip_spectroPower(bradybin,:))./sum(snip_spectroPower);
        resCell.normoPercent = sum(snip_spectroPower(normobin,:))./sum(snip_spectroPower);
        resCell.tachyPercent = sum(snip_spectroPower(tachybin,:))./sum(snip_spectroPower);
        resCell.DP = max(snip_spectroPower)./sum(snip_spectroPower);
        [~, idx] = max(snip_spectroPower);
        resCell.DF = freqBands_Hz(idx)*60;
        
        tmpLL = MovingWinFeats(wf, fs, LLfn);
        resCell.lineLen = tmpLL/median(tmpLL);
        tmpA = MovingWinFeats(wf, fs, Afn);
        resCell.area = tmpA/median(tmpA);
        tmpE = MovingWinFeats(wf, fs, Efn);
        resCell.energy = tmpE/median(tmpE);
        tmpZx = MovingWinFeats(wf, fs, ZXfn);
        resCell.zeroX = tmpZx/median(tmpZx);
        
        featList = fieldnames(resCell);
        numFeats = length(featList);
        
        mdStruct = struct;
        mdStruct.subject = subject;
        mdStruct.trialnum = trialnum;
        mdStruct.chanLabel = chanLabel{iChan};
        mdStruct.referenceWf = resultObj.referenceWf;
        mdStruct.signalType = signalType;
        
        for iSnip = 1:length(snipStart)
            if stateLabel(iSnip) ~=0
                snip_md = mdStruct;
                snip_md.state = stateLabel(iSnip);
                snip_md.startT_min = snipStart(iSnip);
                snippetWf = snipWf(:,iSnip);

                parentObj = createSnippetObj(snip_md, snippetWf, iSnip);

                for iFeat = 1:numFeats
                    structField = featList{iFeat};

                    result_md = mdStruct;
                    result_md.startT_min = snipStart(iSnip);

                    result_md.signalType = signalType;                     % emg/se/bp/CA/PA/bPA
                    result_md.location = stomachLocation;                  % A/F/D/AF/FD/DA
                    result_md.state = stateLabel(iSnip);                   % 1/2/3/4/5 => rest/distended/subthresh/early emetine/late emetine
                    result_md.feature = iFeat;                             % 1/2/3/4/5/6/7/8/9  => bradyPercent/normoPercent/tachyPercent/DP/DF/LL/A/E/ZX
                    result_md.featVal = resCell.(structField)(iSnip);

                    childObj = createFeatureObj(result_md, iSnip);
%                     mdf.addParentChildRelation(parentObj, childObj, 'features');
%                     childObj.save;
%                     parentObj.save;
                end
            end
        end
    end
end
