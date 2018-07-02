### Author: Fei He <feh@microsoft.com>
### Purpose: Convert all excel files into cleaned csv files for later text mining 
 

rm(list=ls())
gc()

library(CosmosToR)
library(dplyr)
#library(plyr)  # detach(package:plyr)
library(data.table)
library(ggplot2)
library(caret)
library(scales)
library(janeaustenr)
library(tidytext)
library(openxlsx)

path <- paste0("D:/HackforGood/")

### Read in data ######
file_names <- c("Burn Care", "Cardiology", "Clinical Trials", "Craniofacial",
				"Dentistry", "Medicine", "Mental Health1", "Mental Health2", "Nephrology", "Neurology",
				"Oncology", "Ophthalmology", "Orthopaedics", "OrthoticsProsthetics", "Pulmonology",
				"Rehabilitation", "Special Ed", "Urology")

## Simple data cleaning
for (name in file_names) {
data_raw <- read.xlsx(paste0(path, "org_data/", name, ".xlsx"), colNames = F)
######### Organization data ########
data_use <- data_raw[,c(2,3)]
colnames(data_use) <- c("organization_name", "Description")
data_use <- data_use[!is.na(data_use$organization_name),]
data_use <- data_use[!is.na(data_use$Description),]
data_use <- data_use[!data_use$organization_name %in% c("Organization Name:", "Organization Name :", "Organization Name: ", "Organization Name : ",
														 "Hospital Name:", "Hospital Name :", "Hospital Name: ", "Hospital Name : "), ]
data_use <- data_use[!data_use$Description %in% c("Description", "Desciption:", "Desciption :", "Desciption: ", "Desciption : "), ]

write.csv(data_use, paste0(path, "/clean_data/", name, ".csv"), row.names=F)

}