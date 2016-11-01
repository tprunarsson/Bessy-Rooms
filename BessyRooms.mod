# Messy Bessy Room allocation: Beta version 0.0.1
# Authors: Thomas Philip Runarsson and Asgeir Orn Sigurpalsson
# Last modified by aos at 15:03 20/9/2016
# Last modified by tpr at 13:55 23/9/2016

#-----------------------------------PARAMETERS AND SETS----------------------------------------#

#number of exam days
param n:= 11;

#set of exams to be assigned to exam slots
set CidExam;

# Set of all ExamSlots and their position
set ExamSlots:= 1..(2*n);
param SlotNames{ExamSlots}, symbolic; #  (not used here)
param Slot {CidExam, ExamSlots} binary, default 0;

set CidExamNew within CidExam;

#Set of all Computer Courses
set ComputerCourses within CidExam;

#Courses that should not be assigned to seats
set CidMHR within CidExam;

set CidAssign := setof{c in CidExamNew: c not in CidMHR and (Slot[c,1] > 0 or Slot[c,2] > 0)} c;
display CidAssign;

# Total number of students for each course
param cidCount{CidExam} default 0;

# The long number identification for the exam
param CidId{CidExam};

#Total number of Special students for each course
param SpeCidCount{CidExam} default 0;

set CidAssignComp := setof{c in ComputerCourses: c not in CidMHR and c in CidAssign} c;
set CidAssignSpec := setof{c in CidAssign: SpeCidCount[c] > 0} c;

# course incidence data to constuct the matrix for courses that should be examined together"
# this may be used ...
param cidConjoinedData {CidExam, CidExam};
# The set of courses that should be examined together, this script forces symmetry for the matrix (if needed)
param cidConjoined  {c1 in CidExam, c2 in CidExam} := min(cidConjoinedData[c1,c2] + cidConjoinedData[c2,c1],1);
#Indicator tells us the course is in a conjoined set
param cidIsConjoined {c in CidExam} :=  min(sum{ce in CidExam} cidConjoined[c,ce],1);

#-----------------------------------Sets and parameters related to rooms---------------------#
# The courses are assigned to these slots from phase 1
set Rooms;
set ComputerRooms;
set SpecialRooms;

set AllRooms := setof{r in (Rooms union ComputerRooms union SpecialRooms)} r;

param RoomCapacity{AllRooms} default 0;

set Building;
param BuildingNames{Building}, symbolic;

set RequiredBuildings{CidExam} within Building default {};

set RoomInBuilding{Building} within AllRooms default {};

set BuildingWithRoom{r in AllRooms} within Building := setof{b in Building: r in RoomInBuilding[b]} b;

param distance {Building, Building} default 0;
param hfix{CidAssign,AllRooms} default 0;
param RoomPriority{AllRooms} default 3;
param duration {CidExam} default 3;

#-----------------------------------Decision variables----------------------------------------#

# The decision variable is to assign an exam to an exam slot (later we may add room assignments)
var h {c in CidAssign, r in AllRooms} >= 0, integer;
var w {c in CidAssign, r in AllRooms}, binary;

param h_fix {c in CidAssign, r in AllRooms} default 0;

var sc{CidAssign}>= 0;
var ss{CidAssign}>= 0;
var ssc{CidAssign}>=0;
var sr{CidAssign}>= 0;
var sp{CidAssign}>= 0;

#-----------------------------------Constraints-------------------------------------------------#

subject to FixH{c in CidAssign, r in AllRooms: h_fix[c,r] > 0}: h[c,r] = h_fix[c,r];

subject to Balance{c in CidAssign}: sum{r in AllRooms} h[c,r] + sc[c] + ss[c] + sr[c] + ssc[c] + sp[c] = cidCount[c];

# Special students need special rooms:
subject to SpecialCoursesReq{c in CidAssignSpec: c not in CidAssignComp}: sum{r in SpecialRooms: r not in ComputerRooms} h[c,r] + ss[c] = SpeCidCount[c];

# Special students need special copmuter rooms:
subject to SpecialCompCoursesReq{c in CidAssignSpec: c in CidAssignComp}: sum{r in SpecialRooms: r in ComputerRooms} h[c,r] + ssc[c] = SpeCidCount[c];

# Computer courses should only be assigned to computer rooms or on a dummy room if there is no space!
subject to ComputerCoursesReq{c in CidAssignComp}: sum{r in ComputerRooms} h[c,r] + sc[c] = cidCount[c] - SpeCidCount[c];

# The rest of the students should be in the other rooms in preferred building
subject to RegularCoursesReq{c in CidAssign: c not in CidAssignComp}: sum{b in Building, r in RoomInBuilding[b]: r not in SpecialRooms and r not in ComputerRooms}
 h[c,r] + sr[c] = cidCount[c] - SpeCidCount[c];

# RequiredBuildings[c]
subject to RoomCapacityLimit{r in AllRooms, e in ExamSlots}: sum{c in CidAssign} h[c,r] * Slot[c,e] <=  RoomCapacity[r];

# A constraint that indicates the binary variable of which room/s a course is placed in (Big-M approach)
subject to CourseInRoom{c in CidAssign, r in AllRooms: r not in SpecialRooms}:  h[c,r] <= w[c,r] * sum{cc in CidAssign} cidCount[cc];

