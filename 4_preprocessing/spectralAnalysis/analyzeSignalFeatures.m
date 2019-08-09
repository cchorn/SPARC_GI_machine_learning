function [wf_out, res_out] = analyzeSignalFeatures(mode, subject, trialList, signalType, referenceWf, varargin)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Analyzes all features specified in featureFunctions for signal
    %   source
    %
    %   INPUTS
    %   ===================================================================
    %   subject         :  (string) subject name
    %   trialList       :  (cell) cell array of trial types
    %   signalType      :  (string) emg/se/bp/CA/PA/bPA
    %   referenceWf     :  (string) CA/PA default none
    %
    %   OPTIONAL INPUTS
    %   ===================================================================
    %   
    %   freqBands_Hz        :  (1xn) frequencies for spectrogram
    %   fs                  :  (int) sampling frequency;
    %   artifact_subtract   :  (bool) remove artifacts
    %   filter_signal       :  (bool) high pass filters and downsample
    %
    %   NOTE
    %   ===================================================================
    %   possible signal sources are se, se-CA, se-PA, bp, bp-CA, bp-PA, PA,
    %   bPA, emg
    %
    %   USAGE
    %   ===================================================================
    %   analyzeSignalFeatures('analyze','43-17',{'rec','balloon','emetine'},'PA','CA')
    %   analyzeSignalFeatures('analyze','14-18',{'rec','balloon','emetine'},'PA','CA')
    %   analyzeSignalFeatures('analyze','16-18',{'rec','balloon','emetine'},'PA','CA')
    %   analyzeSignalFeatures('analyze','13-18',{'rec','balloon','emetine'},'PA','CA', 'artifact_subtract', true)
    %   analyzeSignalFeatures('analyze','15-18',{'rec','balloon','emetine'},'bPA','none')
    %   analyzeSignalFeatures('analyze','29-18',{'rec','balloon','emetine'},'PA','CA')
    %   analyzeSignalFeatures('analyze','32-18',{'rec','balloon','emetine'},'PA','CA')
    %   analyzeSignalFeatures('analyze','34-18',{'rec','balloon','emetine'},'PA','CA','filter_signal',false)
    %
    %   analyzeSignalFeatures('analyze','43-17',{'rec','balloon','emetine'},'bPA','none')
    %   analyzeSignalFeatures('analyze','14-18',{'rec','balloon','emetine'},'bPA','none')
    %   analyzeSignalFeatures('analyze','16-18',{'rec','balloon','emetine'},'bPA','none')
    %   analyzeSignalFeatures('analyze','13-18',{'rec','balloon','emetine'},'bPA','none', 'artifact_subtract', true)
    %   analyzeSignalFeatures('analyze','15-18',{'rec','balloon','emetine'},'PA','CA')
    %   analyzeSignalFeatures('analyze','29-18',{'rec','balloon','emetine'},'bPA','none')
    %   analyzeSignalFeatures('analyze','32-18',{'rec','balloon','emetine'},'bPA','none')
    %   analyzeSignalFeatures('analyze','34-18',{'rec','balloon','emetine'},'bPA','none','filter_signal',false)
    
    %   analyzeSignalFeatures('debug','40-18',{'rec_awake','feeding','emetine_awake','water_awake'},'PA','CA')
    %   analyzeSignalFeatures('debug','37-18',{'rec_awake','feeding','emetine_awake','water_awake'},'PA','CA')
    %   analyzeSignalFeatures('debug','48-18',{'feeding','emetine_awake','water_awake'},'PA','CA')

    varargin = sanitizeVarargin(varargin);
    DEFINE_CONSTANTS
    freqBands_Hz = (6:0.3:15)/60;
    artifact_subtract = false;
    filter_signal = true;
    save_figure = false;
    END_DEFINE_CONSTANTS
    
    % init DB
    if ismember(subject, {'43-17','14-18','16-18','13-18','15-18','29-18','32-18','34-18'})
        mdf.init(3);
        if any(~ismember(trialList, {'rec', 'balloon', 'emetine', 'stim'}))
            error('chutya')
        end      
    elseif ismember(subject, {'40-18','37-18','48-18'})
        mdf.init(4)
        if any(~ismember(trialList, {'rec_awake','feeding','emetine_awake','water_awake'}))
            error('chutya')
        end
    else
        error('Invalid trial type')
    end
    
    % trial numbers
    allTrials = getAllTrialtypeObjects(subject, trialList);
    trialnum = zeros(1,length(allTrials));
    for iTrial = 1:length(allTrials)
        trialnum(iTrial) = allTrials(iTrial).md.trial;
    end
