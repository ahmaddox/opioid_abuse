### Load Data
drug_data<- read.csv('drug_data2.csv', header = T, sep = "\t")

### Change Data to Numeric
drug_data[1:2692] <- lapply(drug_data[1:2692], as.numeric)

colSums(is.na(drug_data))
drug_data[is.na(drug_data)] <- 98 # Change missing values to "98"

### Load libraries
library(imbalance)

# OPINMYR
drug_data$OPINMYR <- as.factor(drug_data$OPINMYR)
levels(drug_data$OPINMYR) <- c("Negative", "Positive")
table(drug_data$OPINMYR)
drug_data$CLASS <- drug_data$OPINMYR

table(drug_data$CLASS)

newsample <- oversample(drug_data, method = "ADASYN", classAttr = "CLASS")

### Remove redundant columns of data
new_sample_rmvd <- newsample[-c(1, 2, 3:538, 785:821, 836:856, 874:888, 889:1206, 1262:1280,
                              1346:1488, 1593:1656, 1661:1742, 1795:1855, 1903:1936,
                              1958:2040, 2066:2195, 2292:2374, 2409:2446, 2471:2523, 2524:2526,
                              2527:2548, 2583:2609, 2626:2627, 2628:2645, 2646:2655, 
                              2656:2661, 2662:2663, 2683:2684, 2685, 2687, 2688, 2689:2691,
                              2219, 2063, 1954, 1944:1947, 1938)]
### Reduce Size of Dataset
set.seed(1234)
small_drug_data <- sample(2, nrow(new_sample_rmvd), replace=TRUE, prob=c(0.99, 0.01))
small_drug_sample <- new_sample_rmvd[small_drug_data == 2, ]

### Feature Selection using Boruta
library(Boruta)
boruta_out <- Boruta(CLASS ~ ., data = small_drug_sample, doTrace = 2)
print(boruta_out)
boruta_signif <- names(boruta_out$finalDecision[boruta_out$finalDecision %in% c("Confirmed", "Tentative")])
print(boruta_signif)
plot(boruta_out, cex.axis = .7, las = 2, xlab = "", main = "Variable Importance")
# Retrieve final variables
getSelectedAttributes(boruta_out, withTentative = T)
boruta.df <- attStats(boruta_out)
print(boruta.df)

### Create new data set with new variables
drug_data2 <- new_sample_rmvd[c("PSYANYFLAG", "PNRNMFLAG", "TQSDNMFLAG", 
                                "HERPNRYR", "ILLFLAG", 
                                "MJONLYFLAG", "ILLEMFLAG", "CLASS")]
### Change CLASS to factor
drug_data2$CLASS <- as.factor(drug_data2$CLASS)
levels(drug_data2$CLASS) <- c("No", "Yes")
table(drug_data2$CLASS)

### Predicting Substance Abuse Using Random Forest
# Load library
library(randomForest)
# Create training and testing data sets ###
index <- sample(2, nrow(drug_data2), replace=TRUE, prob = c(0.75, 0.25))
drf_train <- drug_data2[index==1, ]
drf_test <- drug_data2[index==2, ]

### RANDOM FOREST: Implement Model ###
drug_forest <- randomForest(CLASS ~ ., data = drf_train)
drug_forest

# gives Gini Index (priority of variables)
drug_forest$importance
varImpPlot(drug_forest)

### RANDOM FOREST: Predictions ###

drf_pred <- data.frame(drf_test$CLASS, predict(drug_forest, drf_test[, 1:23], type = "response"))
head(drf_pred, 5)

plot(drf_pred)
library(caret)
confusionMatrix(table(drf_pred, drf_test$CLASS)) 

# Fit the random forest
library(randomForest)
drug_forest <- randomForest(ILLFLAG ~ ., data = small_drug_sample, proximity = TRUE)
drug_forest

# Return variable importance
drug_importance <- importance(drug_forest)
drug_importance
varImpPlot(drug_forest)

### Feature Reduction using PCA
# Build pcaChart function
pcaCharts <- function(x) {
  x.var <- x$sdev ^ 2
  x.pvar <- x.var/sum(x.var)
  print("proportions of variance:")
  print(x.pvar)
  
  par(mfrow=c(2,2))
  plot(x.pvar,xlab="Principal component", ylab="Proportion of variance explained", ylim=c(0,1), type='b')
  plot(cumsum(x.pvar),xlab="Principal component", ylab="Cumulative Proportion of variance explained", ylim=c(0,1), type='b')
  screeplot(x)
  screeplot(x,type="l")
  par(mfrow=c(1,1))
}

