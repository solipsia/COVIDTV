import requests
import json
from xml.dom import minidom
import MySQLdb as mariadb #pip install mysqlclient
from datetime import datetime  
from datetime import timedelta  
from datetime import date
import os

mariadb_connection = mariadb.connect(user='root', password='313920', database='COVID')
try:
    cursor = mariadb_connection.cursor()
except mariadb.Error as err:
    print("Something went wrong: {}".format(err))

response = requests.get("https://api.covid19api.com/countries")#https://api.covid19api.com/total/dayone/country/south-africa
apicountries = response.json()
#for i in range(len(data)):
#    print(data[i]['Country'])
#    print(data[i]['Slug'])

#https://api.covid19api.com/summary

#query = "INSERT INTO waypoints (Lat,Lon,Ele,Date,Source) VALUES ("+str(lat)+","+str(lon)+","+str(ele)+",'"+timestamp.strftime('%Y-%m-%d %H:%M:%S')+"','"+source+"')"

#timestamp=datetime.fromisoformat(timetag[0].firstChild.nodeValue.replace("Z", "+00:00"))query = "SELECT 1"
try:
    query="SELECT name,slug FROM countries"
    cursor.execute(query)
    dbcountries = cursor.fetchall()
except mariadb.Error as err:
    print("Something went wrong: {}".format(err))
mariadb_connection.commit()
print(len(apicountries),'countries pulled from API')
newcountries=0
for apicountry in apicountries:
    #print(apicountry['Slug'])
    if apicountry['Slug'] not in [i[1] for i in dbcountries]:
        #print('Inserting ',apicountry['Slug'])
        newcountries=newcountries+1
        try:
            query="INSERT INTO countries (name,slug,CODE) VALUES ('"+apicountry['Country'].replace("'","")+"','"+apicountry['Slug'].replace("'","")+"','"+apicountry['ISO2'].replace("'","")+"')"
            #print(query)
            cursor.execute(query)
            dbcountries = cursor.fetchall()
        except mariadb.Error as err:
            print("Something went wrong: {}".format(err))
        mariadb_connection.commit()
print(newcountries,'new countries inserted into database')

try:
    query="TRUNCATE TABLE daily"
    cursor.execute(query)
except mariadb.Error as err:
    print("Something went wrong: {}".format(err))
mariadb_connection.commit()

#full data pull and refresh database
totalrowsinserted=0
for apicountry in apicountries:
    try:
        query="SELECT date FROM cumulative WHERE country='"+apicountry['Country'].replace("'","")+"'" #check if this datapoint already exists in db
        #print(query)
        cursor.execute(query)
        dbdates = cursor.fetchall()
    except mariadb.Error as err:
        print("Something went wrong: {}".format(err))

    response = requests.get("https://api.covid19api.com/total/dayone/country/"+apicountry['ISO2'])
    apidata = response.json()
    rowsinserted=0
    for apidatapoint in apidata:
        timestamp=datetime.fromisoformat(apidatapoint['Date'].replace("Z", "+00:00"))
        if str(apidatapoint['Date'])[:str(apidatapoint['Date']).find('T')] not in [str(i[0])[:str(i[0]).find(' ')] for i in dbdates]: #only insert if this date from the API does not exist in the DB for this country
            #insert this datapoint into db
            try:
                query="INSERT INTO cumulative (country,confirmed,deaths,date) VALUES ('"+apicountry['Country'].replace("'","")+"',"+str(apidatapoint['Confirmed'])+","+str(apidatapoint['Deaths'])+",'"+timestamp.strftime('%Y-%m-%d %H:%M:%S')+"')"
                print(query)
                cursor.execute(query)
            except mariadb.Error as err:
                print("Something went wrong: {}".format(err))
            mariadb_connection.commit()
            rowsinserted=rowsinserted+1
            totalrowsinserted=totalrowsinserted+1
    if rowsinserted>0:
        print(rowsinserted,'new cumulative dates inserted for',apicountry['Country'].replace("'",""))
   
    #calculate daily stats for this country
    try:
        query="SELECT country,confirmed,deaths,date FROM cumulative cm WHERE cm.country='"+apicountry['Country'].replace("'","")+"' ORDER BY cm.country,cm.date ASC" #check if this datapoint already exists in db
        cursor.execute(query)
        dbcumu = cursor.fetchall()
    except mariadb.Error as err:
        print("Something went wrong: {}".format(err))
    if len(dbcumu)>1:# and apicountry['Country']=="South Africa": 
        rownum=0
        confirmed7day=[]
        deaths7day=[]
        for row in dbcumu:
            if rownum>0:
                country=row[0]
                confirmed=row[1]-dbcumu[rownum-1][1]
                confirmed7day.append(confirmed)
                deaths=row[2]-dbcumu[rownum-1][2]
                deaths7day.append(deaths)
                date=row[3]

                if len(confirmed7day)>7: #calc rolling 7 day average
                    confirmed7day.pop(0) #remove the first (oldest) datapoint
                    deaths7day.pop(0) #remove the first (oldest) datapoint

                confirmed7dave = sum(confirmed7day) / len(confirmed7day) 
                deaths7dave = sum(deaths7day) / len(deaths7day) 
                #print(country,confirmed,deaths,date)
                try:
                    query="INSERT INTO daily (country,confirmed,deaths,confirmed7dave,deaths7dave,date) VALUES ('"+country+"',"+str(confirmed)+","+str(deaths)+","+"{:.9f}".format(confirmed7dave)+","+"{:.9f}".format(deaths7dave)+",'"+date.strftime('%Y-%m-%d %H:%M:%S')+"')"
                    #print(query)
                    cursor.execute(query)
                except  mariadb.Error as err:
                    print("Something went wrong: {}".format(err))
                mariadb_connection.commit()
            rownum=rownum+1


print(totalrowsinserted,'new dates inserted globally')
mariadb_connection.close()
#create daily data from scratch

