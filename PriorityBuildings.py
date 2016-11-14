#Author: Ásgeir Örn Sigurpálsson
# update tpr@hi.is: 4 nov 2016
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
with open('bordarodun4.csv',"r",encoding='latin-1', newline='') as csvfile:

    RoomData = csv.reader(csvfile, delimiter=';')
    next(RoomData)
    for rows in RoomData:
        for i in range(6):
            DI[i][rows[2]] = rows[i+1]
with open('PriorityBuildings.dat','w', encoding=_wenc) as fdat:
    for course, blist in DI[0].items():
        s = 'set PriorityBuildings['+course.translate(_trans)+']:='
        fdat.write(s)
        if blist =='11' or blist=='12' or blist=='13' or blist=='14' or blist=='15':
            fdat.write('Haskolatorg')
            fdat.write(';')
        if blist == "16":
            fdat.write('Haskolatorg')
            fdat.write(';')
# @21 Hvernig er þetta með sérúrræðanemana - þarf ekki að forgangsraða þeim sérstaklega? Málið er að þó hjúkrunarfræðin "verði" að vera í Eirbergi þá verða sérúrræðanemar þeirra að vera í Aðalbyggingu eða Háskólatorgi. Í Ht302 er t.d. sérhæfður hugbúnaður sem ekki er hægt að setja upp í öllum tölvuverum.
        if blist=='21':
            fdat.write('Eirberg')
            fdat.write(';')
        if blist=='22':
            fdat.write('VRII')
            fdat.write(';')
        if blist=='23':
            fdat.write('Eirberg')
            fdat.write(';')
        if blist=='24':
            fdat.write('Adalbygging')
            fdat.write(';')
        if blist=='25':
            fdat.write('Oddi')
            fdat.write(';')
        if blist=='26':
            fdat.write('Eirberg')
            fdat.write(';')
        if blist =='31' or blist=='32' or blist=='33' or blist=='34':
            fdat.write('Arnagardur')
            fdat.write(';')
        if blist =='41' or blist=='42' or blist=='43':
            fdat.write('Hamar')
            fdat.write(';')
        if blist =='51' or blist =='54' or blist=='56':
            fdat.write('VRII')
            fdat.write(';')
        if blist =='52' or blist =='53':
            fdat.write('Askja')
            fdat.write(';')
        if blist =='55':
            fdat.write('VRII')
            fdat.write(';')

        fdat.write('\n')
