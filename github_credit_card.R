
#importing data

credit <- read.csv("creditcard.csv" , stringsAsFactors = FALSE)

head(credit)

#Is there any missind data?
any(is.na(credit))

names(credit)

str(credit)

credit$Class <- factor(credit$Class,levels = c(0,1))

table(credit$Class)

#so it is an imbalance data.

prop.table(table(credit$Class))


#pie chart of credit transaction.

labels <- c("legit","fraud")
labels <- paste(labels,round(100 * prop.table(table(credit$Class)),2))
labels <- paste0(labels,"%")

pie(table(credit$Class),labels , col = c("lightblue","red"),
    main = "pie chart of credit card fraud transaction")


#No model Prediction

No_model <- rep.int(0,nrow(credit))
No_model <- factor(No_model,levels = c(0,1))

library(caret)

confusionMatrix(No_model,credit$Class)

library(dplyr)

set.seed(103)

#As the data is very large so we will take a small portion of it. 

credit <- credit %>% sample_frac(0.1)

library(ggplot2)

ggplot(credit,aes(V1,V2,col = Class)) + geom_point() + theme_bw() + 
  scale_color_manual(values = c("dodgerblue","red"))

#Creatind training and test model for fraud detection.

library(caTools)

set.seed(103)

credit_sample <- sample.split(credit$Class,SplitRatio = 0.8)

credit_train <- subset(credit,credit_sample == TRUE)

credit_test <- subset(credit,credit_sample == FALSE)

dim(credit_train)                      
dim(credit_test)

'''In our train data there are only 31 fraud transactions and 
  22785 legit transactions so it is a highly imbalance data.'''

#Random over sampling

library(ROSE)

n_legit <- 22785
n_frac_legit <- 0.50
total_n <- n_legit / n_frac_legit #45570

oversample_result <- ovun.sample(Class ~ .,credit_train,method = "over",N = total_n,seed = 2020)

oversample_credit <- oversample_result$data

table(oversample_credit$Class)

ggplot(oversample_credit,aes(V1,V2,col = Class)) + geom_point(position = position_jitter(width = 0.1)) +
  theme_bw() + scale_color_manual(values = c("dodgerblue","red"))

#Ranom undersampling(RUS)

n_fraud <- 31
new_frac_fraud <- 0.50
new_n_total <- n_fraud / new_frac_fraud

undersample_result <- ovun.sample(Class ~ . ,credit_train,method = "under",N = new_n_total,seed = 2020)

undersample_credit <- undersample_result$data

table(undersample_credit$Class)

ggplot(undersample_credit,aes(V1,V2,col = Class)) + geom_point(position = position_jitter(width = 0.1)) +
  theme_bw() + scale_color_manual(values = c("dodgerblue","red"))

#ROS and RUS

n_new = nrow(credit_train)
frac_fraud_new <- 0.50

sampling <- ovun.sample(Class ~ . , credit_train,method = "both",N = n_new,p = frac_fraud_new,seed = 2020)

sampling_credit <- sampling$data

table(sampling_credit$Class)

ggplot(sampling_credit,aes(V1,V2,col = Class)) + geom_point(position = position_jitter(width = 0.1)) + theme_bw() + 
  scale_color_manual(values = c("dodgerblue","red"))

#using SMOTE to balance dataset

library(smotefamily)

table(credit_train$Class)

n0 <- 22759
n1 <- 26
r0 <- 0.6

n_times <- ((1 - r0)/r0) * (n0/n1) - 1

smote_result <- SMOTE(credit_train[,-c(1,31)],target = credit_train$Class,K = 5,dup_size = n_times)

smote_credit <- smote_result$data

colnames(smote_credit)[30] <- "Class"

table(smote_credit$Class)

ggplot(smote_credit,aes(V1,V2,col = Class)) + geom_point() +
  theme_bw() + scale_color_manual(values = c("dodgerblue","red"))

#Building model

library(rpart)
library(rpart.plot)

credit_model1 <- rpart(Class ~ . , data = smote_credit)

rpart.plot(credit_model1 , extra = 0 , type = 5 , tweak = 1.2)


#predicted fraud class

predicted_value <- predict(credit_model1,credit_test,type = "class")


library(caret)

confusionMatrix(predicted_value,credit_test$Class)


credit_train_model <- rpart(Class ~ . , data = credit_train)

predict_unsmote <- predict(credit_train_model,credit_test,type = "class")

confusionMatrix(predict_unsmote,credit_test$Class)

control <- trainControl(method = "cv",number = 10)

metric <- "Accuracy"

set.seed(10)
#cart

fit.rpart <- train(Class ~ . , data = smote_credit , method = "rpart" , trControl = control , metric= metric )

set.seed(10)

#kNN

fit.knn <-  train(Class ~ . , data = smote_credit , method = "knn" , trControl = control , metric= metric )

set.seed(10)

#svm

fit.svm <- train(Class ~ . , data = smote_credit , method = "svmRadial" , trControl = control , metric= metric )

#randomforest
set.seed(10)

fit.rf <- train(Class ~ . , data = smote_credit , method = "rf" , trControl = control , metric= metric )

results <- resamples(list(rpart = fit.rpart , knn = fit.knn , svm = fit.svm , rf = fit.rf))

summary(results)

dotplot(results)


#Make predictions

prediction <- predict(fit.rf,credit_test)

confusionMatrix(prediction , credit_test$Class)
