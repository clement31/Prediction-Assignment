#################### Test week 4 "Pratical Machine Learning" ############################
#################### Prediction Assignment homework  ############################



##### Load packages #####
library(AppliedPredictiveModeling)
library(caret)
library(pgmm)
library(rpart)
library(gbm)
library(lubridate)
library(forecast)
library(e1071)
library(dplyr)
library(tibble)
library(rpart)
library(rpart.plot)


##### 1) Data loading #####

# I load the raw data from a website and then download them.

train_url <- "http://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
test_url  <- "http://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"

train <- read.csv(url(train_url))
validation <- read.csv(url(test_url))

dim(train)
dim(validation)


  
##### 2) Data Partitioning #####

# I split the train data into training and testing samples.
# The training set consisits of 70% of the total train data and so the testing set consists of 30% of the total train data.
# For reproducibility, seed will be set to 127.

set.seed(127)
training_sample <- createDataPartition(y=train$classe, p=0.7, list=FALSE)
training <- train[training_sample, ]
testing <- train[-training_sample, ]

dim(training)
dim(testing)
names(training)
summary(training$classe)




##### 3) Identify variables that are non-zero #####

# I select only features (variables) that are non-zero in the validation data set. 

all_zero_colnames <- sapply(names(validation), function(x) all(is.na(validation[,x])==TRUE))
nznames <- names(all_zero_colnames)[all_zero_colnames==FALSE]
nznames <- nznames[-(1:7)]
nznames <- nznames[1:(length(nznames)-1)]

#The final model will be fit using the following variables:
nznames




##### 4) Cross-validation technique #####

# The Cross-validation technique assesses how the results of a statistical analysis will generalize to an independent data set. 
# In 3-fold cross-validation, the original sample is randomly partitioned into 3 equal sized sub-samples. A single sample is retained 
# for validation and the other sub-samples are used as training data. The process is repeated 3 times and the results from the folds 
# are averaged.
# Thus, for that project, I use cross-validation with the training sample in order to improve the accuracy of the predictive model.
# The cross-validation technique is done for each model with K = 3.

fitControl <- trainControl(method='cv', number = 3)




##### 5) Main steps for model building and evaluating the accuary #####

# I'm going to use 3 different model algorithms and then look to see which provides the best out-of-sample accuracy. 
# The three model types I'm going to test are the following ones : Decision trees with CART (rpart), Stochastic gradient boosting trees (gbm)
# and Random forest decision trees (rf). 
# I use the cross-validation technique within the training partition to improve the model fit and then do an out-of-sample test with the testing partition.
# Indeed, the model fit using the training data is tested against the testing data. Predicted values for the testing data are then 
# compared to the actual values. This allows forecasting the accuracy and overall out-of-sample error, which indicate how well the model 
# will perform with other data.




##### 6) Decision Tree Model #####

# Run/train the model and save it :
model_cart <- train(
    classe ~ ., 
    data=training[, c('classe', nznames)],
    trControl=fitControl,
    method='rpart'
  )
save(model_cart, file='./ModelFitCART.RData')

# Results of the model on the testing data and plot it :
predCART <- predict(model_cart, newdata=testing)
cmCART <- confusionMatrix(predCART, testing$classe)
cmCART
rpart.plot(model_cart$finalModel, roundint=FALSE)

# The accuracy of the Decision Tree Model, which is 0.49, is limited.



##### 7) Gradient Boosting Model #####

# Run/train the model and save it :
model_gbm <- train(
  classe ~ ., 
  data=training[, c('classe', nznames)],
  trControl=fitControl,
  method='gbm'
)
save(model_gbm, file='./ModelFitGBM.RData')

# Results of the model on the testing data and plot it :
predGBM <- predict(model_gbm, newdata=testing)
cmGBM <- confusionMatrix(predGBM, testing$classe)
cmGBM 
plot(cmGBM$table, col = cmGBM$byClass, 
     main = paste("Gradient Boosting - Accuracy Level =",
                  round(cmGBM$overall['Accuracy'], 4)))

# The accuracy of the Gradient Boosting Model, which is 0.96, is very good.




##### 8) Random Forest Model #####

# Run/train the model and save it :
model_rf <- train(
  classe ~ ., 
  data=training[, c('classe', nznames)],
  trControl=fitControl,
  method='rf',
  ntree=100
)
save(model_rf, file='./ModelFitRF.RData')

# Results of the model on the testing data and plot it :
predRF <- predict(model_rf, newdata=testing)
cmRF <- confusionMatrix(predRF, testing$classe)
cmRF
plot(cmRF$table, col = cmRF$byClass, 
     main = paste("Random Forest - Accuracy Level =",
                  round(cmRF$overall['Accuracy'], 4)))

# The accuracy of the Random Forest Model, which is 0.99, is also very good.




##### 9) Comparaison of models #####

# Sum up of accuracy of the three types of models :
AccuracyResults <- data.frame(
  Model = c('CART', 'GBM', 'RF'),
  Accuracy = rbind(cmCART$overall[1], cmGBM$overall[1], cmRF$overall[1])
)
AccuracyResults

# Based on an assessment of these 3 model fits and out-of-sample results, it looks like both gradient boosting and random forests 
# outperform the decision tree model, with random forests being slightly more accurate. 

# The next step in modeling could be to create an ensemble model of these three model results, however, given the high accuracy of 
# the random forest model, this process is not necessary for that project. I accept the random forest model as the champion (best model) 
# and move on to prediction in the validation sample.




##### 10) Prediction #####

# To finish, I'm going to use the validation data sample to predict a classe for each of the 20 observations.

predValidation <- predict(model_rf, newdata=validation)
ValidationPredictionResults <- data.frame(
  problem_id=validation$problem_id,
  predicted=predValidation
)

# The results of the predicted class are :
print(ValidationPredictionResults)