# Don't put courses that do not have the same length in the same room
subject to NotTheSameRoom{r in AllRooms, c1 in CidAssign, c2 in CidAssign: c1<c2 and c1 not in CidAssignComp and c2 not in CidAssignComp
and duration[c1]!=duration[c2]}: (w[c1,r] + w[c2,r]) <= 1;

# Don't use too many rooms!!!
var maxnumberofrooms{CidAssign}, >= 0;
subject to NotTooManyRooms{c in CidAssign}: sum{r in AllRooms} w[c,r] <= maxnumberofrooms[c];

var wb{CidAssign, Building}, binary;
#var hh,>=0;
/* tells us if the course is within this building, could also be continuous, but then must be minimized on objective */
subject to IsCidInBuilding{c in CidAssign, b in Building}: sum{r in RoomInBuilding[b]} w[c,r] <= wb[c,b] * 1000000;

subject to CourseMayOnlyBeInOneBuilding{c in CidAssign}: sum{b in Building} wb[c,b] <= 1;

/* lets assume once you are in a different building it does not matter how far away it is: */
#var TotalDistance2;
#subject to TotDistance2: TotalDistance2 = sum{c in CidAssign: c not in CidAssignComp and c not in CidAssignSpec}
#(sum{b in Building} wb[c,b] -1);

#Required Rooms - not working perfectly since the variable h is incorrect.
subject to PutNStudentsIn{c in CidAssign, r in AllRooms: hfix[c,r]>0}: h[c,r] = hfix[c,r];

var RBuild, >=0;
subject to Reqbuild: RBuild = sum{c in CidAssign, b in RequiredBuildings[c]} wb[c,b];

#subject to EkkiLaugarvatn{r in RoomInBuilding[13], c in CidAssign: c not in CidSport}: h[c,r] = 0;
subject to EkkiLaugarvatn{r in RoomInBuilding[13], c in CidAssign}: h[c,r] = 0;

# Stofunyting
#var emptychairs{r in AllRooms, e in ExamSlots}, >= 0;
# emptychairs[r,e] =
var maxempty, >= 0;
subject to Nyting {r in AllRooms, e in ExamSlots}: RoomCapacity[r] - sum{c in CidAssign} h[c,r] * Slot[c,e] <= maxempty;

var NumCoursesInRoom{AllRooms, ExamSlots};
subject to debug2{r in AllRooms,e in ExamSlots}: NumCoursesInRoom[r,e] =  sum{c in CidAssign} w[c,r] * Slot[c,e];

# Objective function is simply to minimize the number of rooms used
minimize Objective: sum{c in CidAssign} (sc[c] + ss[c] + sr[c] + ssc[c]+sp[c])
+ 0.01* sum{c in CidAssign, r in AllRooms} w[c,r]
+ (1/card(CidAssign)) * sum{c in CidAssign} maxnumberofrooms[c]
+ (1/card(CidAssign)) * sum{r in AllRooms,e in ExamSlots} NumCoursesInRoom[r,e]
+ 5*sum{c in CidAssign, b in Building} wb[c,b]
-1*RBuild;
#+ sum{c in CidAssign, r in AllRooms: r not in SpecialRooms} h[c,r] * RoomPriority[r];

solve;

# pretty print the solution:
for {e in ExamSlots, c in CidAssign, r in Rooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0} {
  printf : "%s;%s;%s;%d;%s;%s\n", CidId[c], c, r, h[c,r], BuildingNames[b], SlotNames[e];
}
for {e in ExamSlots, c in CidAssign, r in ComputerRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0} {
  printf : "%s;%s;%s;%d;%s;%s\n", CidId[c], c, r, h[c,r], BuildingNames[b], SlotNames[e];
}
for {e in ExamSlots, c in CidAssign, r in SpecialRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0} {
  printf : "%s;%s;%s;%d;%s;%s\n", CidId[c], c, r, h[c,r], BuildingNames[b], SlotNames[e];
}


/*
printf : "Fjöldi tölvu prófsæta: (dags = )\n";
for {e in ExamSlots} {
  printf : "%s = %d\n", SlotNames[e], sum{c in ComputerCourses} Slot[c,e] * cidCount[c];
}

printf : "Heildarfjöldi prófa er %d og þreytt próf eru %.0f.\n", card(CidExam), sum{c in CidExam} cidCount[c];
printf : "Lenda í prófi samdægurs: %.0f (%.2f%%), deildir þvinga %.0f. Prófin eru:\n", obj1, 100*obj1/(sum{c in CidExam} cidCount[c]), obj1-obj1f;
printf {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zsame[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2];
printf : "Taka próf eftir hádegi og svo strax morguninn eftir: %.0f (%.2f%%), deildir þvinga %.0f.\n", obj2, 100*obj2/(sum{c in CidExam} cidCount[c]), obj2-obj2f;
printf {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zseq[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2];
printf : "Þreyta próf tvo daga í röð: %.0f (%.2f%%), deildir þvinga %.0f.\n", obj3, 100*obj3/(sum{c in CidExam} cidCount[c]), obj3-obj3f;
# printf : "Lausnin:\n";
printf {e in ExamSlots, c in CidExam: Slot[c,e] > 0}: "%s;%011.0f;%d;%s\n", c, CidId[c], e, SlotNames[e] > "lausn.csv";
*/


end;
