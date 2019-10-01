# Ugly Bessy Room allocation: Beta version 0.0.2
# Author: Thomas Philip Runarsson and Asgeir Orn Sigurpalsson
# Last modified by tpr at 11:00 21/11/2017 added floors in buildings

# TODO: conjoined courses forced together in one!
# This needs to be resolved perhaps can also be solved by setting the conjoined courses in the same building?!

# --- Parameter and Sets --- #

# Total number of exam days, each day is split in two (even and odd integer)
param n := 12; # point outside normal range....

# Set of all ExamSlots and their position
set ExamSlots:= 1..(2*n);

# The set of exams to be assigned to slots
set CidExam;

# Taken from phase one solution
param Slot {CidExam, ExamSlots} binary, default 0;
# The actual dates, used for printing solution
param SlotNames{ExamSlots}, symbolic;

# It is not necessary to solve all slots at once, select the one you want.
param SolveSlot default 1;
set SubExamSlots within ExamSlots := setof{e in ExamSlots: e == SolveSlot} e;

# Set of all Computer Courses
set ComputerCourses within CidExam;

# Courses that do not require seats/rooms
set CidMHR within CidExam;

# The actual courses than will be assigned seats
#set CidAssign := setof{c in CidExam, e in SubExamSlots: c not in CidMHR and Slot[c,e] > 0} c;
set CidAssign := setof{c in CidExam, e in SubExamSlots: c not in CidMHR and c not in ComputerCourses and Slot[c,e] > 0} c;

# course incidence data to constuct the matrix for courses that should be examined together"
param cidConjoinedData {CidExam, CidExam};
# The set of courses that should be examined together, this script forces symmetry for the matrix (if needed)
param cidConjoined  {c1 in CidAssign, c2 in CidAssign} := min(cidConjoinedData[c1,c2] + cidConjoinedData[c2,c1],1);

# Number of students taking two common courses" THIS IS NOT USED BUT IS IN courses.dat
param CidCommonStudents {CidExam, CidExam} default 0;

# Total number of students for each course
param cidCount{CidExam} default 0;

# The long number identification for the exam, used for printing solution
param CidId{CidExam} default 0;

# Total number of special students for each course
param SpeCidCount{CidExam} default 0;

# These are the subset of students within CidAssign that belong to special groups: Computer and Special
set CidAssignComp := {}; #setof{c in ComputerCourses: c not in CidMHR and c in CidAssign} c;
set CidAssignSpec := setof{c in CidAssign: SpeCidCount[c] > 0} c;

# Missing perhaps is to consider courses that are taught together and that they should be in the same Building
# The preferred future solution to this that they be combined into one MetaCourse! and so will not need to be considered specially

# --- Sets and parameters related to rooms ---#

set Rooms;
set SpecialRooms;
set ComputerRooms;
set SpecialComputerRooms;

set AllRooms := setof{r in (Rooms union ComputerRooms union SpecialRooms union SpecialComputerRooms)} r;

param RoomCapacity{AllRooms} default 0;
param RoomId{AllRooms} default 0;

set Building;
set Cluster;
set BuildingsInCluster{Cluster} within Building;
set Floors := {0..3};
# These building are acceptable to the course
set RequiredBuildings{CidExam} within Building default {};
# These building are the most wanted buildings, note that these are also in RequiredBuildings
set PriorityBuildings{CidExam} within Building default {};
# Tells us which rooms are in a given building
set RoomInBuilding{Building} within AllRooms default {};
# Tells us which rooms are on the same floor in the same building
set RoomInBuildingFloor{Building,Floors} within AllRooms default {};
# Tells us which building has a given room
set BuildingWithRoom{r in AllRooms} within Building := setof{b in Building: r in RoomInBuilding[b]} b;
# The hfix variable is used for fixing a number of students in a given class room
# can be used for post analysis also
param hfix{CidExam,AllRooms} default 0;
param hdef{CidExam,AllRooms} default 0;
# each room has a priority, where 1 is best then 2 and worst 3 NOT USED !!!
param RoomPriority{AllRooms} default 3;
# the length of an exam is needed since exams of same length should be in the same room
param duration {CidExam} default 3;

# --- Decision variables ---#

