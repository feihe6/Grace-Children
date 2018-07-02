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
patient_data_raw <- fread(paste0(path, "patient_data.csv"), header=F)
Burn_data <- read.xlsx(paste0(path, "org_data/Burn Care.xlsx"), colNames = F)



### Patient data ###
patient_data <- patient_data_raw[1:38,1:13]
patient_data <- t(patient_data)
colnames(patient_data) <- patient_data[1,]
colnames(patient_data) <- gsub(" ", "_", colnames(patient_data))
colnames(patient_data) <- gsub("/", "_", colnames(patient_data))
patient_data <- data.table(patient_data[-1,])
subs_names <- c("Patient", "Malady", "Hospital", "NGOs_Nonprofits", "Doctor(s)")
patient_data_use <- patient_data[,.(Patient, Malady, Hospital, NGOs_Nonprofits)]

write.csv(patient_data_use, paste0(path, "/clean_data/patient_data_use.csv"), row.names=F)


### Information that can be directly used ###
Country_of_origin
Government_Documentation
Travel
###
Hospital
NGOs_Nonprofits
Doctor(s)
International_Funding_Programs



#### Apply tf-idf on partient data ###
### Malady ###
patient_malady <- patient_data_use %>%
  unnest_tokens(malady, Malady) %>%
  group_by(Patient, malady) %>% 
  count() %>% 
  ungroup()

# total_malady <- patient_malady %>%
#   group_by(Patient) %>%
#   summarise(total=sum(n)) %>% 
#   ungroup()

# patient_malady <- left_join(patient_malady, total_malady, by="Patient")

patient_malady <- patient_malady %>%
  bind_tf_idf(malady, Patient, n) %>%
  arrange(desc(tf_idf))



### Hospital ##
patient_hospital <- patient_data_use %>%
  unnest_tokens(hospital, Hospital) %>%
  group_by(Patient, hospital) %>% 
  count() %>% 
   bind_tf_idf(hospital, Patient, n) %>%
  arrange(desc(tf_idf)) %>%
  ungroup()

### NGOs ###
patient_NGOs <- patient_data_use %>%
  unnest_tokens(NGOs, NGOs_Nonprofits) %>%
  group_by(Patient, NGOs) %>% 
  count() %>% 
   bind_tf_idf(NGOs, Patient, n) %>%
  arrange(desc(tf_idf)) %>%
  ungroup()


######### Organization data ########
Burn_data_use <- Burn_data[,c(2,3)]
colnames(Burn_data_use) <- c("organization_name", "Description")
Burn_data_use <- Burn_data_use[!is.na(Burn_data_use$organization_name),]
Burn_data_use <- Burn_data_use[!is.na(Burn_data_use$Description),]
Burn_data_use <- Burn_data_use[!Burn_data_use$organization_name %in% c("Hospital Name:", "Organization Name :", "Organization Name:", "Organization Name: "), ]
Burn_data_use <- Burn_data_use[!Burn_data_use$Description %in% c("Description", "Desciption:"), ]
Burn_data_use$type <- "Burn_care"

write.csv(Burn_data_use, paste0(path, "/clean_data/Burn_care.csv"), row.names=F)

### Apply tf-idf on organization data ###
org_description <- Burn_data_use %>%
  unnest_tokens(description, Description) %>%
  group_by(organization_name, description) %>% 
  count() %>% 
  bind_tf_idf(description, organization_name, n) %>%
  arrange(desc(tf_idf)) %>%
  ungroup()



### Find cosine similarity between patients ######
### Hospital ##
patient_hospital_vec <- data.table(patient_hospital)
patient_hospital_vec <- patient_hospital_vec[,.(Patient, hospital, tf_idf)]
patient_hospital_wide <- dcast(patient_hospital_vec, Patient ~ hospital, value.var="tf_idf", fill=0)
patient_hospital_t <- t(patient_hospital_wide[,-1])
patient_hosp_cos_similarity <- cosine(patient_hospital_t)
colnames(patient_hosp_cos_similarity) <- unlist(patient_hospital_wide[,1])
rownames(patient_hosp_cos_similarity) <- unlist(patient_hospital_wide[,1])
patient_hosp_cos_similarity_long <- melt(patient_hosp_cos_similarity)
colnames(patient_hosp_cos_similarity_long) <- c("Patient1", "Patient2","cosine_similarity")
patient_hosp_cos_similarity_long <- patient_hosp_cos_similarity_long[patient_hosp_cos_similarity!=1,]  ## get rid of self correlated
patient_hosp_cos_similarity_long <- patient_hosp_cos_similarity_long[order(patient_hosp_cos_similarity_long$Patient1, -patient_hosp_cos_similarity_long$cosine_similarity),]

### Malady ##
patient_malady_vec <- data.table(patient_malady)
patient_malady_vec <- patient_malady_vec[,.(Patient, malady, tf_idf)]
patient_malady_wide <- dcast(patient_malady_vec, Patient ~ malady, value.var="tf_idf", fill=0)
patient_malady_t <- t(patient_malady_wide[,-1])
patient_malady_cos_similarity <- cosine(patient_malady_t)
colnames(patient_malady_cos_similarity) <- unlist(patient_malady_wide[,1])
rownames(patient_malady_cos_similarity) <- unlist(patient_malady_wide[,1])
patient_malady_cos_similarity_long <- melt(patient_malady_cos_similarity)
colnames(patient_malady_cos_similarity_long) <- c("Patient1", "Patient2","cosine_similarity")
patient_malady_cos_similarity_long <- patient_malady_cos_similarity_long[patient_malady_cos_similarity!=1,]  ## get rid of self correlated
patient_malady_cos_similarity_long <- patient_malady_cos_similarity_long[order(patient_malady_cos_similarity_long$Patient1, -patient_malady_cos_similarity_long$cosine_similarity),]




### Find similarity between organizations ###
org_description_vec <- data.table(org_description)
org_description_vec <- org_description_vec[,.(organization_name, description, tf_idf)]
org_description_wide <- dcast(org_description_vec, organization_name ~ description, value.var="tf_idf", fill=0)
org_description_t <- t(org_description_wide[,-1])
org_descp_cos_similarity <- cosine(org_description_t)
colnames(org_descp_cos_similarity) <- unlist(org_description_wide[,1])
rownames(org_descp_cos_similarity) <- unlist(org_description_wide[,1])
org_descp_cos_similarity_long <- melt(org_descp_cos_similarity)
colnames(org_descp_cos_similarity_long) <- c("Organization1", "Organization2","cosine_similarity")
org_descp_cos_similarity_long <- org_descp_cos_similarity_long[org_descp_cos_similarity!=1,]  ## get rid of self correlated
org_descp_cos_similarity_long <- org_descp_cos_similarity_long[order(org_descp_cos_similarity_long$Organization1, -org_descp_cos_similarity_long$cosine_similarity),]




