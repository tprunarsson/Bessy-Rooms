# Messy Bessy Room allocation: Beta version 0.0.1
# Authors: Thomas Philip Runarsson and Asgeir Orn Sigurpalsson
# Last modified by aos at 15:03 20/9/2016
# Last modified by tpr at 13:55 5/11/2016

# TODO: conjoined courses forced together in one!

# --- Parameter and Sets --- #

# Total number of exam days, each day is split in two (even and odd integer)
param n := 11;

# Set of all ExamSlots and their position
set ExamSlots:= 1..(2*n);

# The set of exams to be assigned to slots
set CidExam;

# This is needed since the orginal list has changes since its publication
set CidExamNew within CidExam;

# Taken from phase one solution
param Slot {CidExam, ExamSlots} binary, default 0;
# The actual dates, used for printing solution
param SlotNames{ExamSlots}, symbolic;

# It is not necessary to solve all slots at once, select the one you want.
set SubExamSlots within ExamSlots := setof{e in ExamSlots: e == 4} e;

# Set of all Computer Courses
set ComputerCourses within CidExam;

# Courses that do not require seats/rooms
set CidMHR within CidExam;

# The actual courses than will be assigned seats
set CidAssign := setof{c in CidExamNew, e in SubExamSlots: c not in CidMHR and Slot[c,e] > 0} c;

display CidAssign;

# Total number of students for each course
param cidCount{CidExam} default 0;

# The long number identification for the exam, used for printing solution
param CidId{CidExam} default 0;

# Total number of special students for each course
param SpeCidCount{CidExam} default 0;

# These are the subset of stusints within CidAssign that belong to special groups: Computer and Special
set CidAssignComp := setof{c in ComputerCourses: c not in CidMHR and c in CidAssign} c;
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

set Building;
param BuildingNames{Building}, symbolic;

set Torfan within Building;

# These building are acceptable to the course
set RequiredBuildings{CidExam} within Building default {};
# These building are the most wanted buildings, not that these are also in RequiredBuildings
set PriorityBuildings{CidExam} within Building default {};
# Tells us which rooms are in a given building
set RoomInBuilding{Building} within AllRooms default {};
# Tells us in which building has a given room
set BuildingWithRoom{r in AllRooms} within Building := setof{b in Building: r in RoomInBuilding[b]} b;
# The hfix variable is used for fixing a number of students in a given class room
# can be used for post analysis also
param hfix{CidAssign,AllRooms} default 0;
# each room has a priority, where 1 is best then 2 and worst 3
param RoomPriority{AllRooms} default 3;
# the length of an exam is needed since exams of same length should be in the same room
param duration {CidExam} default 3;

# --- Decision variables ---#

# The decision variable is to assign an exam to an exam slot (later we may add room assignments)
var h {c in CidAssign, r in AllRooms} >= 0, integer;
# indicator variable tells us if a course is assigned to a room
var w {c in CidAssign, r in AllRooms}, >= 0, <= 1, binary;
# indicator variable tells us if a course is within a building
var wb{CidAssign, Building}, >= 0, <= 1, binary;
# variable tells us if a room is occupied or not, must be minimized in objective
# when minimized it also tries to free rooms when possible and creating a saving for staff needed for monitoring the exams
var wr{AllRooms}, >= 0;
# This parameter will set a decision variable h when > 0
param h_fix {c in CidAssign, r in AllRooms} default 0;

# --- Constraints --- #

# if you would like to fix a decision do it here with parameter h_fix > 0
subject to FixH{c in CidAssign, r in AllRooms: h_fix[c,r] > 0}:
  h[c,r] = h_fix[c,r];

# Make sure that all students in the course have a seat
subject to AssignAllCidSeats{c in CidAssign}:
  sum{r in AllRooms} h[c,r] = cidCount[c];

# Special students need special rooms:
subject to SpecialCoursesReq{c in CidAssignSpec: c not in CidAssignComp}:
  sum{r in SpecialRooms} h[c,r] = SpeCidCount[c];

