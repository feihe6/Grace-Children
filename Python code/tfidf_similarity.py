### Author: Fei He <feh@microsoft.com>
### Purpose: calculate cosine_similarity based on tf-idf from the organization description
 

## Import functions
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity  

## File names 
file_names = ["Burn Care", "Cardiology", "Craniofacial", "Dentistry", "Medicine", "Mental Health1", "Mental Health2", "Nephrology", "Neurology", "Oncology", "Ophthalmology", "Orthopaedics", "Pulmonology", "Rehabilitation", "Urology"]
## empty files: "Clinical Trials", "Special Ed", "OrthoticsProsthetics"

## Loop the similarity calculation over all files 
cos_simi_data_all = pd.DataFrame([])
for i in range(0, (len(file_names)-1)):
    ## Read in cleaned data 
    data_input_path = "D:/HackforGood/clean_data/" + file_names[i] + ".csv"
    data_raw = pd.read_csv(data_input_path, encoding = "ISO-8859-1", error_bad_lines=False)
    #print(data_raw)

    ## Subset the data for later use
    all_documents = data_raw.iloc[:, 0:2].copy()
    print(all_documents)
    
    ## calculate the tf-idf 
    vectorizer = TfidfVectorizer(min_df=0)
    tfidf_matrix = vectorizer.fit_transform(all_documents.iloc[:,1].values.astype('U'))
    #print(tfidf_matrix)
    
    ## output the tf-idf matrix to a dataframe
    feature_names = vectorizer.get_feature_names()
    org_index = [n for n in all_documents.iloc[:,0]]
    tfidf_data = pd.DataFrame(tfidf_matrix.todense(), index=org_index, columns=feature_names)
    #print(tfidf_data)
    ## Output tfidf file for key words
    tfidf_output_path = "D:/HackforGood/tfidf output/" + file_names[i] + "_tfidf.csv"
    tfidf_data.to_csv(tfidf_output_path)
    
    ## Take the tf-idf matrix and calculate the cosine similarity 
    cosine = cosine_similarity(tfidf_matrix, tfidf_matrix)
    ## prep the dataframe 
    org_first = np.repeat(org_index, cosine.shape[0])
    org_second = org_index*int(cosine.shape[0])
    #cos_simi_data = pd.DataFrame(cosine.ravel(), index=[org_first, org_second], columns=["cosine_similarity"])
    cos_simi_data = pd.DataFrame({"org_first" : org_first, "org_second": org_second, "cosine_similarity": cosine.ravel(), "category": file_names[i]})
    cos_simi_data = cos_simi_data[~(cos_simi_data["org_first"] == cos_simi_data["org_second"] ) ]
    cos_simi_data = cos_simi_data.sort_values(by=["cosine_similarity"], ascending=[False])
    cos_simi_data_all = cos_simi_data_all.append(cos_simi_data)
    #print(cos_simi_data)
    
## Output the similarity output 
data_output_path = "D:/HackforGood/similarity output/organization_similarity_table.csv"
cos_simi_data_all = cos_simi_data_all[["org_first", "org_second", "cosine_similarity", "category"]]
cos_simi_data_all.to_csv(data_output_path, index=False)

