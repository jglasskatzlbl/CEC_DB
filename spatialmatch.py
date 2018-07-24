#LAT LONG SCRIPT AND SOME CLEANING

import pandas as pd
import csv
import sqlite3
import os

#Set the directory to the file with workbooks
dir = 'C:\\Users\\jglasskatz\\'  + input('Enter folder directory \\')
os.chdir(dir)

#establish connection
conn = sqlite3.connect('DBworkbook.sqlite')
cur = conn.cursor()


#Need to do lat long matching
try:
    #open up the file
    fname = 'C:\\Users\\jglasskatz\\Desktop\\Sp_analysis\\wecaslat.csv'
    with open(fname) as fh:
        dr = csv.DictReader(fh)
        to_db = []
        for i in dr:
            ID = i['Well_ID']
            CAS = i['CASGEMID']
            to_db.append((CAS,ID))

    cur.executemany('''UPDATE Well SET CasID =? WHERE Well_ID = ?;''', to_db)
except:
    print('Error with Lat Long matching')
#save
conn.commit()

#Make some known cleaning edits

cur.execute('DELETE FROM Pumping WHERE  Well_Id IS NULL;')
#cur.execute('DELETE FROM Pumping WHERE Year < 2000 OR Year >2017')

#Let's add in all the merges to get the full database
cur.execute('''CREATE TABLE Pump_Well AS SELECT*FROM Pumping
LEFT OUTER JOIN Well ON Well.Well_ID = Pumping.Well_Id;''')

#Save and closely
conn.commit()
conn.close()
