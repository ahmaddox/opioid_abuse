# Classifying Opioid Abuse using Machine Learning

Amy Haven Maddox
Regis University
MSDS 696 Practicum II

## Project Summary

This project attempts to explore the personal side of opioid abuse. This is done through the use of the National Drug Use and Health Survey (2018), which contains 2,691 features of data and more than 56,000 observations. Each observation is an individual participant who has responded to the survey through a computer generated questionaire (guided by a survey technician). 

This file will explain the motivation, process, analysis of data, and summary of findings.

## Motivation

Opioid use in the United States was declared a national public health emergency in 2017. Millions of people each year misuse prescription drugs, leading to long term drug addiction and potentially drug overdose. HHS.gov reports an estimated 130 people die each day of an opioid related drug overdose. The epidemic is widespread and while government figures report decreases, the problem is still at large. But who is most at risk?

## Problem Statement

The statistics and data released by the government contains useful information regarding the number of overdose deaths, increases and decreases from year to year, and information regarding the root cause of the epidemic. Can I build a classification model that will accurately classify someone as an opioid user based on demographic data? Can I determine relationships between opioid abuse and specific demographic data?

## The Data

The dataset, 2018 National Survey on Drug Use and Health, has been retrieved from the Substance Abuse and Mental Health Services Adminstration website. The survey is sponsored by the Center for Behavorial Health Statistics and Quality (CBHSQ). 

The NSDUH Code Book defines the target population for the survey as not having changed since 1991, and includes "civilian, noninstitutionalized population of the United States (including civilians living on military bases) who were 12 years of age or older at the time of the survey." The Code Book describes the specific method for choosing sample sizes by state, which includes oversampling for larger metropolitan areas.

**The data includes 56,313 observations and 2,691 columns of data.**

## The Process

###1. **Remove redundant data**
The data includes imputed and recoded data for many of the sections. This data is repetitive and causes issues within the data set. Rather than leaving the columns in the data set, I remove them manually and create a new data set.

###2. **Change data to numeric**
The data is imported with all variables stored as integers. I would rather the data be numeric, for ease of modeling. I will have to go back and forth between numeric and factor for several of the variables, but I want to make this change from the start.

###3. **Check for missing values**
Next, I check the data for missing values. The output returns a total of 13,753,804 missing values! I keep in mind that the data set is massive, and a bulk of these values may belong to a handful of columns. Given that some of the data is imputed automatically, I am not too concerned.
I take a closer look at the missing values and review column-by-column. Overall, most columns do not have missing values. The columns with missing values mostly belong to data in recoded sections where a "." has been entered to represent "No daily use/Not reported". According to the NSDUH Code Book, this can be represented by a "98" instead. I write the code to update all missing values to be replaced with "98", and then confirm that no more missing values are present.

###4. **Checking the balance of the target variable**
For the purposes of this project, opioids use will be classified using the target variable "OPINMYR", which is defined in the Code Book as "Opioid Misuse in the past year". This includes both prescription medication and heroin.

When I run the table to determine if the variable is balanced, I see that it is significantly off balance. Only 4% of respondents have reported that they have misused opioids in the past year, while the majority have reported that they have not misused opioids. I can choose to use a different variable that represents something different, but I know that an unbalanced variable does not mean that the data is not valuable.

I am working with a minority class and can therefore apply a method referred to as oversampling, or upsampling. I apply the ovun.sample function, which samples from the minority class, from the ROSE (Random Over Sampling Examples) package. Within the parameters I identify the method as 'over', and the sample size (N) as '107850'. This amount is just the value of '0' from the table function above, multiplied by 2 to balance the class.

When I run the table function on the new dataset, I can see that the class is perfectly balanced.

###5. **Feature selection using Boruta**
The first thing I have to do before running any model is to reduce the number of features in my dataset. Boruta is a feature selection algorithm in R that utilizes a random forest model and Z scores to determine feature importance. 

Because of the size of my dataset, I scale it down before running the algorithm, and run it on 1% of the dataset.

Next, I run the Boruta model by first installing the Boruta library. I specify the target variable and dataset, and add 'doTrace' so that I can monitor progress on the model.

Once the model is finished running I print the results. This will return information such as the number of iterations and how long the model took to run. This will also tell me how many attributes were confirmed, rejected, and determined as tentative.

My results tell me that there were 99 iterations that took about 8+ minutes. There are 66 confirmed attributes, 772 rejected attributes, and 27 tentative attributes.

###6. **Set target variable as factor**
Before running the random forest, I have to make sure that the target variable, OPINMYR, is set to a factor. Otherwise, the random forest will attempt to run the random forest as a regression model.

###7. **Split the data into train and test sets**
I split the data into training and testing data sets using a 75/25 split.

###8. **Train the random forest model using the training data**
After loading the random forest library, I implement the random forest model and save it as "drg_forest". This model includes the data set that was deemed important from the Boruta function, so it is quite large and takes a long time to run (about 25 minutes).

###9. **Summarize the model**
Once the model completes, I run the summary. It begins by running the call, followed by the type of forest (classification), and the number of trees (500). The number of variables tried at each split is 8. The OOB estimate of error rate is 0%, and the confusion matrix reveals that all observations were appropriately classified. 

###10. **Create predictions**
Next, I run the prediction model based on the existing random forest model and testing data set. Once it completes, I can evaluate the model to determine the accuracy level. 

###11. **Evaluate the model**
The results of the prediction model based on the test data determines that this model is also 100% accurate.

###12. **Try different variables in the data set**
Because the model produced such a high accuracy rate, which could not be correct, I want to see if using a different combination of variables will change the accuracy. I did also try different models (KNN, ensemble methods including SVM, gbm, bagging, boosting, and logistic regression). These all produced the same results unless I changed the variables.

The new data set that finally produced an imperfect model contains the following variables:
*CATAGE (Age)
*IRSEX (Sex)
*NEWRACE2 (Race)
*INCOME (Income)
*IRWRKSTAT (Work status)
*COUTYP4 (Metro location)
*MI_CAT_U (Mental illness category)
*PNRMAINRSN (Reason for misusing pain medication)
*TOBFLAG (Even used tobacco)

###13. **Re-run random forest with new data set**
The new data set produces a 1.01% OOB estimate of error rate when ran through the random forest model. This is still quite high, considering the feature types - it seems unlikely that a model could predict whether or not a person is an opioid abuser simply based on those categories. However, the PNRMAINRSN variable - which is defined as the "Main reason for misusing pain relievers", is ranked highest on the importance plot. This may have a lot to do with the significance of the model.

## Technologies

R Studio Version 1.3.1093

## Sources / References
Davis, Matthew A., Lewei A. Lin, Haiyin Liu, and Brian D. Sites. “Prescription Opioid Use among Adults with Mental Health Disorders in the United States.” The Journal of the American Board of Family Medicine 30, no. 4 (July 1, 2017): 407–17. https://doi.org/10.3122/jabfm.2017.04.170112.

“Commonly Used Terms | Drug Overdose | CDC Injury Center,” May 5, 2020. https://www.cdc.gov/drugoverdose/opioids/terms.html.