# Clean up data by removing zero variance columns
library(caret)
# Change ILLFLAG var back to numeric
small_drug_sample$ILLFLAG <- as.factor(small_drug_sample$ILLFLAG)
nzv <- nearZeroVar(small_drug_sample, saveMetrics = TRUE)
print(paste('Range:', range(nzv$percentUnique)))
head(nzv)
# Return number of rows with freqRatio of > 1
dim(nzv[nzv$freqRatio > 1,])
# Remove rows / columns with freqRatio of > 1
drug_nzv <- small_drug_sample[c(rownames(nzv[nzv$freqRatio > 1,])) ]
print(paste('Column count after cutoff:', ncol(drug_nzv)))
# Standardize the data 
drug_pca <- prcomp(scale(drug_nzv), center = TRUE)
# Check the output
names(drug_pca)
print(drug_pca)
summary(drug_pca)
# Visualization of Data
pcaCharts(drug_pca)
biplot(drug_pca, scale = 0, cex = .5)
pca.out <- drug_pca
pca.out$rotation <- -pca.out$rotation
pca.out$x <- -pca.out$x
# Create biplot of data including target variable
library(factoextra)
fviz_pca_ind(pca.out, geom.ind = "point", pointshape = 21, 
             pointsize = 2, 
             fill.ind = small_drug_sample$ILLFLAG, 
             col.ind = "black", 
             palette = "jco", 
             addEllipses = TRUE,
             label = "var",
             col.var = "black",
             repel = TRUE,
             legend.title = "Substance Abuse, Yes/No") +
  ggtitle("2D PCA-plot from 70 feature dataset") +
  theme(plot.title = element_text(hjust = 0.5))

pr.var <- pca.out$sdev ^ 2
round(pr.var, 2)
pcs <- pca.out$x[,1:20]
head(pcs, 20)

# Bind new variables with target variable
final_drug <- pcs
final_drug <- cbind(final_drug, small_drug_sample$ILLFLAG)
head(final_drug)

# Determine which variables explain specific PC
loadings <- eigen(cov(final_drug))$vectors
explvar <- loadings ^ 2

### Ensemble Method to predict drug use
library(mlbench)
library(tidyverse)
# Create training and testing sets
ind = sample(2, nrow(drug_data2), replace = TRUE, prob=c(0.75, 0.25))
trainset = drug_data2[ind == 1,]
testset = drug_data2[ind == 2,]

fitControl = trainControl(method = "cv",
                          number = 10,
                          classProbs = TRUE,
                          summaryFunction = twoClassSummary)

library(rpart)
tree_model = train(CLASS ~ .,
                   data = trainset,
                   method = "rpart",
                   metric = "ROC",
                   tuneLength = 20,
                   trControl = fitControl)

tree_model # Review output from regression tree

tree_pred = predict(tree_model,newdata = testset)
tree_pred

confusionMatrix(table(tree_pred, testset$CLASS), method = "everything")
RT.acc = confusionMatrix(tree_pred, testset$CLASS)$overall['Accuracy']

library(e1071)
svm_model = svm(CLASS ~., data = trainset, kernel = 'linear', cost = 100, scale = FALSE)
print(svm_model)
svm_model2 = train(CLASS~., data = trainset, method = "svmLinear")
print(svm_model2)
svm_pred = predict(svm_model2, newdata =  testset)
confusionMatrix(table(svm_pred, testset$CLASS), method = "everything")
svm_acc = confusionMatrix(svm_pred, testset$CLASS)$overall['Accuracy']

library(ipred)
bag = bagging(CLASS ~ ., data = trainset, coob = TRUE)
print(bag)
pid.predict = predict(bag, newdata = testset)

confusionMatrix(table(pid.predict, testset$CLASS), method = "everything")
pid.acc = confusionMatrix(pid.predict, testset$CLASS)$overall['Accuracy']

library(xgboost)
fitControl = trainControl(method = "cv",
                          number = 10,
                          classProbs = TRUE,
                          summaryFunction = twoClassSummary)
xgb_grid_1 = expand.grid(
  nrounds = 50,
  eta = c(0.03),
  max_depth = 1,
  gamma = 0,
  colsample_bytree = 0.6,
  min_child_weight = 1,
  subsample = 0.5
)
model_xgbTree = train(CLASS~.,
                      trainset,
                      method="xgbTree",
                      metric="ROC",
                      tuneGrid=xgb_grid_1,
                      trControl=fitControl)
print(model_xgbTree)

boost.pred = predict(model_xgbTree, testset)
boost.acc = confusionMatrix(boost.pred, testset$diabetes)$overall['Accuracy']

accuracy = data.frame(Model=c("Tree", "SVM", "Bagging", "Boosted"), Accuracy=c(RT.acc, svm.acc, pid.acc, boost.acc ))
ggplot(accuracy,aes(x=Model,y=Accuracy)) + geom_bar(stat='identity') + theme_bw() + ggtitle('Comparison of Model Accuracy')

model.list = list(RPART = tree.model, bagging = bag, XGBOOST=model_xgbTree, SVM = svm.model)
resamples = resamples(model_list)
bwplot(resamples, metric="ROC")

model_cor = modelCor(model_list)
model_cor


library(xgboost)
fitControl = trainControl(method = "cv",
                          number = 10,
                          classProbs = TRUE,
                          summaryFunction = twoClassSummary)


