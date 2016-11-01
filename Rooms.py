#Author: Ásgeir Örn Sigurpálsson
#Date: 29 oct 2015
#Type: MessyBessy - Room Scheduling
#Input: stofur.csv and ByggingarOgStofur.csv
#Output: rooms.dat
#   Makes the dat file rooms.dat which includes rooms, room capacity, computer rooms, special rooms, buildings,
#rooms in each buildings, room priority and building names.
#how the doctument looks like:
#Bygging	Stofa	Sætafjöldi	Tegund	Tölvuver	Forgangur	Forgangssvið

import os, csv
from collections import OrderedDict
_trans = str.maketrans('ÁÐÉÍÓÚÝÞÆÖáðéíóúýþæö_ ','ADEIOUYTAOadeiouytao_ ')
_wenc = 'utf_8'

DI = [{} for i in range(6)]
DII = [{} for i in range(2)]
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
        for i in range(2):
            DII[i][rows[1]] = rows[i+1]



with open('rooms.dat','w', encoding=_wenc) as fdat:


#Must be updated - computer rooms should not be in this list
    s='set Rooms:='
    fdat.write(s)
    fdat.write('\n')
    for rooms,cap in DI[2].items():
        if cap =='Almenn':
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
    for room,com in DI[3].items():
        if com =='Já':
            fdat.write(room.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')

    s='set SpecialRooms:='
    fdat.write(s)
    fdat.write('\n')
    for room,com in DI[2].items():
        if com =='Sér':
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


    s='set Building:='
    fdat.write(s)
    fdat.write('\n')
    for b,n in DII[0].items():
        fdat.write(n)
        fdat.write('\n')
    fdat.write(';\n\n')

    for b,r in DII[1].items():
        s='set RoomInBuilding['+b.translate(_trans)+']:='
        fdat.write(s)
        for room in r:
            fdat.write(room.translate(_trans))
        fdat.write(';\n')
    fdat.write('\n')

    s='param BuildingNames:='
    fdat.write(s)
    fdat.write('\n')
    for b,n in DII[0].items():
        fdat.write(n+' '+b)
        fdat.write('\n')
    fdat.write(';\n\n')


    s='end;\n'
    fdat.write(s)
    fdat.write('\n')
