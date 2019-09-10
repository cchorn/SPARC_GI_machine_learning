# find dominant frequency if there's any
# This program features:
# 1) Use freq bands = 0.3cpm
# 2) Power scaled s.t. maxpower=1 at each time point
# 3) Compare among local peaks
# 4) Apply to baseline recordings



rm(list=ls())


out1.dir = "..." # directory to save resutls 
data.dir = "..." # directory containing data


library(dplyr)
library(stringr)
library(tibble)
library(multcomp)
library(utils)


#---------------------------------------------------------#
# Useful functions
# 1) p-value formatting
getpv = function(p){
  if(p<=0.0001) pv = "<0.0001" else
    pv = as.character(round(p,4))
  return(pv)
}


# 2) detect true DF if any

DF_detect = function(filename){
  
  # Read and process data
  freq_data = read.csv(file.path(data.dir,filename),na="")

  # first column = frequency in cpm
  # 2nd to last column = power over time (extract from time windows)
  
  lastcol = names(freq_data)[ncol(freq_data)]
  lastcol = as.numeric(substr(lastcol,2,nchar(lastcol)))
  freq_nooverlap = freq_data[,c("Row",paste0("w",0:lastcol))]
  
  # power scaled at each time window such that max(power) == 1
  for(j in 2:(lastcol+2)){
    freq_nooverlap[,j] = freq_nooverlap[,j]/max(freq_nooverlap[,j])
  }
  rm(j)
  
  freq_long = reshape(freq_nooverlap,varying = names(freq_nooverlap)[2:ncol(freq_nooverlap)],v.names = "power",
                      timevar = "time",idvar = "Row",direction = "long")
  
  freq_long$time = freq_long$time - 1
  freq_long$Row = as.factor(freq_long$Row)
  
  
  ggplot(data = freq_long)+geom_line(aes(x=as.numeric(as.character(Row)),y=power,color=factor(time)))+
    xlab("frequency") + ggtitle("14-18_Trial05_chpaddle01-04 \n power not scaled\n color shows time window")
  
  
  
  freq_lm <- lm(power ~ Row, data = freq_long)
  freq_av <- aov(freq_lm)
  anova_p = summary(freq_av)[[1]][["Pr(>F)"]][1]
  anova_p = getpv(anova_p)
  
  #              Df Sum Sq Mean Sq F value Pr(>F)    
  # Row          30   4248  141.60   21.32 <2e-16 ***
  # Residuals   589   3912    6.64 
  
  # There's at least one row different from others
  
  
  
  # Find out the peaks over frequency
  rowmn = rowMeans(freq_nooverlap[,2:ncol(freq_nooverlap)])
  rowmndiff = ((rowmn[2:length(rowmn)] - rowmn[1:(length(rowmn)-1)])>0)*1
  
  peak.loc = c()
  for(i.diff in 1:(length(rowmndiff)-1)){
    if(rowmndiff[i.diff+1]!=rowmndiff[i.diff])
      peak.loc = c(peak.loc,i.diff+1)
  }
  
  rm(i.diff)
  
  peaks = freq_nooverlap$Row[peak.loc]
  n.p = length(peak.loc)
  
  
  # contrast
  if(n.p > 1){
    pairs = t(combn(peak.loc,m = 2))
    contrast = matrix(0,nrow=nrow(pairs),ncol=length(freq_nooverlap$Row))
    
    for(j in 1:nrow(pairs)){
      contrast[j,pairs[j,]] = c(1,-1)}
    rm(j)
    
    rownames(contrast) = paste0(freq_nooverlap$Row[pairs[,1]]," vs ",freq_nooverlap$Row[pairs[,2]])
    
    t = glht(freq_lm, linfct = contrast)
    a = summary(t)
    
    r = data.frame(Estimate = a$test$coefficients,Std.Error = a$test$sigma,Tvalue = a$test$tstat,PVadj = a$test$pvalues)
    r <- r %>% rownames_to_column("Pair")
    r$significant = (r$PVadj<0.05)*1
    
    # which freq has the largest average power?
    max_mean_freq = freq_nooverlap$Row[rowmn == max(rowmn)]
    
    r_mmf = r[str_detect(r$Pair,as.character(max_mean_freq)),]
    df_sig = c("Yes","No")[(sum(r_mmf$significant!=1)>0)+1]
  }
  
  if(n.p==1){
    df_sig = "Yes"
    max_mean_freq = freq_nooverlap$Row[rowmn == max(rowmn)]
  }
  
  result = data.frame(filename,anova_p,max_mean_freq,df_sig)
  return(result)
  
}





animals = c("13-18","14-18","15-18","16-18","29-18","32-18","34-18","43-17")
trials  = paste0(animals,"_Trial",c("02","05","08","03","01","01","01","02"),"_chpaddle")

allfiles = list.files(data.dir)


result = c()

for(i.animal in 1:length(animals)){
  animal_spec = allfiles[str_detect(allfiles,trials[i.animal])]
  
  for(i in 1:length(animal_spec)){
    result = rbind(result,DF_detect(animal_spec[i]))
  }
  print(animals[i.animal])
}

write.csv(result,file.path(out1.dir,"DFtest_origfreq_powerscale_comppeaks.csv"),na="",row.names = F)