# The number of students assigned to a given room.
var h {c in CidAssign, r in AllRooms} >= 0, integer;
# indicator variable tells us if a course is assigned to a room
var w {c in CidAssign, r in AllRooms}, >= 0, <= 1, binary;
# indicator variable tells us if a course is within a building
var wb{CidAssign, Building}, >= 0, <= 1, binary;
# variable tells us if a room is occupied or not, must be minimized in objective
# when minimized it also tries to free rooms when possible and creating a saving for staff needed for monitoring the exams
var wr{AllRooms}, >= 0, <= 1;
# This indicator variable tells us when a floor is occumpied within a building, we would like to minimize the number of floors used
var wf{Floors, Building} >= 0, <= 1;

# --- Constraints --- #

# if you would like to fix a decision do it here with parameter h_fix > 0
subject to FixH{c in CidAssign, r in AllRooms: hfix[c,r] > 0}:
  h[c,r] = hfix[c,r];

# there is another possible fixing defined by the user, you can't fix more students than that registered
printf{c in CidAssign}: "%s %d %d\n", c, sum{r in Rooms} hdef[c,r], cidCount[c]-SpeCidCount[c];
#check{c in CidAssign}: sum{r in Rooms} hdef[c,r] <= (cidCount[c]-SpeCidCount[c]);

# this min trick will only work if the user has fixed only one room!
subject to FixD{c in CidAssign, r in AllRooms: hdef[c,r] > 1}:
  h[c,r] = min(hdef[c,r],cidCount[c]-SpeCidCount[c]);

# perhaps this should be used instead
subject to ForceRoom{c in CidAssign, r in AllRooms: hdef[c,r] == 1}:
 h[c,r] >= 1;

# this boolean will dictate if we want to arrange also special students
param AssignSpec := 0;

# Make sure that all students in the course have a seat
# *** This constraint may be satisified by ones below
subject to AssignAllCidSeats{c in CidAssign}:
  sum{r in AllRooms} h[c,r] = cidCount[c] - SpeCidCount[c] ;

# Special students need special rooms:
subject to SpecialCoursesReq{c in CidAssignSpec: c not in CidAssignComp}:
  sum{r in SpecialRooms} h[c,r] = AssignSpec*SpeCidCount[c];

# Special students need special computer rooms:
subject to SpecialCompCoursesReq{c in CidAssignSpec: c in CidAssignComp}:
  sum{r in SpecialComputerRooms} h[c,r] = AssignSpec*SpeCidCount[c];

# Computer courses should only be assigned to computer rooms or to a dummy room if there is no space!
subject to ComputerCoursesReq{c in CidAssignComp}:
  sum{r in ComputerRooms} h[c,r] = cidCount[c] - SpeCidCount[c];

printf: sum{c in CidAssignComp} (cidCount[c] - SpeCidCount[c]);

# The rest of the students should be in the other rooms in preferred building
subject to RegularCoursesReq{c in CidAssign: c not in CidAssignComp}:
  sum{r in Rooms} h[c,r] = cidCount[c] - SpeCidCount[c];

# The number of students in a room should not go over the limit
# n.b. this is the total number of useful seats (reduce the number is there a "bad seats" in the room)
subject to RoomCapacityLimit{r in AllRooms, e in SubExamSlots}:
  sum{c in CidAssign: Slot[c,e] > 0} h[c,r] <=  RoomCapacity[r];

# A constraint for the indicator binary variable is course c in room r, the 1.0001 is a hack needed ?!
# the sum sum{cc in CidAssign} cidCount[cc] corresponds to a big value, i.e. Big-M approach
subject to CourseInRoom{c in CidAssign, r in AllRooms}:
  1.0001*h[c,r] <= w[c,r] * sum{cc in CidAssign} cidCount[cc];
subject to CourseInRoom2{c in CidAssign, r in AllRooms}:
  1.0001*h[c,r] >= w[c,r];

# Don't put courses that do not have the same length (duration) in the same room
subject to NotTheSameRoom{r in AllRooms, c1 in CidAssign, c2 in CidAssign: c1 < c2 and duration[c1]!=duration[c2]}:
  (w[c1,r] + w[c2,r]) <= 1;

