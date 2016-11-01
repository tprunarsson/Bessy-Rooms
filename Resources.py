#------------------------------------#
#Author: Ásgeir Örn Sigurpálsson
#Date: 28 oct 2015
#Type: MessyBessy - Room Scheduling
#Output: resources.dat
#   Makes the dat file resources.dat which includes special cidcount, special exams, computer courses and
#   courses that should not be scheduled into rooms (CidMHR). The input is a document supplied by the examination director
#   which was also used for phase I.
#how the doctument looks like:
#Langt númer	Fagnúmer	Tegund lokaprófs	Fagheiti	proftafla.fest	Byrjar	Endar	Staðnemar
#Staðnemar sérnemar	Fjarnemar	Fjarnemar sérnemar

#------------------------------------#
import os, csv
from collections import OrderedDict
_trans = str.maketrans('ÁÐÉÍÓÚÝÞÆÖáðéíóúýþæö_ ','ADEIOUYTAOadeiouytao_ ')
_wenc = 'utf_8'

DI = [{} for i in range(10)]

with open('tafla8.csv',"r",encoding='latin-1', newline='') as csvfile:

    RoomData = csv.reader(csvfile, delimiter=';')
    next(RoomData)
    for rows in RoomData:
        for i in range(10):
            DI[i][rows[1]] = rows[i+1]

with open('resources.dat','w', encoding=_wenc) as fdat:


    s= 'param SpeCidCount :=\n'
    fdat.write(s)
    for course,count in DI[7].items():
        if count !=0:
            fdat.write(course.translate(_trans)+' '+count.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')


    s ='set SpecialExams :=\n'
    fdat.write(s)
    for course,count in DI[7].items():
        if count !=0:
            fdat.write(course.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
    fdat.write('\n')


    s='set ComputerCourses := \n'
    fdat.write(s)
    for course, types in DI[1].items():
        #print(types)
        if types =='C':
            fdat.write(course.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')


    s ='set CidMHR := \n'
    fdat.write(s)
    for course, types in DI[1].items():
        if types=='M' or types =='H' or types =='R':
            fdat.write(course.translate(_trans))
            fdat.write('\n')
    fdat.write(';\n')
