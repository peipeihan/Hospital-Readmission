# Importing Data using pandas
#267 columns
import matplotlib.pyplot as plt
import pandas as pd
#import numpy as np

# import dataset
filename = 'C:\Users\peipe\Desktop\Hospital Readm\NRD sample data\NRD_head_100K.csv'
data = pd.read_csv(filename) 
data.head()
data_array = data.values
 
# check the column names    
list(data.columns.values)

### count the NRD_VisitLink to get the people who go to hospital more than once
# grouped = data.groupby(func, axis=0).mean()
gc = data.groupby(["NRD_VisitLink"]).size().reset_index(name='count')
merge_result= pd.merge(data, gc, on='NRD_VisitLink', how='left')


#NRD_DaysToEvent
#"The timing variable (NRD_DaysToEvent) was calculated consistently for each verified patient linkage (NRD_visitLink) based on a randomly assigned ""start date."" Each patient linkage is assigned a unique start date that is used to calculate NRD_DaysToEvent for all visits associated with that visitLink value. The variable NRD_DaysToEvent is the difference between the visit's admission date and the start date associated with the visitLink. 

#For example:
#A patient with congestive heart failure that has a 3-day hospital admission on 1/10/13 and another inpatient stay on 1/25/13.
#Suppose the NRD_DayToEvent value is ""1109"" for the 1/10/13 admission and the NRD_DayToEvent value is ""1124"" for the 1/25/13 stay.
#The number of days between the start of each admission is 15 days (1124 - 1109 = 15)
#Readmission analyses often consider the time between the end of one admission and the start on the next admission. The number of days between the admissions (from discharge date of the first admission to the start of the second admission) is 12 days (1124 -1109 - 3 = 12) because the patient had a 3-day length of stay."

# ReAdmission
Pre_readmission = merge_result.loc[merge_result['count']>1].sort(['NRD_VisitLink','NRD_DaysToEvent'],ascending = [1,0])

#df.loc[:,['B', 'A']] = df[['A', 'B']]
readm_label = Pre_readmission[['NRD_VisitLink','NRD_DaysToEvent','LOS','KEY_NRD']]
readm_label["RN"] = range(1,readm_label.shape[0]+1)  #reset index to do the calculateion of readmission day gap

readm_label1 = Pre_readmission[['NRD_VisitLink','NRD_DaysToEvent','LOS','KEY_NRD']]
readm_label1["RN"] = range(0,readm_label.shape[0])

#self join to get the same person's 
s1 = pd.merge(readm_label, readm_label1, how='inner', on=['NRD_VisitLink', 'RN'])
s1["ReadmDayGap"]= s1['NRD_DaysToEvent_x']-s1['NRD_DaysToEvent_y']-s1['LOS_y']
s1["ReadmLabel"] = s1['ReadmDayGap']<=30

### this person went to hospital three times.
#s1["NRD_VisitLink"] == "bq27y5j"
#a = s1.query(''' NRD_VisitLink == 'bq27y5j' ''')


### Now we get the ReadmLabel for the whole dataset
data_label = pd.merge(data, s1, left_on='KEY_NRD', right_on = "KEY_NRD_y", how='left')
data["ReadmLabel"] = data_label["ReadmLabel"] ==True

#check how many people g
#sum(data['ReadmLabel'] ==True)


data.to_csv("C:\Users\peipe\Desktop\Hospital Readm\NRD sample data\NRD_head_100K_Readmlabel.csv")

#Plots in matplotlib reside within a figure object, use plt.figure to create new figure
fig=plt.figure()
#Create one or more subplots using add_subplot, because you can't create blank figure
ax = fig.add_subplot(1,1,1)
data['ReadmLabel'].hist() 
#Variable
ax.hist(data['LOS:DRG_NoPOA'],bins = 5)
#Labels and Tit
plt.title('LOS distribution')
plt.xlabel('LOS')
plt.ylabel('#Employee')
plt.show()