# If any two courses are conjoined then they should be in the same building!!!
subject to conjoinedCourses{b in Building, c1 in CidAssign, c2 in CidAssign: c1 < c2 and cidConjoined[c1,c2] == 1}:
  wb[c1,b] = wb[c2,b];

# Don't use too many rooms for small courses, say 12 ?!
# n.b. this applies only to Rooms which are not ComputerRooms or SpecialRooms
subject to NotTooManyRooms{c in CidAssign: (cidCount[c]-SpeCidCount[c]) <= 12}:
  sum{r in Rooms} w[c,r] <= 1;

# We will force the courses in many rooms within the builing, however, they
# should be more than 12 in a room or less for a 2 way split
# this should avoid the possibility of putting courses as singles in rooms
subject to NotTooFewStudents{c in CidAssign, r in Rooms: (cidCount[c]-SpeCidCount[c]) >= 12}:
  h[c,r] >= w[c,r] * min(12,min((cidCount[c]-SpeCidCount[c])/2,
                          (cidCount[c]-SpeCidCount[c]-(sum{rr in Rooms: hdef[c,rr]>0} hdef[c,rr]))));

# Do not have too many different exams in the same room, more traffic from teachers
# try to maximize the number of courses in a room !!! Helps with table assignments (different exams at each table)
subject to NotTooManyCourse{e in SubExamSlots, r in AllRooms: r not in SpecialRooms and r not in SpecialComputerRooms}:
  sum{c in CidAssign: Slot[c,e] > 0} w[c,r] <= if (RoomCapacity[r] >= 20) then 3 else 2;

# The same applied to Special Courses, but here we can have more teachers entering the rooms
subject to NotTooManyCoursesSpecial{e in SubExamSlots, r in AllRooms: r in SpecialRooms or r in SpecialComputerRooms}:
  sum{c in CidAssign: Slot[c,e] > 0} w[c,r]  <= 6;

# A constraint for the indicator binary variable is course c in building b
subject to IsCidInBuilding{c in CidAssign, b in Building, r in RoomInBuilding[b]}:
  w[c,r] <= wb[c,b];

# A constraint for the indicator binary variable is course c in building b and floor
subject to IsCidInBuildingFloor{b in Building, f in Floors,c in CidAssign, r in RoomInBuildingFloor[b,f]}:
  w[c,r] <= wf[f,b];

############# TEST ZONE ##############

# A constraint for the indicator binary variable is course c in building b, the 1.0001 is a hack needed ?!
# This variable is different to wb in that it only considers regular exams as in the building!
var wbb{CidAssign,Building}, <= 1, >= 0, binary;
subject to IsCidInBuildingBB{c in CidAssign, b in Building}:
  1.0001 * sum{r in RoomInBuilding[b]: r in Rooms} w[c,r] <= wbb[c,b] * 10000;
subject to IsCidInBuildingBB2{c in CidAssign, b in Building}:
  1.0001 * sum{r in RoomInBuilding[b]: r in Rooms} w[c,r]  >= wbb[c,b];


# Can only be in one building if not then on the green!
var NumberOfBuildings{CidAssign}, >= 0;
subject to OnlyOneUnlessInBuildingCluster{c in CidAssign, g in Cluster, t in BuildingsInCluster[g]}:
  sum{b in Building: b not in BuildingsInCluster[g]} wbb[c,b] + wbb[c,t] <= NumberOfBuildings[c];

#####################

# If the room is occupied then wr is forced to 1 else it will tend to zero due to the objective function
subject to RoomOccupied{c in CidAssign, r in AllRooms}: w[c,r] <= wr[r];

display CidAssign;

