#Author: Ásgeir Örn Sigurpálsson
#Date: 28 oct 2015
#Input: bordarodun.csv
#Type: MessyBessy - Room Scheduling
#Output: RequiredBuilding.dat
#   Makes the dat file RequiredBuildings.dat which includes all of the courses with the prefered their Building.
#The input is a document supplied by the examination director (fyrir bordarodun)
#The document looks like:
#Fræðasvið	Deild	Stuttfagnúmer	Fagheiti	Dagsetning	Staðnemar	Heildarfjöldi	Tegund lokaprófs


import os, csv
from collections import OrderedDict
_trans = str.maketrans('ÁÐÉÍÓÚÝÞÆÖáðéíóúýþæö_ ','ADEIOUYTAOadeiouytao_ ')
_wenc = 'utf_8'

DI = [{} for i in range(6)]

#Verdur ad vera skjal ur bordarodun..Thar koma svidsnumer og fleira fram
with open('bordarodun2.csv',"r",encoding='latin-1', newline='') as csvfile:

    RoomData = csv.reader(csvfile, delimiter=';')
    next(RoomData)
    for rows in RoomData:
        for i in range(6):
            DI[i][rows[2]] = rows[i+1]

            #/*
            #ID number for buildings
            #Adalbygging	1
            #Askja	2
            #Arnagardur	3
            #Eirberg	4
            #Gimli	5
            #Haskolatorg	6
            #Logberg	7
            #Oddi	8
            #VRII	9
            #Hamar	10
            #Klettur	11
            #Enni	12
            #Laugarvatn	13
            #Nýji Garður 14
            #*/


with open('RequiredBuildings.dat','w', encoding=_wenc) as fdat:
    for course, blist in DI[0].items():
        s = 'set RequiredBuildings['+course.translate(_trans)+']:='
        fdat.write(s)
        if blist =='11' or blist=='12' or blist=='13' or blist=='14' or blist=='15' or blist=='16':
            fdat.write('Haskolatorg Oddi Logberg Arnagardur ')
            fdat.write(';')
        if blist=='21':
            fdat.write('Eirberg Adalbygging')
            fdat.write(';')
        if blist=='22' or blist=='23' or blist=='24' or blist=='25' or blist=='26':
            fdat.write('VRII Eirberg Adalbygging Haskolatorg Oddi Arnagardur Oddi')
            fdat.write(';')
        if blist =='31' or blist=='32' or blist=='33' or blist=='34':
            fdat.write('Adalbygging Arnagardur Haskolatorg Logberg Oddi')
            fdat.write(';')
        if blist =='41' or blist=='42' or blist=='43':
            fdat.write('Hamar Klettur Enni')
            fdat.write(';')
        if blist =='51' or blist =='52' or blist =='53' or blist =='54' or blist=='55' or blist=='56':
            fdat.write('VRII Askja Arnagardur Haskolatorg Oddi Adalbygging Eirberg')
            fdat.write(';')

        fdat.write('\n')
