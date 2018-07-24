# -*- coding: utf-8 -*-
"""
Created on Tue May 22 15:52:03 2018

@author: jglasskatz
"""

import pandas as pd
import os
import sqlite3

dir = 'C:\\Users\\jglasskatz\\Desktop'
os.chdir(dir)

conn = sqlite3.connect('DBworkbook.sqlite')
cur = conn.cursor()

vols = pd.read_csv('Annual_Volumes_edit.csv')
pump = pd.read_sql_query('SELECT*FROM Pumpcas', conn)

agents = pd.unique(pump['Agency'])
vols1 = vols[vols['Agency'] == 'Alameda County WD']

#prep in excel to match names

for agent in agents:
    vols1 = vols1.append(vols[vols['Agency'] == str(agent)])

#need .copy() to make a copy, o/w just renaming the file
weights = vols1.copy()

#clean the index
weights.reset_index(inplace = True)

#parse through, sum volumes, make weights
#use the index to go row by row
#also make the dictionary key to replace vals
agedic = {}
for index in weights.index:
    #use iloc to lock onto the row index, take the 4: volume cols
    w = sum(weights.loc[index,'2006':])
    #divide each column by w
    weight = list(weights.loc[index,'2006':].values/w)
    weight.append(w)
    agedic[weights.loc[index,'Agency']] = weight



#Need to make the var excusively numeric
pump['Volume_ac_ft'] = pd.to_numeric(pump.loc[:,'Volume_ac_ft'], errors = 'coerce')

#Take the relevant data (the nulls)
pump1 = pump[pump.loc[:,'Volume_ac_ft'].isnull()]

#agedic  contains the weights (0:10)  and the total (11)
#These can be used as a map to give volume to those missing.
for agent in agents:
    df = pump1[pump1.loc[:,'Agency'] == agent]
    size = len(pump[pump.loc[:,'Agency'] == agent])

    if((agent in agedic) & (size >0)):
        divs = agedic[agent][-1]/size
        newline = [i * divs for i in agedic[agent][0:-1]]
        for date in range(2006, 2016):
            pump1.loc[((pump1['Agency'] == agent) & (pump1['Year_Month'].str.contains(str(date)))), 'Volume_ac_ft'] = newline[date-2006]

#Weird because you get an error message but it ends up working

#update the db
#to_db = []
#for i in pump1.index:
#    vol = pump1.loc[i,'Volume_ac_ft']
#    date = pump1.loc[i,'Year_Month']
#    wellid = pump1.loc[i,'Well_Id']
#    to_db.append((vol,wellid, date))

#cur.executemany('''UPDATE Pumpcas SET Volume_ac_ft = ? WHERE Well_Id = ? AND Year_Month = ?;''',to_db)

#try using row id instead bc really slow
to_db1 = []
for i in pump1.index:
    vol = pump1.loc[i,'Volume_ac_ft']
    rowid = i+1
    to_db1.append((vol,rowid))

cur.executemany('UPDATE Pumpcas SET Volume_ac_ft = ? WHERE rowid =?;',to_db1)
conn.commit()
conn.close()
