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
with open('bordarodun2.csv',"r",encoding='latin-1', newline='') as csvfile:

    RoomData = csv.reader(csvfile, delimiter=';')
    next(RoomData)
    for rows in RoomData:
        for i in range(6):
            DI[i][rows[2]] = rows[i+1]

with open('RequiredBuildings.dat','w', encoding=_wenc) as fdat:
    for course, blist in DI[0].items():
        s = 'set RequiredBuildings['+course.translate(_trans)+']:='
        fdat.write(s)
        if blist =='11' or blist=='13' or blist=='14' or blist=='15':
            fdat.write('Torfan')
            fdat.write(';')
        if blist == "12":
            fdat.write('Eirberg Torfan')
            fdat.write(';')
        if blist == "16":
            fdat.write('VRII Torfan')
            fdat.write(';')
# @21 Hvernig er þetta með sérúrræðanemana - þarf ekki að forgangsraða þeim sérstaklega? Málið er að þó hjúkrunarfræðin "verði" að vera í Eirbergi þá verða sérúrræðanemar þeirra að vera í Aðalbyggingu eða Háskólatorgi. Í Ht302 er t.d. sérhæfður hugbúnaður sem ekki er hægt að setja upp í öllum tölvuverum. 
        if blist=='21':
            fdat.write('Eirberg Torfan')
            fdat.write(';')
        if blist=='22':
            fdat.write('VRII Torfan')
            fdat.write(';')
        if blist=='23':
            fdat.write('Eirberg Torfan')
            fdat.write(';')
        if blist=='24':
            fdat.write('Adalbygging Torfan')
            fdat.write(';')
        if blist=='25' or blist=='26':
            fdat.write('Torfan')
            fdat.write(';')
        if blist=='26':
            fdat.write('Eirberg Torfan')
            fdat.write(';')
        if blist =='31' or blist=='32' or blist=='33' or blist=='34':
            fdat.write('Torfan')
            fdat.write(';')
        if blist =='41' or blist=='42' or blist=='43':
            fdat.write('Hamar Torfan Klettur Enni')
            fdat.write(';')
        if blist =='51' or blist =='54' or blist=='56':
            fdat.write('VRII Torfan Askja')
            fdat.write(';')
        if blist =='52' or blist =='53':
            fdat.write('Askja Torfan VRII')
            fdat.write(';')
        if blist =='55':
            fdat.write('VRII Torfan Eirberg')
            fdat.write(';')
        if blist =='56':
            fdat.write('VRII Torfan')
            fdat.write(';')

        fdat.write('\n')
