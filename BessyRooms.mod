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
set SubExamSlots within ExamSlots := setof{e in ExamSlots: e < 2} e;

param SlotNames{ExamSlots}, symbolic; #  (not used here)
param Slot {CidExam, ExamSlots} binary, default 0;

set CidExamNew within CidExam;

#Set of all Computer Courses
set ComputerCourses within CidExam;

#Courses that should not be assigned to seats
set CidMHR within CidExam;

set CidAssign := setof{c in CidExamNew, e in SubExamSlots: c not in CidMHR and Slot[c,e] > 0} c;
# display CidAssign;

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
var w {c in CidAssign, r in AllRooms},>= 0, <= 1, binary;

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

# Special students need special computer rooms:
subject to SpecialCompCoursesReq{c in CidAssignSpec: c in CidAssignComp}: sum{r in SpecialRooms: r in ComputerRooms} h[c,r] + ssc[c] = SpeCidCount[c];

# Computer courses should only be assigned to computer rooms or on a dummy room if there is no space!
subject to ComputerCoursesReq{c in CidAssignComp}: sum{r in ComputerRooms} h[c,r] + sc[c] = cidCount[c] - SpeCidCount[c];

# The rest of the students should be in the other rooms in preferred building
subject to RegularCoursesReq{c in CidAssign: c not in CidAssignComp}: sum{b in Building, r in RoomInBuilding[b]: r not in SpecialRooms and r not in ComputerRooms}
 h[c,r] + sr[c] = cidCount[c] - SpeCidCount[c];

# RequiredBuildings[c]
subject to RoomCapacityLimit{r in AllRooms, e in SubExamSlots}: sum{c in CidAssign} h[c,r] * Slot[c,e] <=  RoomCapacity[r];

# A constraint that indicates the binary variable of which room/s a course is placed in (Big-M approach)
subject to CourseInRoom{c in CidAssign, r in AllRooms}:  1.0001*h[c,r] <= w[c,r] * sum{cc in CidAssign} cidCount[cc];
subject to CourseInRoom2{c in CidAssign, r in AllRooms}:  1.0001*h[c,r] >= w[c,r];

# Don't put courses that do not have the same length in the same room
subject to NotTheSameRoom{r in AllRooms, c1 in CidAssign, c2 in CidAssign: c1<c2 and c1 not in CidAssignComp and c2 not in CidAssignComp
and duration[c1]!=duration[c2]}: (w[c1,r] + w[c2,r]) <= 1;

# Don't use too many rooms for small courses!!!
subject to NotTooManyRooms{c in CidAssign: c not in ComputerCourses and (cidCount[c]-SpeCidCount[c]) <= 8}: sum{r in Rooms} w[c,r] <= 1;

subject to NotTooFewStudents{r in Rooms, c in CidAssign: c not in ComputerCourses}: 1.0001*h[c,r] >= w[c,r] * min(12, (cidCount[c]-SpeCidCount[c]));

subject to NotTooManyCourse{e in SubExamSlots, r in Rooms}: sum{c in CidAssign} w[c,r] * Slot[c,e] <= 2;

var wb{CidAssign, Building}, >= 0, <= 1, binary;

#var hh,>=0;
/* tells us if the course is within this building, could also be continuous, but then must be minimized on objective */
subject to IsCidInBuilding{c in CidAssign, b in Building}: 1.0001 * sum{r in RoomInBuilding[b]: r not in SpecialRooms} w[c,r] <= wb[c,b] * 10000;
subject to IsCidInBuilding2{c in CidAssign, b in Building}: 1.0001 * sum{r in RoomInBuilding[b]: r not in SpecialRooms} w[c,r]  >= wb[c,b];

var wr{AllRooms}, >= 0;
subject to RoomOccupied{c in CidAssign, r in AllRooms}: w[c,r] <= wr[r];


/* this condition is made soft since it does not work allways, should be added to phase 1 */
subject to CourseMayOnlyBeInOneBuilding{c in CidAssign: c not in ComputerCourses}: sum{b in Building} wb[c,b] <= 2;

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

# In in any of buildings numberd above 9 or 4?, you should really only be there!
subject to IfTheseThenOnlyThese{c in CidAssign, b in Building: b > 9}: sum{bb in Building: bb <> b} wb[c,bb] <= (1-wb[c,b])*card(Building);

# Stofunyting
#var emptychairs{r in AllRooms, e in SubExamSlots}, >= 0;
# emptychairs[r,e] =
var maxempty, >= 0;
subject to Nyting {r in AllRooms, e in SubExamSlots}: RoomCapacity[r] - sum{c in CidAssign} h[c,r] * Slot[c,e] <= maxempty;

var NumCoursesInRoom{AllRooms, SubExamSlots};
subject to debug2{r in AllRooms,e in SubExamSlots}: NumCoursesInRoom[r,e] =  sum{c in CidAssign} w[c,r] * Slot[c,e];

#subject to test{e in SubExamSlots, c in CidAssign, r in Room, }: w[c,r] * Slot[c,e] * max(20,RoomCapacity[r]) >= h[c,r];

subject to forceslacks: sum{c in CidAssign} (sc[c] + ss[c] + sr[c] + ssc[c] + sp[c]) = 0;

