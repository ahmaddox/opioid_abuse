# Loading the data

drug_data <- read.csv('drug_data2.csv', header = T, sep = "\t")

# Removing redundant columns of data

new_drug_data <- drug_data[-c(1, 2, 3:538, 785:821, 836:856, 874:888, 889:1206, 1262:1280,
                              1346:1488, 1593:1656, 1661:1742, 1795:1855, 1903:1936,
                              1958:2040, 2066:2195, 2292:2374, 2409:2446, 2471:2523, 2524:2526,
                              2527:2548, 2583:2609, 2626:2627, 2628:2645, 2646:2655, 
                              2656:2661, 2662:2663, 2683:2684, 2685, 2687, 2688, 2689:2691,
                              2219, 2063, 1944:1947, 1938)]

### Exploratory Data Analysis

# Data structure

dim(new_drug_data) # Review dimensions of the data

str(new_drug_data) # Review the structure of the data 

# Data Distribution

# Age

# Change feature to factor and add levels per code book
new_drug_data$CATAGE <- as.factor(new_drug_data$CATAGE)
levels(new_drug_data$CATAGE) <- c("12-17", "18-25", "26-34", "35 or Older")
table(new_drug_data$CATAGE)

# Plot data
library(ggplot2)
bar_age <- ggplot(data = new_drug_data, aes(x = CATAGE))
bar_age + geom_bar() +
  xlab("Age") + ylab("Count") + ggtitle("Bar plot of Age Categories")

# Gender

# Change feature to factor and add levels per code book
new_drug_data$IRSEX <- as.factor(new_drug_data$IRSEX)
levels(new_drug_data$IRSEX) <- c("Male", "Female")
table(new_drug_data$IRSEX)

# Plot data
bar_sex <- ggplot(data = new_drug_data, aes(x = IRSEX))
bar_sex + geom_bar() +
  xlab("Gender") + ylab("Count") + ggtitle("Bar plot of Gender")

# Race

# Change feature to factor and add levels per code book
new_drug_data$NEWRACE2 <- as.factor(new_drug_data$NEWRACE2)
levels(new_drug_data$NEWRACE2) <- c("White", "Black", "Native Am/AK Native",
                                    "Native HI/Other Pac Isl", "Asian", "More than one race",
                                    "Hispanic")
table(new_drug_data$NEWRACE2)

# Plot data
bar_race <- ggplot(data = new_drug_data, aes(x = NEWRACE2))
bar_race + geom_bar() + coord_flip()
xlab("Race") + ylab("Count") + ggtitle("Bar plot of Race Categories")

# Income

# Change feature to factor and add levels per code book
new_drug_data$INCOME <- as.factor(new_drug_data$INCOME)
levels(new_drug_data$INCOME) <- c("Less than $20,000", "$20,000 - $49,999", "$50,000 - $74,999", "$75,000 or More")
table(new_drug_data$INCOME)


# Plot data
bar_income <- ggplot(data = new_drug_data, aes(x = INCOME))
bar_income + geom_bar() +
  xlab("Income") + ylab("Count") + ggtitle("Bar plot of Income")


# Employment

# Change feature to factor and add levels per code book
new_drug_data$IRWRKSTAT <- as.factor(new_drug_data$IRWRKSTAT)
levels(new_drug_data$IRWRKSTAT) <- c("Employed Full Time", "Employed Part Time", "Unemployed", "Other", "Underage")
table(new_drug_data$IRWRKSTAT)

# Plot data
bar_work <- ggplot(data = new_drug_data, aes(x = IRWRKSTAT))
bar_work + geom_bar() +
  xlab("Work Status") + ylab("Count") + ggtitle("Bar plot of Work Status")

# Location

# Change feature to factor and add levels per code book
new_drug_data$COUTYP4 <- as.factor(new_drug_data$COUTYP4)
levels(new_drug_data$COUTYP4) <- c("Large Metro", "Small Metro", "Non-Metro")
table(new_drug_data$COUTYP4)

# Plot data
bar_loc <- ggplot(data = new_drug_data, aes(x = COUTYP4))
bar_loc + geom_bar() +
  xlab("Location") + ylab("Count") + ggtitle("Bar plot of Location")

# Mental Health

# Adult Mental Health Distress

# Change feature to factor and add levels per code book
new_drug_data$MI_CAT_U <- as.factor(new_drug_data$MI_CAT_U)
levels(new_drug_data$MI_CAT_U) <- c("No MI", "Mild MI", "Moderate MI", "Serious MI", "N/A")
table(new_drug_data$MI_CAT_U)

# Plot data
bar_mi <- ggplot(data = new_drug_data, aes(x = MI_CAT_U))
bar_mi + geom_bar() +
  xlab("Mental Illness Category") + ylab("Count") + ggtitle("Bar plot of MI Categories")

### Change Data to Numeric

drug_data[1:2691] <- lapply(drug_data[1:2691], as.numeric)

### Check For Missing Values

sum(is.na(new_drug_data)) # sums missing data for the entire data set

colSums(is.na(new_drug_data)) # Returns missing data by column
new_drug_data[is.na(new_drug_data)] <- 98 # Replace missing data with "98" ; per code book is the value for "Unknown" 
colSums(is.na(new_drug_data)) # Verify missing values have been replaced with "98"

### Checking the balance of the target variable

new_drug_data$OPINMYR <- as.factor(new_drug_data$OPINMYR) # Change feature to factor
levels(new_drug_data$OPINMYR) <- c("No", "Yes") # Add levels per code book

