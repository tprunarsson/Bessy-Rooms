#Author: Ásgeir Örn Sigurpálsson
#Date: 29 oct 2015
#Type: MessyBessy - Room Scheduling
#Input: stofur.csv and ByggingarOgStofur.csv
#Output: rooms.dat
#   Makes the dat file rooms.dat which includes rooms, room capacity, computer rooms, special rooms, buildings,
#rooms in each buildings and room priority.
#how the doctument looks like:
#stofur.csv
#Bygging	Stofa	Sætafjöldi	Tegund	Tölvuver	Forgangur	Forgangssvið
#ByggingarOgStofur.csv:
#

import os, csv
from collections import OrderedDict
_trans = str.maketrans('ÁÐÉÍÓÚÝÞÆÖáðéíóúýþæö_ ','ADEIOUYTAOadeiouytao_ ')
_wenc = 'utf_8'

DI = [{} for i in range(6)]
DII = [{} for i in range(1)]
with open('stofur.csv',"r",encoding='latin-1', newline='') as csvfile,\
     open('ByggingarOgStofur.csv',"r",encoding='latin-1', newline='') as csvfile2:

    RoomData = csv.reader(csvfile, delimiter=';')
    next(RoomData)
    for rows in RoomData:
        for i in range(6):
            DI[i][rows[1]] = rows[i+1]



    RoomData2 = csv.reader(csvfile2, delimiter=';')
    next(RoomData2)
    for rows in RoomData2:
        for i in range(1):
            DII[i][rows[0]] = rows[i+1]





with open('rooms2.dat','w', encoding=_wenc) as fdat:

    s='set Building:='
    fdat.write(s)
    fdat.write('\n')
    for b,n in DII[0].items():
        fdat.write(b.translate(_trans))
        fdat.write('\n')
    fdat.write(';\n\n')



    s='param BuildingNames:='
    fdat.write(s)
    fdat.write('\n')
    for b,n in DII[0].items():
        fdat.write(b.translate(_trans)+' '+"'"+b+"'")
        fdat.write('\n')
    fdat.write(';\n\n')


    s='set Rooms:='
    fdat.write(s)
    fdat.write('\n')
    for rooms,t in DI[2].items():
        if t=='Almenn':
            fdat.write(rooms.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')



    s='param RoomCapacity:='
    fdat.write(s)
    fdat.write('\n')
    for room,cap in DI[1].items():
        fdat.write(room.translate(_trans)+' '+cap)
        fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')

    s='set ComputerRooms:='
    fdat.write(s)
    fdat.write('\n')
    for room,com in DI[2].items():
        if com =='Tölvuver':
            fdat.write(room.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')


    s='set SpecialRooms:='
    fdat.write(s)
    fdat.write('\n')
    for room,t in DI[2].items():
        if t =='Sér':
            fdat.write(room.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')

    s='set SpecialComputerRooms :='
    fdat.write(s)
    fdat.write('\n')
    for room, t in DI[2].items():
        if t=='Sér-Tölvuver':
            fdat.write(room.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')

    s='param RoomPriority:='
    fdat.write(s)
    fdat.write('\n')
    for room, pri in DI[4].items():
        fdat.write(room.translate(_trans)+' '+pri)
        fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')


    for b,r in DII[0].items():
        s='set RoomInBuilding['+"'"+b.translate(_trans)+"'"+']:='
        fdat.write(s)
        for room in r:
            fdat.write(room.translate(_trans))
        fdat.write(';\n')
    fdat.write('\n')

    s='end;\n'
    fdat.write(s)
    fdat.write('\n')
