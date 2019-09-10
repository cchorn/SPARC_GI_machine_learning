function [] = plotPSDbars(fftResult)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Plots percentage of total power in the normo, brady and tachy
    %   gastric ranges as a bar graph for the given input struct. 
    %   See analyzeSignalFeatures.m for details on constructing input struct.
    %

    normoLim = fftResult.baseline.F_lims.normoLim;

    brady_base = fftResult.baseline.PSD.brady;
    normo_base = fftResult.baseline.PSD.normo;
    tachy_base = fftResult.baseline.PSD.tachy;
    totalP_base = fftResult.baseline.PSD.total;
    DF_base = fftResult.baseline.DF;
    DF_target = 0;
    legendVal = {};
    
    bradyPercent_base = brady_base/totalP_base * 100;
    normoPercent_base = normo_base/totalP_base * 100;
    tachyPercent_base = tachy_base/totalP_base * 100;
    barMatrix = [bradyPercent_base; normoPercent_base; tachyPercent_base];

    if length(fieldnames(fftResult))>1
        brady_target = fftResult.target.PSD.brady;
        normo_target = fftResult.target.PSD.normo;
        tachy_target = fftResult.target.PSD.tachy;
        totalP_target = fftResult.target.PSD.total;
        DF_target = fftResult.target.DF;
        
        bradyPercent_target = brady_target/totalP_target * 100;
        normoPercent_target = normo_target/totalP_target * 100;
        tachyPercent_target = tachy_target/totalP_target * 100;
        barMatrix = [barMatrix [bradyPercent_target; normoPercent_target; tachyPercent_target] ];
        legendVal = {'perturb'};
    end
    
    bar(barMatrix)
    set(gca,'XTickLabel',{'brady', sprintf('normo (%0.1f-%0.1f)',normoLim),'tachy'})
    ylim([0 100])
    ylabel('%P_n_o_r_m_o')
    title(sprintf('Baseline DF %0.1f; Perturb DF %0.1f', DF_base, DF_target))
    legend({'baseline',legendVal{:}})
    box off
    
end