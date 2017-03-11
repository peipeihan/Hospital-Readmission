setwd("~/Dropbox/DAL_NRD")
rm(list=ls())
DF <- read.csv("~/Dropbox/DAL_NRD/100K_020417.csv")
library(dplyr)
library(ggplot2)
library(caret)

#install.packages("caret")
##Drop missing value
DF <- filter(DF, DIED != -9, DIED != -8, DISPUNIFORM != -9, DISPUNIFORM != -8, DISPUNIFORM != 99,
             LOS !=  -6666)


##Select some features
#Continuous 
X1 <- select(DF, AGE, LOS )
#Binary
X2 <- select(DF, AWEEKEND, DIED, FEMALE, Severity.CM_AIDS:Severity.CM_WGHTLOSS)
#Catergorial
X3 <- select(DF, DISPUNIFORM, DMONTH, DQTR, HCUP_ED, MDC, Severity.APRDRG:Severity.APRDRG_Severity,
             Hospital.HOSP_BEDSIZE:Hospital.H_CONTRL)
X3 <- data.frame(lapply(X3, function(x) as.factor(x)))


##Calculate Readmisssion
DF <- arrange(DF, NRD_VisitLink, NRD_DaysToEvent)
CalculateReadmission <- function(Data = DF){
  Data <- arrange(Data, NRD_VisitLink, NRD_DaysToEvent)
  A <- Data %>%
    select(NRD_VisitLink,KEY_NRD, NRD_DaysToEvent, LOS) %>%
    arrange(NRD_VisitLink, NRD_DaysToEvent) %>%
    mutate(Discharge = NRD_DaysToEvent + LOS) %>%
    group_by(NRD_VisitLink) %>%
    mutate(NextAdm = lead(NRD_DaysToEvent)) %>%
    mutate(Duration = NextAdm-Discharge) 
  y <- (ifelse(A$Duration<=30, 1, 0))
  y[is.na(y)] <- 0
  return(y)
}
y <- CalculateReadmission()


##Transform Categorical data to binary
X3 <- predict(dummyVars(~ ., data = X3), newdata = X3)


##Delete Low varation features
#X1 <- X1[, -nearZeroVar(X1)]
X2 <- X2[, -nearZeroVar(X2)]
X3 <- X3[, -nearZeroVar(X3)]


##Delete linear dependent features
#X1<- X1[, -findLinearCombos(X1)$remove]
#X2<- X2[, -findLinearCombos(X2)$remove]
X3<- X3[, -findLinearCombos(X3)$remove]


##Creating Training and Test data set (also centering and scaling them)
set.seed(123)
inTrain <- sample(seq_len(nrow(X1)), size = nrow(X1)/2) #half and half

TrainingX1 <- X1[inTrain,]
TestX1 <- X1[-inTrain,]
TrainingX2 <- X2[inTrain,]
TestX2 <- X2[-inTrain,]
TrainingX3 <- X3[inTrain,]
TestX3 <- X3[-inTrain,]
Trainingy <- y[inTrain]
Testy <- y[-inTrain]

preProcValues <- preProcess(TrainingX1, method = c("center", "scale"))

TrainingX1_Normalized <- predict(preProcValues, TrainingX1)
TestX1_Normalized <- predict(preProcValues, TestX1)

TrainingX <- cbind(TrainingX1_Normalized, TrainingX2, TrainingX3)
TestX <- cbind(TestX1_Normalized, TestX2, TestX3)

Training <- cbind(Trainingy, TrainingX)
Test <- cbind(Testy, TestX)

##Train Model
set.seed(825)
Fit <-glm(Trainingy ~ .,
          family = binomial(logit), data = Training)
summary(Fit)


##Predict
Pre <- predict(Fit, Test[,-1], type = "response")
library(pROC)
AUC <- roc(Test[,1], Pre)
print(AUC$auc)
#The AUC is telling us that our model has a 0.7 AUC score 
#(remember that an AUC ranges between 0.5 and 1, where 0.5 is random and 1 is perfect).