%     trialnum = arrayfun(@(x) x.trial, allTrials);
    if strcmp(subject, '29-18')
        allTrials(trialnum == 6) = [];
        trialnum(trialnum == 6) = [];
    elseif strcmp(subject,'37-18')
        allTrials(trialnum == 66) = [];
        trialnum(trialnum == 66) = [];
    elseif strcmp(subject,'40-18')
        allTrials(trialnum == 38) = [];
        trialnum(trialnum == 38) = [];
    elseif strcmp(subject,'48-18')
        allTrials(trialnum == 39) = [];
        trialnum(trialnum == 39) = [];
    end
    numTrials = length(trialnum);

    % run mode
    if strcmp(mode,'analyze')
        eval_save_plot = [true, true, false];
    elseif strcmp(mode,'view')
         eval_save_plot = [false, false, true];
    elseif strcmp(mode,'debug')
         eval_save_plot = [true, false, true];
    else
        error('Invalid analysis params')
    end

    % signal source
    summaryObj = mdf.load('subject',subject,'mdf_type','summary');
    if strcmp('PA',signalType)
        chanLabel = summaryObj.md.paddleLabels{:};
    elseif strcmp('bPA',signalType)
        chanLabel = summaryObj.md.paddlePairLabels;
    elseif strcmp('emg',signalType)
        chanLabel = summaryObj.md.EMG.label(:);
    elseif strcmp('CA', signalType)
        chanLabel = 'CA';
    elseif strcmp('bp', signalType)
        chanLabel = summaryObj.bipolarPairLabels;
    end
        
    wf_out = cell(numTrials,length(chanLabel));
    res_out = cell(numTrials,length(chanLabel));
    
    for iTrial = 1:numTrials
        
        trialObj = allTrials(iTrial);  % mdf.load('subject',subject,'trial',trialnum,'mdf_type','trial');
        trialType = trialObj.trialType;

        for iChan = 1:length(chanLabel)        
            chanLoc = getChannelLocation(subject, chanLabel{iChan});
            fprintf('Subject: %s; Trial: %d, %s: (%s)\n', subject, trialnum(iTrial), chanLabel{iChan}, chanLoc)

            result_md = struct;
            result_md.subject = subject;
            result_md.trial = trialnum(iTrial);
            result_md.trialType = trialType;
            result_md.signalType = signalType;
            result_md.chanLabel = chanLabel{iChan};
            result_md.chanLocation = chanLoc;
            result_md.referenceWf = referenceWf;
            result_md.artifact_subtract = double(artifact_subtract);
            result_md.filter_signal = double(filter_signal);

            result = struct;
            if eval_save_plot(1)
                [wf, fs] = getSignalSourceWF(subject, trialnum(iTrial), signalType, chanLabel(iChan), 'referenceWf', referenceWf,'artifact_subtract',artifact_subtract, 'filter_signal',filter_signal);
                result.wf = wf;
                result_md.fs = fs;  

                % evaluate frequency domain features             
                result.winFeat = struct;
                result.FFT = struct;
                result.winFeat.freqBins = freqBands_Hz;
                [result.winFeat.wf_spectroPower , result.winFeat.winStart, result.winFeat.winSnips] = MovingWinFeats(wf, fs, 'spectro', 'freqBins', freqBands_Hz,'overlap_min',0.5);

                if ismember(trialType,{'rec','rec_awake'})
                    result.FFT.baseline.DF = getWindowAverageDF(result.winFeat.wf_spectroPower, freqBands_Hz, result.winFeat.winStart, [0 result.winFeat.winStart(end)]);
                    result.FFT.baseline.F_lims = calculateFLims(result.FFT.baseline.DF, freqBands_Hz);                
                    [result.FFT.baseline.xmag, result.FFT.baseline.f, result.FFT.baseline.DP, result.FFT.baseline.PSD] = evaluateSignalFFT(wf, fs, result.FFT.baseline.F_lims);
                    result.winFeat.lastWinStart = result.winFeat.winStart(end);

                else
                    [baseline_tmin, target_tmin] = getTimeRanges(trialObj);
                    result.winFeat.lastWinStart = target_tmin(end);

                    result.FFT.baseline.DF = getWindowAverageDF(result.winFeat.wf_spectroPower, freqBands_Hz, result.winFeat.winStart, baseline_tmin);
                    result.FFT.baseline.F_lims = calculateFLims(result.FFT.baseline.DF, freqBands_Hz);
                    baselineSnip = wf([baseline_tmin(1)*60*fs+1:baseline_tmin(2)*60*fs]);
                    [result.FFT.baseline.xmag, result.FFT.baseline.f, result.FFT.baseline.DP, result.FFT.baseline.PSD] = evaluateSignalFFT(baselineSnip, fs, result.FFT.baseline.F_lims);

                    result.FFT.target.DF = getWindowAverageDF(result.winFeat.wf_spectroPower, freqBands_Hz, result.winFeat.winStart, target_tmin);
                    wfSnip = wf([round(target_tmin(1)*60*fs):round(target_tmin(2)*60*fs)]);
                    [result.FFT.target.xmag, result.FFT.target.f, result.FFT.target.DP, result.FFT.target.PSD] = evaluateSignalFFT(wfSnip, fs, result.FFT.baseline.F_lims);


                end

            else
                queryStruct = result_md;
                if filter_signal
                    result_md.fs = 10;
                else
                    result_md.fs = 2e3;
                end
                queryStruct.mdf_type = 'result';
                resultObj = mdf.load(queryStruct);
                if ~isempty(resultObj)
                    result = resultObj.data;
                    wf = resultObj.data.wf;
                else
                    error('these set of parameters have not been used for analysis before')
                end
            end

            wf_out{iTrial, iChan} = wf;
            res_out{iTrial, iChan} = result;

            % save result as mdf object (untested)
            if eval_save_plot(2)            
                upsertResultObj(result_md, result);
            end

            if eval_save_plot(3)
                plotSpectralResults(result_md, result,'save_figure',save_figure);
            end

        end
    end
    disp('finished')
end