# Objective function
minimize Objective:
# 1.) we don't want to use Klettur and Enni (unless asked for)
+ 100 * sum{c in CidAssign, b in Building: (b == 'Stakkahlid_Klettur' or b == 'Stakkahlid_Enni') and b not in PriorityBuildings[c]} wb[c,b]
# 1.1) even when asked for we really don't want to go here ...
+ 100 * sum{c in CidAssign, b in Building: (b == 'Stakkahlid_Klettur' or b == 'Stakkahlid_Enni')} wb[c,b]
# 2.) We don't want to use Hamar unless asked for
+ 75 * sum{c in CidAssign, b in Building: b == 'Stakkahlid_Hamar' and b not in PriorityBuildings[c]} wb[c,b]
# 3.) Avoid also Eirberg is not on your list
+ 50 * sum{c in CidAssign, b in Building: b == 'Eirberg' and b not in PriorityBuildings[c]} wb[c,b]
# 4.) Avoid buildings that are not on your list, note that this adds to RequiredBuildings, so not too big please
+ 50 * sum{c in CidAssign, b in Building: b not in PriorityBuildings[c]} wb[c,b]
+ 50 * sum{c in CidAssign, b in Building: b not in RequiredBuildings[c]} wb[c,b]
# 5.) minimize the number of buildings used, weight should be equal to Required or higher?
+ 10 * sum{c in CidAssign, b in Building} wb[c,b]
+ 1000 * sum{c in CidAssign} NumberOfBuildings[c]
# 6.) Empty rooms when possible
+ 100 * sum{r in AllRooms} wr[r]
# 7.) Leave also empty floors!!!
+ 100 * sum{f in Floors, b in Building} wf[f,b]
# 8.) Use as many rooms as possible also but with smaller priority
- (1/card(CidAssign)) * sum{c in CidAssign,r in Rooms} w[c,r]
+ 100*sum{c in CidAssign} w[c,'HT204']
;

# Some debugging now for the data supplied:
set UnionOfRoomsInBuildings := setof{b in Building, r in RoomInBuilding[b]} r;
check card(UnionOfRoomsInBuildings) == card(AllRooms);
check {c in CidAssign} cidCount[c] >= SpeCidCount[c];

check {c in CidAssign} sum{r in Rooms} hfix[c,r] <= cidCount[c];
check {r in Rooms} sum{c in CidAssign} hfix[c,r] <= RoomCapacity[r];


# Solve the model
solve;

# More debugging stuff to follow:
for {r in AllRooms: r not in UnionOfRoomsInBuildings} {
  printf : "%s not in any building\n", r;
}

for {r in ComputerRooms: r in Rooms} {
  printf : "computer %s  in any Rooms?!\n", r;
}

for {r in SpecialRooms: r in Rooms} {
  printf : "computer %s  in any Rooms?!\n", r;
}

for {c in CidAssign} {
  printf : "Fjöldi í námskeið %s eru %d en CidCount er %d\n", c, sum{r in AllRooms} h[c,r], cidCount[c];
}

for {e in SubExamSlots} {
  printf "Dagur/tími: %s\n", SlotNames[e];
  printf : "fjöldi sæta tiltæk %d og þöfin er %d\n", sum{r in Rooms} RoomCapacity[r], sum{c in CidAssign: c not in ComputerCourses} (cidCount[c]-SpeCidCount[c]) * Slot[c,e];
  printf : "fjöldi sæta tiltæk í tölvustofum er %d og þöfin er %d\n", sum{r in ComputerRooms} RoomCapacity[r], sum{c in ComputerCourses} cidCount[c] * Slot[c,e];
  printf : "fjöldi sæta tiltæk í sérúræði er %d og þöfin er %d\n", sum{r in SpecialRooms} RoomCapacity[r], sum{c in CidAssign: c not in ComputerCourses} SpeCidCount[c] * Slot[c,e];
  printf : "fjöldi sæta tiltæk í sérúræðitölvu er %d og þöfin er %d\n", sum{r in SpecialComputerRooms} RoomCapacity[r], sum{c in CidAssign: c in ComputerCourses} SpeCidCount[c] * Slot[c,e];
}

for {c in CidAssign: sum{b in Building} wb[c,b] > 1} {
  printf : "Namskeið %s er í %d byggingum (með sérúrræði): ", c, sum{b in Building} wb[c,b];
  printf {b in Building: wb[c,b] > 0}: "%s ", b;
  printf "\n";
}

for {c in CidAssign: sum{b in Building} wbb[c,b] > 1} {
  printf : "Namskeið %s er í %d byggingum: ", c, sum{b in Building} wbb[c,b];
  printf {b in Building: wbb[c,b] > 0}: "%s ", b;
  printf "\n";
}

