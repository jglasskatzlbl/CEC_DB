#Turn spreadsheets into csvs and load them
#get csvs into DB
#put in agency column
#add in casgem data

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

#Make the tables
#Create well table
cur.execute('''CREATE TABLE IF NOT EXISTS Well (Well_ID INT PRIMARY KEY, Local_Well_Number TEXT,
State_Well_Number TEXT, Utility_Id TEXT, Utility_Account TEXT, Utility_Premise TEXT, Latitude REAL,
Longitude REAL, Zip INT, City TEXT, County TEXT, Agency TEXT)''')

#Create agency table
cur.execute('''CREATE TABLE IF NOT EXISTS Agency ( Acronym TEXT NOT NULL UNIQUE, Name TEXT,
Type TEXT, Water_Unit TEXT, Completed_In Text, Comments TEXT)''')

#create pumping table
cur.execute('''CREATE TABLE IF NOT EXISTS Pumping ( Well_Id INT, Year_Month TEXT,
Volume_local_unit REAL, Electricity_kWh REAL, Depth_ft REAL, Draw_Down_ft REAL, Pressure_psi REAL,
Friction_Head REAL, TDH REAL, OPPE REAL, Flow_gpm REAL, HP_Input REAL)''')

#Well info table
cur.execute('''CREATE TABLE IF NOT EXISTS CASGEMWI ( SID TEXT, CASGEMID TEXT,
 County TEXT, totdepth INT, Lat REAL, Long REAL  )''')

#Ground water elevation info
cur.execute('''CREATE TABLE IF NOT EXISTS CASGEMGWE(CID TEXT, YrMo TEXT,
 GSE REAL, WSE REAL, Depth REAL)''')

#read each workbook, upload to DB
for workbook in os.listdir(dir):
    try:
        #connect to the workbook
        wb = pd.ExcelFile(workbook)
        #grab the names and make them into seperate dfs
        names = wb.sheet_names
        fileA = wb.parse(names[0])
        fileW = wb.parse(names[1])
        fileP = wb.parse(names[2])
        #correct the column name errors
        fileA.columns = fileA.columns.str.replace('\s+', '_')
        fileW.columns = fileW.columns.str.replace('\s+', '_')
        fileP.columns = fileP.columns.str.replace('\s+', '_')
        fileP.columns = fileP.columns.str.replace('-', '_')
        fileP.columns = fileP.columns.str.replace('(', '')
        fileP.columns = fileP.columns.str.replace(')', '')
        #load agency
        fileA.to_sql('Agency', conn, if_exists = 'append', index = False)
        #load well and pump
        try:
            #add in the acronym column
            fileW['Agency'] = fileA.iloc[0]['Name']
            fileW.to_sql('Well', conn, if_exists = 'append', index = False)
        except:
            fileW = fileW.iloc[:,:-2]
            fileW['Agency'] = fileA.iloc[0]['Name']
            fileW.to_sql('Well', conn, if_exists = 'append', index = False)
        #And pump
        fileP.to_sql('Pumping', conn, if_exists = 'append', index = False)
    except:
        print(workbook + ' had a problem')
conn.commit()

#Get the Casgem data on there
for csvfile in os.listdir(dir):
    try:
     #if file name contains WI, upload to well
        if 'Wells' in csvfile:
             fnameW = csvfile
             with open(fnameW) as fh:
                 dr = csv.DictReader(fh)
                 to_db = []
                 for i in dr:
                    to_db.append(( i['ï»¿State Well Number'], i['CASGEM Well Number'], i['County'], i['Total Well Depth'], i['Latitude (NAD 83)'], i['Longitude (NAD 83)']))

             cur.executemany('INSERT INTO CASGEMWI ( SID, CASGEMID,County, totdepth, Lat, Long) Values (?,?,?,?,?,?);', to_db)

         #if file name contains agency, upload to agency
        elif 'a0' in csvfile:
            fnameG = csvfile
            try:
                with open(fnameG) as fh:
                    dr = csv.DictReader(fh)
                    to_db = []
                    for i in dr:
                        to_db.append((i['ï»¿CASGEM ID'], i['Date'], i['GS Elevation'], i['WSE'], i['GS to WS']))
            except:
                with open(fnameG) as fh:
                    dr = csv.DictReader(fh)
                    to_db = []
                    for i in dr:
                        to_db.append((i['CASGEM ID'], i['Date'], i['GS Elevation'], i['WSE'], i['GS to WS']))

            cur.executemany('INSERT INTO CASGEMGWE(CID, YrMo, GSE, WSE, Depth) Values (?,?,?,?,?)', to_db)
    except:
        print('Yipes ' + csvfile)
conn.commit()
#Now fix up the dates on the casgem data
try:
    casgwe = pd.read_sql_query('SELECT*FROM CASGEMGWE',conn)

    #put it in date time
    casgwe['YM'] = pd.to_datetime(casgwe['YrMo'])

    #go to just the Month and year
    casgwe['YM'] = casgwe.YM.dt.to_period('M')
    dates = casgwe['YM']

    #and go ahead and update DB
    to_db = []
    i = 0
    while i < len(casgwe):
        date = str(dates[i])
        to_db.append((date,i+1))
        i = i+1

    cur.execute('ALTER TABLE CASGEMGWE ADD YM TEXT')
    cur.executemany('''UPDATE CASGEMGWE SET YM =? WHERE rowid = ?''', to_db)

except:
    print('There was an error fixing up the Casgem dates.')
#Save DB

conn.commit()

#Make the pump dates to proper date time
try:
    fh = cur.execute ('SELECT Year_Month FROM Pumping')
    yrmo = []
    j = 1
    for date in fh:
        date = date[0]
        if '-' in date:
            yrmo.append((date,j))
        else:
            dat = date[0:4] + '-' + date[4:]
            yrmo.append((dat, j))
        j = j+1
    cur.executemany('UPDATE Pumping SET Year_Month =? WHERE rowid = ?;', yrmo)
except:
    print('Error fixing pump dates')

#Save
conn.commit()
#Create the table connecting well and the casgem identifiers
#The CASGEM matches by lat long come from R
#the stateID matches can be done on the DB

#create the columnn for CID
try:
    cur.execute('''ALTER TABLE Well ADD COLUMN CasID TEXT;''')
    #match on the stateID's
    cur.execute('''UPDATE Well SET CasID = (SELECT CASGEMWI.CASGEMID
    FROM CASGEMWI WHERE CASGEMWI.SID = Well.State_Well_Number)
    WHERE NOT Well.State_Well_Number = '';''')
except:
    print("Error with StateID matching")

#Finish up and Save
conn.commit()
conn.close()

#What now must be done is
#Spatial scripts (R then python)
#spatialmatch.py
#correct units on sql
#Volumenorm.py
#imputeavedepth.py
#annualvols.py
#Rscript for RF
#RFImpute_DepthInterpolate.py
