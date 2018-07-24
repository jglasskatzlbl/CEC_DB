# -*- coding: utf-8 -*-
"""
Created on Tue Apr 17 13:11:01 2018

@author: jglasskatz
"""

#Script to standardize volume
import pandas as pd
import sqlite3
import os

dir = 'C:\\Users\\jglasskatz\\Desktop'
os.chdir(dir)
conn = sqlite3.connect('DBworkbook.sqlite')
cur = conn.cursor()



pump = pd.read_sql_query('SELECT*FROM Pump_Well', conn)
ag = pd.read_sql_query('SELECT*FROM Agency', conn)
merg = pd.merge(pump, ag, how = 'left', left_on ='Agency', right_on ='Name')
unit = pd.unique(ag['Water_Unit'])

#Convert everything to ac-ft

uc = {}

uc['ac-ft'] = 1
uc['gal'] = 3.0689e-6
uc['mi gal'] = 3.0689
uc['miGal'] = 3.0689
uc['kGal'] = .0030689
uc['th gal'] = .0030689

merg['reg'] = merg['Water_Unit'].replace(uc)

to_db = []

for i in range(0,len(merg)):
    ind = i+1
    reg = merg['reg'][i]
    try:
        vreg = reg*merg['Volume_local_unit'][i]
    except:
        vreg = None
    to_db.append((vreg,ind))
try:
    cur.execute('ALTER TABLE Pump_Well ADD Volume_ac_ft REAL')
except:
    print("Don't do that")
cur.executemany('''UPDATE Pump_Well SET Volume_ac_ft =? WHERE rowid = ?''', to_db)
#Save
conn.commit()

#create the Pumcas table
cur.execute('''CREATE TABLE Pumpcas AS SELECT*FROM Pump_Well
LEFT OUTER JOIN CASGEMGWE ON Pump_Well.CasID = CASGEMGWE.CID
AND Pump_Well.Year_Month = CASGEMGWE.YM;''')

#get values from casgem
cur.execute('''UPDATE Pumpcas SET Depth_ft = Depth WHERE Depth_ft IS NULL AND Depth IS NOT NULL;''')
#The rest should be averaged.
conn.commit()
conn.close()
