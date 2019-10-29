function [] = createBipolarEGGobj(trialObj,chanPairs)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Generates bipolar pair objects for all possible EGG bipolar pairs 
    %
    %   INPUTS
    %   ===================================================================
    %   trialObj    :   MDF object for trial to be processed
    %   paddleMap   :   nx2 cell array where columns are EGG channels to
    %                   difference
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    numCombos = size(chanPairs,1);
    summaryObj = mdf.load('mdf_type','summary','subject',trialObj.subject);
    if ~isempty(setdiff(chanPairs, summaryObj.EGG.label))
        error('invalid channel pairs')
    end
    
    bipolarObj_template = mdfObj;
    bipolarObj_template.type = 'bipolarEGG';
    bipolarObj_template.md.subject = trialObj.subject;
    bipolarObj_template.md.trial = trialObj.trial;
    bipolarObj_template.md.chan1 = [];
    bipolarObj_template.md.chan2 = [];
    bipolarObj_template.md.chanLabel = [];
    bipolarObj_template.md.fs = 2e3;
    
    bipolarPairLabels = cell(1,numCombos);
    for iCombo = 1:numCombos
        pairLabel = sprintf('%02d-%02d',chanPairs(iCombo,1),chanPairs(iCombo,2));
        
        if ismember(trialObj.trialType, {'rec', 'emetine','euthasol', 'rec_postop','rec_awake', 'feeding', 'post_feeding', 'pre_feeding', 'emetine_awake', 'feeding_stim','water_awake'})
            for iSeg = 1:trialObj.getLen('segments')
                segObj = trialObj.segments(iSeg);
                
                if isempty(mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','bipolarEGG','chanLabel',pairLabel,'segment',segObj.segment))
                    fprintf('Processing segment %d bipolar pair %s\n', iSeg, pairLabel)
                    chan1 = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','egg','EGGlabel',chanPairs(iCombo,1),'segment',segObj.segment);
                    chan2 = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','egg','EGGlabel',chanPairs(iCombo,2),'segment',segObj.segment);
                    
                    bipolarObj = bipolarObj_template.clone;
                    bipolarObj.setFiles(fullfile('<DATA_BASE>',segObj.subject,'bipolarEGG',sprintf('Trial%02d_seg%02d_ch%s',segObj.trial, segObj.segment, pairLabel)));
                    bipolarObj.md.chan1 = chanPairs(iCombo,1);
                    bipolarObj.md.chan2 = chanPairs(iCombo,2);
                    bipolarObj.md.chanLabel = pairLabel;
                    bipolarObj.md.segment = segObj.segment;
                    
                    bipolarObj.data.wf = chan1.data.wf-chan2.data.wf;
                    bipolarObj.data.time = chan1.data.time;
                    bipolarObj.save;

                    mdf.addParentChildRelation(chan1, bipolarObj,'bipolarEGG');
                    mdf.addParentChildRelation(chan2, bipolarObj,'bipolarEGG');
                    mdf.addParentChildRelation(segObj, bipolarObj, 'bipolarEGG');
                    segObj.save;
                    chan1.save;
                    chan2.save;
                    bipolarObj.save;

                else
                    fprintf('bipolar pair %s already created\n', pairLabel)
                end
            end

        else
            if ismember(trialObj.trialType, {'stim', 'pauli_stim','stim_postop', 'stim_awake', 'balloon', 'palpate'})
                
                if isempty(mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','bipolarEGG','chanLabel',pairLabel))
                    fprintf('Processing trial %d, bipolar pair %s\n', trialObj.trial, pairLabel)
                    chan1 = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','egg','EGGlabel',chanPairs(iCombo,1));
                    chan2 = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','egg','EGGlabel',chanPairs(iCombo,2));

                    bipolarObj = bipolarObj_template.clone;
                    bipolarObj.setFiles(fullfile('<DATA_BASE>',trialObj.subject,'bipolarEGG',sprintf('Trial%02d_ch%s',trialObj.trial, pairLabel)));
                    bipolarObj.md.chan1 = chanPairs(iCombo,1);
                    bipolarObj.md.chan2 = chanPairs(iCombo,2);
                    bipolarObj.md.chanLabel = pairLabel;

                    bipolarObj.data.wf = chan1.data.wf - chan2.data.wf;
                    bipolarObj.data.time = chan1.data.time;
                    bipolarObj.save;

                    mdf.addParentChildRelation(chan1, bipolarObj,'bipolarEGG');
                    mdf.addParentChildRelation(chan2, bipolarObj,'bipolarEGG');
                    mdf.addParentChildRelation(trialObj, bipolarObj, 'bipolarEGG');

                    trialObj.save;
                    chan1.save;
                    chan2.save;
                    bipolarObj.save;
                else
                    fprintf('bipolar pair %s already created\n', pairLabel)
                end
            else
                error('invalid trial type')
            end
        end
        bipolarPairLabels{iCombo} = pairLabel;
    end
    summaryObj.md.seChans = unique(chanPairs);
    summaryObj.md.bipolarPairLabels = bipolarPairLabels;
    summaryObj.save;
    disp('Finished creating bipolar objects')
end