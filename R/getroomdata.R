rm(list=ls())
require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Proftafla_id <- Ugla.Raw$data$proftafla_id

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=rooms&proftaflaID=", Proftafla_id)
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
roomFloor = numeric(0)
for (i in c(1:length(Data))) {
  # create room name but with no spaces and icelandic characters
  tmp <- Data[[i]]$room
  tmp <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), tmp)
  tmp <- gsub(" ", "", tmp, fixed = TRUE)
  tmp <- gsub("_", "", tmp, fixed = TRUE)
  room <- c(room,tmp)
  roomFloor <- c(roomFloor,floor(as.numeric(sub("\\D*(\\d+).*", "\\1", tmp))/100))
  capacity <- as.numeric(Data[[i]]$bord_almennir)
  capacitySpecial <- as.numeric(Data[[i]]$bord_sernemar)
  computerRoom <- Data[[i]]$computerRoom
  computerRoomSpecial <- Data[[i]]$computerRoomSpecial
  roomid <- Data[[i]]$room_id
  roomID <- c(roomID,roomid)
  buildingname <- Data[[i]]$building
  buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
  buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
  buildingName = c(buildingName,buildingname)
  buildingID = c(buildingID, as.numeric(Data[[i]]$building_id))
  # split the room in two if can take both normal and special students

  if (capacity > 0 & capacitySpecial > 0) {
    roomCapacity = c(roomCapacity,capacity)
    if (computerRoom == TRUE) {
      roomType = c(roomType,2)
    } else {
      roomType = c(roomType,1)
    }
    room <- c(room,paste0(tmp,'_special'))
    roomFloor <- c(roomFloor,NA)
    roomCapacity = c(roomCapacity,capacitySpecial)
    roomID <- c(roomID,roomid) # has same room id
    buildingName = c(buildingName,buildingname)
    buildingID = c(buildingID, as.numeric(Data[[i]]$building_id))

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
# FIX NA
roomFloor[is.na(roomFloor)] = 0

FEL = c('ASK','BLF','FEL','FOR','FRA','FRG','FVS','HAG','KYN','LOG','MAN','NSR','OSS','STJ','VID','TJO')
HEL = c('GSL','HJU','LEI','LYF','LYD','LAK','MAT','NAR','SAL','SJU','TAL','TAN','TSM')
HUG = c('ABF','DAN','DET','ENS','GRF','GRI','HSP','ISE','ISL','ITA','JAP','KIN','KVI','LAT','LIS','MAF','MIS','NLF','RUS','SAG','SPA','SAN','TAK','TYD','TYS')
MEN = c('GSS','INT','ITH','KEN','LSS','MEX','MVS','NOK','STM','TOS','UMS','TRS')
VON = c('BYG','EDL','EFN','EVF','FER','HBV','IDN','JAR','JED','LAN','LEF','LIF','RAF','REI','STA','TOL','UAU','UPP','VEL')


cat("set Building := ", file="RoomData.dat",sep="\n")
ubuildings = sort(unique(buildingName))
for (i in c(1:length(ubuildings))) {
  write(ubuildings[i], file = "RoomData.dat", append = T)
}
write(";", file = "RoomData.dat", append = T)

write("set Cluster :=  Holtid Eirberg;", file = "RoomData.dat", append = T)

#write("set BuildingsInCluster['Torfan'] := Gimli Haskolatorg Logberg HusVigdisar;", file = "RoomData.dat", append = T)
#write("set BuildingsInCluster['Melurinn'] := Adalbygging Arnagardur Oddi;", file = "RoomData.dat", append = T)
Stakkahlid = c("Stakkahlid_Hamar","Stakkahlid_Klettur","Stakkahlid_Enni")
write(paste0("set BuildingsInCluster['Holtid'] := ", paste(Stakkahlid[Stakkahlid %in% ubuildings], collapse = " "),";"), file = "RoomData.dat", append = T)

#write("set BuildingsInCluster['Haskolabio'] := Haskolabio;", file = "RoomData.dat", append = T)
Eirberg = c("Eirberg")
write(paste0("set BuildingsInCluster['Eirberg'] := ", paste(Eirberg[Eirberg %in% ubuildings], collapse = " "),";"), file = "RoomData.dat", append = T)



write("set Rooms := ", file="RoomData.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 1) {
    write(room[i], file = "RoomData.dat", append = T)
  }
}
write(";", file = "RoomData.dat", append = T)


write("param RoomId := ", file = "RoomData.dat", append = T)
for (i in c(1:length(room))) {
  strcat <- sprintf('%s %s', room[i], roomID[i])
  write(strcat, file = "RoomData.dat", append = T)
}
write(";", file = "RoomData.dat", append = T)

write("param RoomCapacity := ", file = "RoomData.dat", append = T)
for (i in c(1:length(room))) {
  strcat <- sprintf('%s %d', room[i], roomCapacity[i])
  write(strcat, file = "RoomData.dat", append = T)
}
write(";", file = "RoomData.dat", append = T)

write("set ComputerRooms := ", file = "RoomData.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 2) {
    strcat <- sprintf('%s', room[i])
    write(strcat, file = "RoomData.dat", append = T)
  }
}
write(";", file = "RoomData.dat", append = T)

write("set SpecialRooms := ", file = "RoomData.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 3) {
    strcat <- sprintf('%s', room[i])
    write(strcat, file = "RoomData.dat", append = T)
  }
}
write(";", file = "RoomData.dat", append = T)

write("set SpecialComputerRooms := ", file = "RoomData.dat", append = T)
for (i in c(1:length(room))) {
  if (roomType[i] == 4) {
    strcat <- sprintf('%s', room[i])
    write(strcat, file = "RoomData.dat", append = T)
  }
}
write(";", file = "RoomData.dat", append = T)

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
  write(strcat, file = "RoomData.dat", append = T)
}

for (i in c(1:length(ubuildings))) {
  for (flo in c(0:3)){
    success = FALSE
    strcat = "set RoomInBuildingFloor['";
    strcat <- sprintf("%s%s",strcat,ubuildings[i])
    strcat <- sprintf("%s',%d] := ",strcat,flo)
    for (j in c(1:length(room))) {
      if (buildingName[j] == ubuildings[i]) {
        if (roomFloor[j] == flo) {
          success = TRUE
          strcat <- sprintf('%s %s',strcat,room[j])
        }
      }
    }
    strcat <- sprintf('%s%s',strcat,";")
    if (success == TRUE) {
      write(strcat, file = "RoomData.dat", append = T)
    }
  }
}


roomID = as.numeric(roomID)
save(file = "ubuildings.Rdata", list=c("ubuildings", "room", "roomID", "buildingName", "buildingID"))
