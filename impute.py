#Input pump clean
import pandas as pd
import sqlite3
import os

dir = 'C:\\Users\\jglasskatz\\Desktop'
os.chdir(dir)
conn = sqlite3.connect('DBworkbook.sqlite')
cur = conn.cursor()


pclean = pd.read_csv("Pumpclean.csv")

pclean.to_sql('PumpingClean', conn, if_exists = 'append', index = False)