# Hvaða stofur er verið að nota og hvernig er nýtingin:
for {e in SubExamSlots} {
  printf "Dagur/tími: %s\n", SlotNames[e];
  printf "Bygging stofa; fjöldi/hámarksfjöldi (forgangur) fjöldi_námskeiða:\n";
  for {b in Building} {
    printf{r in RoomInBuilding[b]: r in Rooms} : "%s %s %d/%d (%d) %d\n", b, r, sum{c in CidAssign} Slot[c,e] * h[c,r], RoomCapacity[r], RoomPriority[r], sum{c in CidAssign} w[c,r] * Slot[c,e];
  }
  printf "Tölvustofur:\n";
  printf{r in ComputerRooms} : "%s %d/%d (%d) \n", r, sum{c in CidAssign} Slot[c,e] * h[c,r], RoomCapacity[r], RoomPriority[r];
  printf "Sérúrræðistofur:\n";
  printf{r in SpecialRooms} : "%s %d/%d (%d)\n", r, sum{c in CidAssign} Slot[c,e] * h[c,r], RoomCapacity[r], RoomPriority[r];
}

# pretty print the solution for file "lausn.csv"
printf : "Dagur;Tími;ID;Námskeið;Bygging;Stofa;Fjöldi;Lengd prófs;" > "lausn.csv";
printf : "Heildarfjöldi;Hámarksfjöldi;Fjöldi námskeiða í stofu\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in Rooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;\n", SlotNames[e], CidId[c], c, b, r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;\n", b, sum{rr in RoomInBuilding[b], cc in CidAssign: rr in Rooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in Rooms} RoomCapacity[rr] >> "lausn.csv";
}
printf : "Tölvustofur;;;;;;;;;;;\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in ComputerRooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;\n", SlotNames[e], CidId[c], c, b, r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;;%d;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;\n", b, sum{rr in RoomInBuilding[b], cc in CidAssign: rr in ComputerRooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in ComputerRooms} RoomCapacity[rr] >> "lausn.csv";
}
printf : "Sérúrræði;;;;;;;;;;;\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in SpecialRooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;\n", SlotNames[e], CidId[c], c, b, r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;\n", b, sum{rr in RoomInBuilding[b], cc in CidAssign: rr in SpecialRooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in SpecialRooms} RoomCapacity[rr] >> "lausn.csv";
}
printf : "Sérúrræði tölvustofur;;;;;;;;\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in SpecialComputerRooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;\n", SlotNames[e], CidId[c], c, b, r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;;\n", b, sum{rr in RoomInBuilding[b], cc in CidAssign: rr in SpecialComputerRooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in SpecialComputerRooms} RoomCapacity[rr] >> "lausn.csv";
}

printf : "Dagur;Tími;ID;Námskeið;Bygging;Stofa;Fjöldi;Lengd prófs;Sérnemar;" > "hreinn.csv";
printf : "Fjöldinema; Hámarksæti; Fjöldinámskeiða\n" >> "hreinn.csv";

for {e in SubExamSlots} {
  for {c in CidAssign} {
     printf{r in AllRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0 and r not in SpecialRooms and r not in SpecialComputerRooms}:
     "%s;%011.0f;%s;%s;%s;%d;%d;FALSE;%d;%d;%d\n",
     SlotNames[e], CidId[c], c, b, r, h[c,r], duration[c],sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e] >> "hreinn.csv";
     printf{r in AllRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0 and (r in SpecialRooms or r in SpecialComputerRooms)}:
     "%s;%011.0f;%s;%s;%s;%d;%d;TRUE;%d;%d;%d\n",
     SlotNames[e], CidId[c], c, b, r, h[c,r], duration[c],sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e] >> "hreinn.csv";
  }
}

printf : "Dagur;Tími;Fagnúmer ID;Stofu ID;Fjöldi;Lengd\n" > "import.csv";
for {e in SubExamSlots} {
  for {c in CidAssign} {
     printf{r in AllRooms, b in BuildingWithRoom[r]: Slot[c,e] * h[c,r] > 0}: "%s;%011.0f;%d;%d;%d\n",
     SlotNames[e], CidId[c], RoomId[r], h[c,r], duration[c] >> "import.csv";
  }
}



end;
