rm(list=ls())
require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=rooms")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Data <- Ugla.Raw$data
props <- names(Data[[1]])
room = character(0)
roomID = character(0)
roomCapacity = numeric(0)
roomType = numeric(0)
buildingID = numeric(0)
buildingName = character(0)
for (i in c(1:length(Data))) {
  # create room name but with no spaces and icelandic characters
  tmp <- Data[[i]]$room
  tmp <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), tmp)
  tmp <- gsub(" ", "", tmp, fixed = TRUE)
  room <- c(room,tmp)
  capacity <- as.numeric(Data[[i]]$capacity)
  capacitySpecial <- as.numeric(Data[[i]]$capacitySpecial)
  capacity <- as.numeric(Data[[i]]$capacity)
  computerRoom <- Data[[i]]$computerRoom
  computerRoomSpecial <- Data[[i]]$computerRoomSpecial
  roomid <- Data[[i]]$roomID
  roomID <- c(roomID,roomid)
  buildingname <- Data[[i]]$building
  buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
  buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
  buildingName = c(buildingName,buildingname)
  buildingID = c(buildingID, as.numeric(Data[[i]]$buildingID))
  # split the room in two if can take both normal and special students
  
  if (capacity > 0 & capacitySpecial > 0) {
    roomCapacity = c(roomCapacity,capacity)
    if (computerRoom == TRUE) {
      roomType = c(roomType,2)
    } else {
      roomType = c(roomType,1)
    }
    room <- c(room,paste0(tmp,'_special'))
    roomCapacity = c(roomCapacity,capacitySpecial)
    roomID <- c(roomID,roomid) # has same room id
    buildingName = c(buildingName,buildingname)
    buildingID = c(buildingID, as.numeric(Data[[i]]$buildingID))
    
    if (computerRoomSpecial == TRUE) {
      roomType = c(roomType,4)
    } else {
      roomType = c(roomType,3)
    }
  } else if (capacity > 0) {
    roomCapacity = c(roomCapacity,capacity)
    if (computerRoom == TRUE) {
      roomType = c(roomType,2)
    } else {
      roomType = c(roomType,1)
    }
  } else if (capacitySpecial > 0) {
    roomCapacity = c(roomCapacity,capacitySpecial)
    if (computerRoomSpecial == TRUE) {
      roomType = c(roomType,4)
    } else {
      roomType = c(roomType,3)
    }
  } else {
    error("room has no capacity")
  }
}

cat("set Building := ", file="roomdata.dat",sep="\n")
ubuildings = sort(unique(buildingName))
for (i in c(1:length(ubuildings))) {
  write(ubuildings[i], file = "roomdata.dat", append = T)
}
write(";", file = "roomdata.dat", append = T)

write("set Cluster :=  Torfan Melurinn Holtid ;", file = "roomdata.dat", append = T)

write("set BuildingsInCluster['Torfan'] := Gimli Haskolatorg Logberg Oddi HusVigdisar Arnagardur Askja;", file = "roomdata.dat", append = T)
write("set BuildingsInCluster['Melurinn'] := Adalbygging Arnagardur Oddi;", file = "roomdata.dat", append = T)
write("set BuildingsInCluster['Holtid'] := Stakkahlid_Hamar Stakkahlid_Klettur Stakkahlid_Enni;", file = "roomdata.dat", append = T)



write("set Rooms := ", file="roomdata.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 1) {
    write(room[i], file = "roomdata.dat", append = T)
  }
}
write(";", file = "roomdata.dat", append = T)

write("param RoomId := ", file = "roomdata.dat", append = T)
for (i in c(1:length(room))) {
  strcat <- sprintf('%s %s', room[i], roomID[i])
  write(strcat, file = "roomdata.dat", append = T)
}
write(";", file = "roomdata.dat", append = T)

write("param RoomCapacity := ", file = "roomdata.dat", append = T)
for (i in c(1:length(room))) {
  strcat <- sprintf('%s %d', room[i], roomCapacity[i])
  write(strcat, file = "roomdata.dat", append = T)
}
write(";", file = "roomdata.dat", append = T)

write("set ComputerRooms := ", file = "roomdata.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 2) {
    strcat <- sprintf('%s', room[i])
    write(strcat, file = "roomdata.dat", append = T)
  }
}
write(";", file = "roomdata.dat", append = T)

write("set SpecialRooms := ", file = "roomdata.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 3) {
    strcat <- sprintf('%s', room[i])
    write(strcat, file = "roomdata.dat", append = T)
  }
}
write(";", file = "roomdata.dat", append = T)

write("set SpecialComputerRooms := ", file = "roomdata.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 4) {
    strcat <- sprintf('%s', room[i])
    write(strcat, file = "roomdata.dat", append = T)
  }
}
write(";", file = "roomdata.dat", append = T)

for (i in c(1:length(ubuildings))) {
  strcat = "set RoomInBuilding['";
  strcat <- sprintf('%s%s',strcat,ubuildings[i])
  strcat <- sprintf('%s%s',strcat,"'] := ")
  for (j in c(1:length(room))) {
    if (buildingName[j] == ubuildings[i]) {
      strcat <- sprintf('%s %s',strcat,room[j])
    }
  }
  strcat <- sprintf('%s%s',strcat,";")
  write(strcat, file = "roomdata.dat", append = T)
}
roomID = as.numeric(roomID)
save(file = "ubuildings.Rdata", list=c("ubuildings", "room", "roomID"))
