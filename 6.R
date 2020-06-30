# A)

library(readxl)
library(dplyr)
library(caret)
library(lattice)
library(e1071)
library(rattle)

blood_train <- read_excel("blood_traindata.xlsx")
blood_test <- read_excel("blood_testdata.xlsx")
str(blood_train)
str(blood_test)
colnames(blood_train) = c('ID','Months_Last','Number_Donations','Total_Volume','Months_First','Donate_This_Month')
colnames(blood_test) = c('ID','Months_Last','Number_Donations','Total_Volume','Months_First','Donate_This_Month','Probability')
blood_train$Donate_This_Month=factor(blood_train$Donate_This_Month)

fullset <- createDataPartition(blood_train$Donate_This_Month, p=0.75, list=FALSE)
trainset <- blood_train[fullset,]
testset <- blood_train[-fullset,]

cor(blood_train[, -6])

# Logistic Regression
logit1 = glm(Donate_This_Month ~ Months_Last * Number_Donations * Months_First, data=trainset, family="binomial")
summary(logit1)

logit1a = glm(Donate_This_Month~ Months_Last + Number_Donations + Months_First, data=trainset, family="binomial")
summary(logit1a)

logit1$coef
y=logit1$coef[1] + logit1$coef[2]*testset$Months_Last + logit1$coef[3]*testset$Number_Donations +
  logit1$coef[4]*testset$Months_First
Probabilitya = exp(y)/(1+exp(y))

logit1a$coef
y=logit1a$coef[1] + logit1a$coef[2]*testset$Months_Last + logit1a$coef[3]*testset$Number_Donations +
  logit1a$coef[4]*testset$Months_First
Probability = exp(y)/(1+exp(y))

testset$Probability <- Probabilitya

pred_test <- testset %>% mutate(guess = ifelse(y >= .5, 1, 0), correct = ifelse(Donate_This_Month == guess, 1, 0))

# 10-fold Cross-Validation
control <- trainControl(method="cv", number=10)
metric <- "Accuracy"

# Linear Discriminant Analysis (LDA)
set.seed(1)
fit.lda <- train(Donate_This_Month ~ Months_Last + Number_Donations + Months_First, data=blood_train, method="lda", 
                 metric=metric, trControl=control)

# Classfication and Regression Trees (CART)
set.seed(2)
fit.cart <- train(Donate_This_Month~ Months_Last + Number_Donations + Months_First, data=blood_train, method="rpart", 
                  metric=metric, trControl=control)

# k-Nearest Neighbors (KNN)
set.seed(3)
fit.knn <- train(Donate_This_Month~ Months_Last + Number_Donations + Months_First, data=blood_train, method="knn", 
                 metric=metric, trControl=control)

# Support Vector Machines (SVM)
set.seed(4)
fit.svm <- train(Donate_This_Month~ Months_Last + Number_Donations + Months_First, data=blood_train, method="svmRadial", 
                 metric=metric, trControl=control)

# Random Forest
set.seed(5)
fit.rf <- train(Donate_This_Month~ Months_Last + Number_Donations + Months_First, data=blood_train, method="rf", 
                 metric=metric, trControl=control)


results <- resamples(list(lda=fit.lda, cart=fit.cart, knn=fit.knn, svm=fit.svm, rf=fit.rf))
summary(results)

print(fit.rf)

predict1 <- predict(fit.rf, blood_test)
blood_test$Donate_This_Month <- predict1
y=logit1$coef[1] + logit1$coef[2]*blood_test$Months_Last + logit1$coef[3]*blood_test$Number_Donations +
  logit1$coef[4]*blood_test$Months_First
blood_test$Probability = exp(y)/(1+exp(y))

write.csv (blood_test, file = "Project5a.csv")