table(new_drug_data$OPINMYR)
prop.table(table(new_drug_data$OPINMYR)) # Add percentages to table

# Plot data
bar_ops <- ggplot(data = new_drug_data, aes(x = OPINMYR))
bar_ops + geom_bar() +
  xlab("Opioid Use") + ylab("Count") + ggtitle("Bar plot of Opioid Use")

### Balancing and oversampling the data

library(ROSE) # Random oversampling example
drug_over <- ovun.sample(OPINMYR ~ ., data = new_drug_data, method = "over", N = 107850)$data # function to oversample minority class and balance the target variable
table(drug_over$OPINMYR) # Verify that the target variable is balanced

### Feature Selection Using Boruta

# Scale down the data set, run Boruta on 1% of data set to save on time
set.seed(1234)
small_drug_data <- sample(2, nrow(drug_over), replace=TRUE, prob=c(0.99, 0.01))
small_drug_sample <- drug_over[small_drug_data == 2, ] # 1% of data set

library(Boruta)
boruta_out <- Boruta(OPINMYR ~ ., data = small_drug_sample, doTrace = 2) # create boruta model

print(boruta_out) # print results of model

boruta_signif <- names(boruta_out$finalDecision[boruta_out$finalDecision %in% c("Confirmed", "Tentative")]) # Print list of attributes
print(boruta_signif)

plot(boruta_out, cex.axis = .7, las = 2, xlab = "", main = "Variable Importance") # plot variable importance

# Create dataframe of attributes; assists with creation of new dataframe for new variables
getSelectedAttributes(boruta_out, withTentative = T)
boruta.df <- attStats(boruta_out)
print(boruta.df)


# Create New Dataset Using Boruta Results

drug_data2 <- drug_over[c("HERFLAG", "HERYR", "HERMON", "PNRANYFLAG", "PNRANYYR", "CATAGE", "MI_CAT_U", "INCOME", "IRSEX",
                          "PSYANYFLAG", "PSYANYYR", "PNRNMFLAG", "PNRNMYR", "PNRNMMON",
                          "PSYCHFLAG", "PSYCHYR", "PSYCHMON", "HERPNRYR", "ILLFLAG", "ILLYR",
                          "ILLMON", "MJONLYFLAG", 'MJONLYYR' , 'ILLEMFLAG' , 'ILLEMYR' , 'ILLEMMON' , 
                          'ILTOBALCFG', 'ILTOBALCYR', 'ILLANDALC', 'ILLORALC', 'ILLALCFLG', 'HYDCPDAPYU',
                          'OXCOPDAPYU', 'CODEPDAPYU', 'MTDNPDAPYU', 'HYDCPDPYMU', 'OXCOPDPYMU', 'TRAMPDPYMU',
                          'CODEPDPYMU', 'PNROTHPYMU2', 'HERYDAYS', 'PNRNDAYPM', 'PNRMAINRSN', 'SRCPNRNM2', 'SRCFRPNRNM',
                          'SRCCLFRPNR', 'ANYNDLREC', 'CHMNDLREC', 'HERSMOK2', 'DEPNDPYIEM', 'ABODHER', 'UDPYOPI', 
                          'UDPYHRPNR', 'UDPYILL', 'UDPYIEM', 'UDPYILAL', 'DUDNOAUD', 'DRVINHERN', 'HERAGLST', 'HERYLU',
                          'HERMLU', 'METHAGLST', 'METHMOLST', 'COCYRBFR', 'TXYRNDILL', 'TXYRNDILAL', 'OPINMYR')]

### Random Forest

# Make sure target variable is a factor
drug_data2$OPINMYR <- as.factor(drug_data2$OPINMYR)
levels(drug_data2$OPINMYR) <- c("No", "Yes")

# Load libraries
library(randomForest)

# Create test and train data set
set.seed(234)
ind = sample(2, nrow(drug_data2), replace = TRUE, prob=c(0.75, 0.25))

training_set = drug_data2[ind == 1,]
testing_set = drug_data2[ind == 2,]

# Train model using training data
drg_forest <- randomForest(OPINMYR ~ ., data = training_set, importance = TRUE)

# Summary of the model
drg_forest

# Create predictions
drg_forest_pred <- predict(drg_forest, testing_set, type = "class")

# Evaluate model
table(drg_forest_pred, testing_set$OPINMYR)
importance(drg_forest)
varImpPlot(drg_forest)

### Establish Revised Dataset

drug_data_final <- drug_over[c("CATAGE", "IRSEX", "NEWRACE2", "INCOME", "IRWRKSTAT", "COUTYP4", "MI_CAT_U", "PNRMAINRSN",
                               "TOBFLAG", "OPINMYR")]

### Change target variable to a factor and create levels per code book
drug_data_final$OPINMYR <- as.factor(drug_data_final$OPINMYR)
levels(drug_data_final$OPINMYR) <- c("No", "Yes")

### Random Forest

# Create test and train data set
set.seed(234)
ind = sample(2, nrow(drug_data_final), replace = TRUE, prob=c(0.75, 0.25))

training_set2 = drug_data_final[ind == 1,]
testing_set2 = drug_data_final[ind == 2,]

# Train model using training data
drg_forest2 <- randomForest(OPINMYR ~ ., data = training_set2, importance = TRUE)

# Summary of the model
drg_forest2

# Create predictions
drg_forest_pred2 <- predict(drg_forest2, testing_set2, type = "class")

# Evaluate model
table(drg_forest_pred2, testing_set2$OPINMYR)
importance(drg_forest2)
varImpPlot(drg_forest2)

