# -*- coding: utf-8 -*-
"""
Created on Wed Apr 11 11:26:23 2018

@author: jglasskatz
"""

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import colors as c
from mpl_toolkits.basemap import Basemap, shiftgrid
import numpy as np
import os
import scipy.stats as st
import matplotlib.animation


#Read in the data
#go to appropriate directory
os.chdir('C:\\Users\\jglasskatz\\Desktop\\CNRA_DATA')

#make csvs df
gwm = pd.read_csv('continuousgroundwatermonthly.csv')
stat = pd.read_csv('gwlstations.csv')
#merge to get relevant data set
gw = gwm.merge(stat, how ='left', on = 'STATION')
#Relevant depths
gw = gw[:][gw['GSE_WSE']>0]
#Get a bunch of different data sets with unique dates
Utime =pd.unique(gw['MSMT_DATE'])
datedata  =[]
for time in Utime:
    df = gw[:][gw['MSMT_DATE']==time]
    datedata.append(df)

#make a list of the ones with 100 samples or more
dfs = []
for df in datedata:
    #print(df.shape)
    if(df.shape[0]>100):
        dfs.append(df)
lons = []
lats = []
depths = []
dates = []
os.chdir('C:\\Users\\jglasskatz\\Desktop\\Depth_Im')
for i in range(0, len(dfs)):
#Do a tester
    test = dfs[i]
    test2 = test.reset_index()
    #They are the same so all unique)
    
    #Get data
    x1 = test2['LONGITUDE'][:]
    y1 = test2['LATITUDE'][:]
    depth = test2['GSE_WSE'][:]
    
    fig = plt.figure(figsize=[10,10])
    # specify (nrows, ncols, axnum)
    ax = fig.add_subplot(1, 1, 1)
    #Title
    ax.set_title('Groundwater Depth for ' + test2['MSMT_DATE'][0], fontsize = 14)
    
    map = Basemap(projection='cyl',llcrnrlat=32.5,urcrnrlat=42.5,llcrnrlon=-125,urcrnrlon=-115,resolution='c', ax=ax)
    #fill it in a bit
    map.drawcoastlines()
    map.drawmapboundary (fill_color='aqua', zorder =1)
    map.fillcontinents (color='#cc9955', zorder =2)
    map.drawstates(zorder =3)
    lon, lat = map(x1,y1)
    lons.append(lon)
    lats.append(lat)
    dates.append(test2['MSMT_DATE'][0])
    depths.append(depth)
    cs = map.scatter(lon, lat, c=depth, cmap='gnuplot', zorder=4)
    fig.colorbar(cs, orientation = 'horizontal')
    #fig.savefig(test2['MSMT_DATE'][0]+'.png')


#################################
#################################    
#Make an animation
#The figure to be animated    
fig = plt.figure(figsize=[8,8])
# specify (nrows, ncols, axnum)
ax = fig.add_subplot(1, 1, 1)
ax.set_title('Groundwater Depth for ' + dates[0], fontsize = 14)
    
map = Basemap(projection='cyl',llcrnrlat=32.5,urcrnrlat=42.5,llcrnrlon=-125,urcrnrlon=-115,resolution='c', ax=ax)
    #fill it in a bit
map.drawcoastlines()
map.drawmapboundary (fill_color='aqua', zorder =1)
map.fillcontinents (color='#cc9955', zorder =2)
map.drawstates(zorder =3)
cs = map.scatter(lons[0], lats[0], c=depths[0], cmap='gnuplot', zorder=4)
fig.colorbar(cs, orientation = 'horizontal')

def update(i):
    ax.set_title('Groundwater Depth for ' + dates[i], fontsize = 14)
    cs = map.scatter(lons[i], lats[i], c=depths[i], cmap='gnuplot', zorder=4)
    
ani = matplotlib.animation.FuncAnimation(fig, update, frames=len(dates), repeat=True)    
ani.save('GWEbyMonth.mp4', writer=writer)

#Zoomed in version
#map = Basemap(projection='cyl',llcrnrlat=min(y1)-.2,urcrnrlat=max(y1)+.2,llcrnrlon=min(x1)-1,urcrnrlon=max(x1)+1,resolution='c', ax=ax)