# Special students need special computer rooms:
subject to SpecialCompCoursesReq{c in CidAssignSpec: c in CidAssignComp}:
  sum{r in SpecialComputerRooms} h[c,r] = SpeCidCount[c];

# Computer courses should only be assigned to computer rooms or on a dummy room if there is no space!
subject to ComputerCoursesReq{c in CidAssignComp}:
  sum{r in ComputerRooms} h[c,r] = cidCount[c] - SpeCidCount[c];

# HACK THIS SHOULD NOT BE NEEDED, try to delete
#subject to ComputerCoursesReqForce{c in CidAssignComp}:
#  sum{r in Rooms} h[c,r] = 0;

# The rest of the students should be in the other rooms in preferred building
subject to RegularCoursesReq{c in CidAssign: c not in CidAssignComp}:
  sum{r in Rooms} h[c,r] = cidCount[c] - SpeCidCount[c];

# HACK THIS SHOULD NOT BE NEEDED, try to delete
#subject to RegularCoursesReqForce{c in CidAssign: c not in CidAssignComp}:
#  sum{r in ComputerRooms} h[c,r] = 0;

# The number of students in a room should not go over the limit
# n.b. this is the total number of useful seats (reduce the number is there a "bad seats" in the room)
subject to RoomCapacityLimit{r in AllRooms, e in SubExamSlots}:
  sum{c in CidAssign} h[c,r] * Slot[c,e] <=  RoomCapacity[r];

# A constraint for the indicator binary variable is course c in room r, the 1.0001 is a hack needed ?!
# the sum sum{cc in CidAssign} cidCount[cc] corresponds to a big value, i.e. Big-M approach
subject to CourseInRoom{c in CidAssign, r in AllRooms}:
  1.0001*h[c,r] <= w[c,r] * sum{cc in CidAssign} cidCount[cc];
subject to CourseInRoom2{c in CidAssign, r in AllRooms}:
  1.0001*h[c,r] >= w[c,r];

# Don't put courses that do not have the same length (duration) in the same room
subject to NotTheSameRoom{r in AllRooms, c1 in CidAssign, c2 in CidAssign: c1 < c2 and duration[c1]!=duration[c2]}:
  (w[c1,r] + w[c2,r]) <= 1;

# Don't use too many rooms for small courses, say 12 ?!
# n.b. this applies only to Rooms which are not ComputerRooms or SpecialRooms
subject to NotTooManyRooms{c in CidAssign: (cidCount[c]-SpeCidCount[c]) <= 12}:
  sum{r in Rooms} w[c,r] <= 1;
# We will force the courses in many rooms within the builing, however, they
# should be more than 12 in a room or less for a 2 way split
# this should avoid the possibility of putting courses as singles in rooms
subject to NotToFewStudents{c in CidAssign, r in Rooms: (cidCount[c]-SpeCidCount[c]) >= 12}:
  h[c,r] >= w[c,r] * min(12,(cidCount[c]-SpeCidCount[c])/2);

# Do not have too many different exams in the same room, more traffic from teachers
# try to maximize the number of courses in a room !!! Helps with table assignments (different exams at each table)
subject to NotTooManyCourse{e in SubExamSlots, r in AllRooms: r not in SpecialRooms and r not in SpecialComputerRooms}:
  sum{c in CidAssign} w[c,r] * Slot[c,e] <= if (RoomCapacity[r] >= 80) then 3 else 2;

# The same applied to Special Courses, but here we can have more teachers entering the rooms
subject to NotTooManyCoursesSpecial{e in SubExamSlots, r in AllRooms: r in SpecialRooms or r in SpecialComputerRooms}:
  sum{c in CidAssign} w[c,r] * Slot[c,e] <= 6;

# A constraint for the indicator binary variable is course c in building b, the 1.0001 is a hack needed ?!
subject to IsCidInBuilding{c in CidAssign, b in Building}:
  1.0001 * sum{r in RoomInBuilding[b]} w[c,r] <= wb[c,b] * 10000;
