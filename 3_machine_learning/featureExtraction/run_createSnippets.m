function [] = run_createSnippets(subName)

    %   DESCRIPTION
    %   ===================================================================
    %   wrapper for evaluateSnippetFeat to generate and log signal features
    %   to MDF
    %   
    %   USAGE
    %   ===================================================================
    %   run_createSnippets('43-17')


    % rest snippets
    trialObj = mdf.load('subject',subName,'mdf_type','trial','trialType','rec');
%     evaluateSnippetFeat(subName, trialObj(1).md.trial, 'PA', 1, []);
    evaluateSnippetFeat(subName, trialObj(1).md.trial, 'bPA', 1, []);
    disp('finished baseline snippets')

    % distended snippets
    trialObj = mdf.load('subject',subName,'mdf_type','trial','trialType','balloon');
    if ~isempty(trialObj)
        for iTrial = 1:length(trialObj)
            tmpTrialObj = trialObj(iTrial);
            distendRange_min = tmpTrialObj.params.preInfusion+tmpTrialObj.params.rampUp+[0, tmpTrialObj.params.hold];
            distendBase_min = [0, tmpTrialObj.params.preInfusion];

%             evaluateSnippetFeat(subName, tmpTrialObj.trial, 'PA', 2, distendRange_min);
            evaluateSnippetFeat(subName, tmpTrialObj.trial, 'bPA', 2, distendRange_min);

%             evaluateSnippetFeat(subName, tmpTrialObj.trial, 'PA', 6, distendBase_min);                
            evaluateSnippetFeat(subName, tmpTrialObj.trial, 'bPA', 6, distendBase_min);
        end
    end
    disp('finished distension snippets')
    disp(datetime)

    % early and late emetine snippets
    trialObj = mdf.load('subject',subName,'mdf_type','trial','trialType','emetine');
    if ~isempty(trialObj)
        for iTrial = 1:length(trialObj)
            tmpTrialObj = trialObj(iTrial);

            emetineBase_min = [0,tmpTrialObj.md.annotations.infusionStart_sec/60];
            infusionT_min = tmpTrialObj.md.annotations.infusionEnd_sec/60;
            retchT_min = tmpTrialObj.md.annotations.retching_sec(1)/60;
            retchInterval_min = retchT_min-infusionT_min;

            if retchInterval_min < 30
                early_timeRange_min = infusionT_min+[0, retchInterval_min/2];
                late_timeRange_min = infusionT_min+[retchInterval_min/2, retchInterval_min];
            else
                early_timeRange_min = infusionT_min+[0, 15];
                late_timeRange_min = retchT_min+[-15, 0];
            end

%             evaluateSnippetFeat(subName, tmpTrialObj.trial, 'PA', 7, emetineBase_min);
            evaluateSnippetFeat(subName, tmpTrialObj.trial, 'bPA', 7, emetineBase_min);

%             evaluateSnippetFeat(subName, tmpTrialObj.trial, 'PA', 4, early_timeRange_min);
            evaluateSnippetFeat(subName, tmpTrialObj.trial, 'bPA', 4, early_timeRange_min);

%             evaluateSnippetFeat(subName, tmpTrialObj.trial, 'PA', 5, late_timeRange_min);
            evaluateSnippetFeat(subName, tmpTrialObj.trial, 'bPA', 5, late_timeRange_min);

        end
    end
    disp('finished all snippets')
    disp(datetime) 
end

%% sub thresh snippets
% trialObj = mdf.load('subject',subName,'mdf_type','trial','trialType','stim');
% if ~isempty(trialObj)
%     for iTrial = 1:length(trialObj)
%         tmpTrialObj = trialObj(iTrial);
%         if ismember('annotations', fieldnames(tmpTrialObj.md)) && ismember('retching_sec', fieldnames(tmpTrialObj.md.annotations))
%             continue
%         else
%             timeRange_min = tmpTrialObj.stimTimes(1)/60+[0,5];
%             if ismember('paddleLabels',fieldnames(summaryObj.md))
%                 evaluateSnippetFeat(subName, tmpTrialObj.trial, 'PA', paddleLabels, filtQuery, 3, timeRange_min, 'downsamp',true);
%             end
%             
%             if ismember('paddlePairLabels',fieldnames(summaryObj.md))
%                 evaluateSnippetFeat(subName, tmpTrialObj.trial, 'bPA', paddlePairLabels,filtQuery, 3, timeRange_min,'downsamp',true);
%             end
%         end
%     end
% end
% disp('finished sub thresh snippets')
% disp(datetime)

