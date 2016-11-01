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

DI = [{} for i in range(10)]

#Verdur ad vera skjal ur bordarodun..Thar koma svidsnumer og fleira fram
with open('bordarodun2.csv',"r",encoding='latin-1', newline='') as csvfile:

    RoomData = csv.reader(csvfile, delimiter=';')
    next(RoomData)
    for rows in RoomData:
        for i in range(10):
            DI[i][rows[2]] = rows[i+1]


with open('RequiredBuildings.dat','w', encoding=_wenc) as fdat:
    for course, blist in DI[0].items():
        s = 'set RequiredBuildings['+course.translate(_trans)+']:='
        fdat.write(s)
        if blist =='11' or blist=='12' or blist=='13' or blist=='14' or blist=='15' or blist=='16':
            fdat.write('6 8')
            fdat.write(';')
        if blist=='21':
            fdat.write('4 1')
            fdat.write(';')
        if blist=='22' or blist=='23' or blist=='24' or blist=='25' or blist=='26':
            fdat.write('9 4 1 6 8')
            fdat.write(';')
        if blist =='31' or blist=='32' or blist=='33' or blist=='34':
            fdat.write('1 3 6 7')
            fdat.write(';')
        if blist =='41' or blist=='42' or blist=='43':
            fdat.write('10 11 12')
            fdat.write(';')
        if blist =='51' or blist =='52' or blist =='53' or blist =='54' or blist=='55' or blist=='56':
            fdat.write('9 2 3 6')
            fdat.write(';')

        fdat.write('\n')