subject to IsCidInBuilding2{c in CidAssign, b in Building}:
  1.0001 * sum{r in RoomInBuilding[b]} w[c,r]  >= wb[c,b];

############# TEST ZONE ##############

# A constraint for the indicator binary variable is course c in building b, the 1.0001 is a hack needed ?!
# This variable is different to wb in that it only considers regular exams as in the building!
var wbb{CidAssign,Building}, <= 1, >= 0, binary;
subject to IsCidInBuildingBB{c in CidAssign, b in Building}:
  1.0001 * sum{r in RoomInBuilding[b]: r in Rooms} w[c,r] <= wbb[c,b] * 10000;
subject to IsCidInBuildingBB2{c in CidAssign, b in Building}:
  1.0001 * sum{r in RoomInBuilding[b]: r in Rooms} w[c,r]  >= wbb[c,b];

# Can only be in one building if not on the green!
var NumberOfBuildings{CidAssign}, >= 0;
subject to OnlyOneUnlessOnTheGreen{c in CidAssign, bb in Building: bb not in Torfan}:
  sum{b in Building: bb <> b} wbb[c,b] + wbb[c,bb] <= NumberOfBuildings[c];

#####################

# If the room is occupied then wr is forced to 1 else it will tend to zero due to the objective function
subject to RoomOccupied{c in CidAssign, r in AllRooms}: w[c,r] <= wr[r];

# This would be a hard condition on the number this condition is made soft since it does not work allways, should be added to phase 1 */
#subject to CourseMayOnlyBeInOneBuildingSpec{c in CidAssign: SpeCidCount[c]>0}: sum{b in Building} wb[c,b] <= 3;
#subject to CourseMayOnlyBeInOneBuilding{c in CidAssign: SpeCidCount[c]==0}: sum{b in Building} wb[c,b] <= 2;

# Force a solution!
subject to ForceNumberInRoom{c in CidAssign, r in AllRooms: hfix[c,r]>0}: h[c,r] = hfix[c,r];

# Special condition for Laugarvatn, too far away ;)
subject to EkkiLaugarvatn{c in CidAssign: 'Laugarvatn' not in RequiredBuildings[c]}:
  sum{r in RoomInBuilding['Laugarvatn']} h[c,r] = 0;

# Objective function
minimize Objective:
# 1.) we don't want to use Klettur and Enni (unless asked for)
+ 100 * sum{c in CidAssign, b in Building: (b == 'Klettur' or b == 'Enni') and b not in RequiredBuildings[c]} wb[c,b]
# 1.1) even when asked for we really don't want to go here ...
+ 10 * sum{c in CidAssign, b in Building: (b == 'Klettur' or b == 'Enni')} wb[c,b]
# 2.) We don't want to use Hamar unless asked for
+ 75 * sum{c in CidAssign, b in Building: b == 'Hamar' and b not in RequiredBuildings[c]} wb[c,b]
# 3.) Avoid also Eirberg is not on your list
+ 50 * sum{c in CidAssign, b in Building: b == 'Eirberg' and b not in RequiredBuildings[c]} wb[c,b]
# 4.) Avoid buildings that are not on your list, note that this adds to RequiredBuildings, so not too big please
+ 5 * sum{c in CidAssign, b in Building: b not in PriorityBuildings[c]} wb[c,b]
+ 20 * sum{c in CidAssign, b in Building: b not in RequiredBuildings[c]} wb[c,b]
# 5.) minimize the number of buildings used, weight should be equal to Required or higher?
#+ 50 * sum{c in CidAssign, b in Building: b not in Torfan} wb[c,b]
+ 10 * sum{c in CidAssign, b in Building} wb[c,b]
+ 1000 * sum{c in CidAssign} NumberOfBuildings[c]
# 6.) Empty rooms when possible
+ 10 * sum{r in AllRooms} wr[r]
# 7.) Use as many rooms as possible also but with smaller priority
- (1/card(CidAssign)) * sum{c in CidAssign,r in Rooms} w[c,r]
# 10.) all else being equal use rooms with better priority (low weight here)
+ (0.1/card(CidAssign)) * sum{c in CidAssign, r in AllRooms} w[c,r] * RoomPriority[r]
;