# Objective function is simply to minimize the number of rooms used
minimize Objective:
# 100 * sum{c in CidAssign} (sc[c] + ss[c] + sr[c] + ssc[c] + sp[c])
#- 0.01*sum{c in CidAssign, r in AllRooms} w[c,r]
#+ (1/card(CidAssign)) * sum{c in CidAssign} maxnumberofrooms[c]
+ 30 * sum{c in CidAssign, b in Building: b <> 11 and b <> 12} wb[c,b]
+ 50 * sum{c in CidAssign, b in Building: b == 11 or b == 12} wb[c,b]
- 20 * RBuild
+ 1 * sum{c in CidAssign, r in AllRooms: r not in SpecialRooms} h[c,r] * RoomPriority[r] / cidCount[c]
+ 10 * sum{r in AllRooms} wr[r];

set UnionOfRoomsInBuildings := setof{b in Building, r in RoomInBuilding[b]} r;

solve;

for {r in AllRooms: r not in UnionOfRoomsInBuildings} {
  printf : "%s not in any building\n", r;
}

for {r in ComputerRooms: r in Rooms} {
  printf : "computer %s  in any Rooms?!\n", r;
}

for {r in SpecialRooms: r in Rooms} {
  printf : "computer %s  in any Rooms?!\n", r;
}

for {c in CidAssign: sr[c] > 0} {
  printf : "Namskeið %s vantar %d sæti\n", c, sr[c];
}

for {c in CidAssign: sc[c] > 0} {
  printf : "Namskeið %s vantar %d sæti í tölvustofu\n", c, sc[c];
}

for {c in CidAssign: ss[c] > 0} {
  printf : "Namskeið %s vantar %d sérúrræðisæti\n", c, ss[c];
}

for {c in CidAssign: ssc[c] > 0} {
  printf : "Namskeið %s vantar %d sérúrræðisæti í tölvustofu\n", c, ssc[c];
}
for {e in SubExamSlots} {
  printf "Dagur/tími: %s\n", SlotNames[e];
  printf : "fjöldi sæta tiltæk %d og þöfin er %d\n", sum{r in Rooms} RoomCapacity[r], sum{c in CidAssign: c not in ComputerCourses} (cidCount[c]-SpeCidCount[c]) * Slot[c,e];
  printf : "fjöldi sæta tiltæk í tölvustofum er %d og þöfin er %d\n", sum{r in ComputerRooms} RoomCapacity[r], sum{c in ComputerCourses} cidCount[c] * Slot[c,e];
  printf : "fjöldi sæta tiltæk í sérúræði er %d og þöfin er %d\n", sum{r in SpecialRooms} RoomCapacity[r], sum{c in CidAssign: c not in ComputerCourses} SpeCidCount[c] * Slot[c,e];
}

for {c in CidAssign: sum{b in Building} wb[c,b] > 1} {
  printf : "Namskeið %s er í %d byggingum: ", c, sum{b in Building} wb[c,b];
  printf {b in Building: wb[c,b] > 0}: "%s ", BuildingNames[b];
  printf "\n";
}

# Hvaða stofur er verið að nota og hvernig er nýtingin:
for {e in SubExamSlots} {
  printf "Dagur/tími: %s\n", SlotNames[e];
  printf "Bygging stofa; fjöldi/hámarksfjöldi (forgangur) fjöldi_námskeiða:\n";
  for {b in Building} {
    printf{r in RoomInBuilding[b]: r in Rooms} : "%s %s %d/%d (%d) %d\n", BuildingNames[b], r, sum{c in CidAssign} Slot[c,e] * h[c,r], RoomCapacity[r], RoomPriority[r], sum{c in CidAssign} w[c,r] * Slot[c,e];
  }
  printf "Tölvustofur:\n";
  printf{r in ComputerRooms} : "%s %d/%d (%d) \n", r, sum{c in CidAssign} Slot[c,e] * h[c,r], RoomCapacity[r], RoomPriority[r];
  printf "Sérúrræðistofur:\n";
  printf{r in SpecialRooms} : "%s %d/%d (%d)\n", r, sum{c in CidAssign} Slot[c,e] * h[c,r], RoomCapacity[r], RoomPriority[r];
}

# pretty print the solution:
printf : "ID;Námskeið;Stofa;Fjöldi;Bygging;Dagur;Tími";
for {e in SubExamSlots, c in CidAssign, r in Rooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0} {
  printf : "%s;%s;%s;%d;%s;%s\n", CidId[c], c, r, h[c,r], BuildingNames[b], SlotNames[e];
}
printf : "Tölvustofur;;;;;;\n";
for {e in SubExamSlots, c in CidAssign, r in ComputerRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0} {
  printf : "%s;%s;%s;%d;%s;%s\n", CidId[c], c, r, h[c,r], BuildingNames[b], SlotNames[e];
}
printf : "Sérúrræði;;;;;;;;;\n";
for {e in SubExamSlots, c in CidAssign, r in SpecialRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0} {
  printf : "%s;%s;%s;%d;%s;%s\n", CidId[c], c, r, h[c,r], BuildingNames[b], SlotNames[e];
}

end;