# Some debugging now for the data supplied:
set UnionOfRoomsInBuildings := setof{b in Building, r in RoomInBuilding[b]} r;
check card(UnionOfRoomsInBuildings) == card(AllRooms);
check {c in CidAssign} cidCount[c] >= SpeCidCount[c];

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
}

for {c in CidAssign: sum{b in Building} wb[c,b] > 1} {
  printf : "Namskeið %s er í %d byggingum (með sérúrræði): ", c, sum{b in Building} wb[c,b];
  printf {b in Building: wb[c,b] > 0}: "%s ", BuildingNames[b];
  printf "\n";
}

for {c in CidAssign: sum{b in Building} wbb[c,b] > 1} {
  printf : "Namskeið %s er í %d byggingum: ", c, sum{b in Building} wbb[c,b];
  printf {b in Building: wbb[c,b] > 0}: "%s ", BuildingNames[b];
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

# pretty print the solution for file "lausn.csv"
printf : "Dagur;Tími;ID;Námskeið;Stofa;Bygging;Fjöldi;Lengd prófs;" > "lausn.csv";
printf : "Heildarfjöldi;Hámarksfjöldi;Fjöldi námskeiða;Forgangur\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in Rooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;;\n", SlotNames[e], CidId[c], c, BuildingNames[b], r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;;%d;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e], RoomPriority[r] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;;\n", BuildingNames[b], sum{rr in RoomInBuilding[b], cc in CidAssign: rr in Rooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in Rooms} RoomCapacity[rr] >> "lausn.csv";
}
printf : "Tölvustofur;;;;;;;;;;;;\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in ComputerRooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;;\n", SlotNames[e], CidId[c], c, BuildingNames[b], r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;;%d;%d;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e], RoomPriority[r] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;;\n", BuildingNames[b], sum{rr in RoomInBuilding[b], cc in CidAssign: rr in ComputerRooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in ComputerRooms} RoomCapacity[rr] >> "lausn.csv";
}
printf : "Sérúrræði;;;;;;;;;;;;\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in SpecialRooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;\n", SlotNames[e], CidId[c], c, BuildingNames[b], r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;%d;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e], RoomPriority[r] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;;\n", BuildingNames[b], sum{rr in RoomInBuilding[b], cc in CidAssign: rr in SpecialRooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in SpecialRooms} RoomCapacity[rr] >> "lausn.csv";
}
printf : "Sérúrræði tölvustofur;;;;;;;;;\n" >> "lausn.csv";
for {e in SubExamSlots, b in Building} {
  for {r in RoomInBuilding[b]: r in SpecialComputerRooms} {
    printf {c in CidAssign: Slot[c,e] * h[c,r] > 0} : "%s;%011.0f;%s;%s;%s;%d;%d;;;;;\n", SlotNames[e], CidId[c], c, BuildingNames[b], r, h[c,r], duration[c] >> "lausn.csv";
    printf : ";;;;;%s;;%d;%d;%d;%d\n", r, sum{cc in CidAssign} Slot[cc,e] * h[cc,r], RoomCapacity[r], sum{cc in CidAssign} w[cc,r] * Slot[cc,e], RoomPriority[r] >> "lausn.csv";
  }
  printf : ";;;;%s;;;;%d;%d;;;\n", BuildingNames[b], sum{rr in RoomInBuilding[b], cc in CidAssign: rr in SpecialComputerRooms} Slot[cc,e] * h[cc,rr], sum{rr in RoomInBuilding[b]: rr in SpecialComputerRooms} RoomCapacity[rr] >> "lausn.csv";
}

end;
