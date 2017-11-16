rm(list=ls())
require(rjson)
require(lubridate)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=courses&proftaflaID=34")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Data <- Ugla.Raw$data
cid <- names(Data)
props <- names(Data[[cid[1]]])

load(file = c('ubuildings.Rdata'))
load(file = c('mhr.Rdata'))

# quickly extract all potential exam dates:
dates = rep(ymd_hms(Data[[cid[1]]]$start),length(cid))
for (i in c(1:length(cid))) {
  dates[i] <- ymd_hms(Data[[cid[i]]]$start)
}
udates = sort(unique(yday(dates)))
uudates = as.Date(udates-1, origin = sprintf("%d-01-01",year(dates[1])))
uhours = sort(table(sprintf("%02d:%02d",hour(dates),minute(dates))),decreasing = TRUE)
morningafternoon = sort(hm(names(uhours)[1:2]))
morningafternoon = sprintf("%02d:%02d",hour(morningafternoon),minute(morningafternoon))
cat("param SlotNames := ", file="SplitForPhase.dat",sep="\n")
for (i in c(1:length(uudates))) {
  strcat = sprintf("%d '%d.%d.%d;%s'",1+2*(i-1),year(uudates[i]),month(uudates[i]),day(uudates[i]),morningafternoon[1])
  write(strcat, file = "SplitForPhase.dat", append = T)
  strcat = sprintf("%d '%d.%d.%d;%s'",2*i,year(uudates[i]),month(uudates[i]),day(uudates[i]),morningafternoon[2])
  write(strcat, file = "SplitForPhase.dat", append = T)
}
write(";", file = "SplitForPhase.dat", append = T)

write("param hdef := ", file = "SplitForPhase.dat", append = T)
for (c in cid) {
  cname <- Data[[c]]$'courseName'
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  if ((cname %in% MHR) == FALSE) {
    if (Data[[c]]$preferredRoom != "" & (length(as.numeric(Data[[c]]$preferredRoomSeats))>0)) {
      strcat = cname
      roomname = room[which(as.numeric(Data[[c]]$preferredRoom)==roomID)]
      print(roomname)
      strcat = sprintf("%s %s %d", cname, roomname, as.numeric(Data[[c]]$preferredRoomSeats) )
      write(strcat, file = "SplitForPhase.dat", append = T)
    }
  }
}
write(";", file = "SplitForPhase.dat", append = T)

write("param duration := ", file = "SplitForPhase.dat", append = T)
for (c in cid) {
  cname <- Data[[c]]$'courseName'
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  if ((cname %in% MHR) == FALSE) {
    if ((length(as.numeric(Data[[c]]$duration))>0)) {
      strcat = cname
      strcat = sprintf("%s %.1f", cname, as.numeric(Data[[c]]$duration) )
      if (as.numeric(Data[[c]]$duration) != 3) {
        write(strcat, file = "SplitForPhase.dat", append = T)
      }
    }
  }
}
write(";", file = "SplitForPhase.dat", append = T)


for (c in cid) {
  usedbefore = character(0)
  cname <- Data[[c]]$'courseName'
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  if ((cname %in% MHR) == FALSE) {
    for (i in Data[[c]]$priorityRooms) {
      buildingname <- i$building # Data[[c]]$priorityRooms[[i]]
      buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
      buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
      if (buildingname %in% ubuildings) {
        usedbefore = c(usedbefore, buildingname)
      }
    }
    requiredBuilding = usedbefore
    if (Data[[c]]$preferredBuildingName != "") {
      buildingname <- Data[[c]]$preferredBuildingName
      buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
      buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
      upile = unique(usedbefore)
      usedbefore = c(usedbefore,buildingname)
      if (buildingname == 'Haskolatorg' & length(requiredBuilding) == 0) {
        usedbefore = c('Gimli','Haskolatorg','Logberg','Oddi','HusVigdisar','Arnagardur','Askja')
      }
      if (buildingname == 'Haskolatorg' & length(upile) == 1) {
        usedbefore = c(usedbefore,'Gimli','Haskolatorg','Logberg','Oddi','HusVigdisar','Arnagardur','Askja')
      }
    }
    # Special additions:
    cnameshort = substr(cname[1],1,3)
    if (cnameshort == 'LAK' | cnameshort == 'TAN' | cnameshort == 'SJU' | cnameshort == 'HJU') {
      usedbefore = c(usedbefore, 'Eirberg')
    }
    usedbefore = unique(usedbefore)
    if (length(usedbefore) == 0) {
      usedbefore = c('Gimli','Haskolatorg','Logberg','Oddi','HusVigdisar','Arnagardur','Askja') # if nothing has been chosen ...
    }
    if (length(usedbefore) == 1) {
      usedbefore = c(usedbefore,'Gimli','Haskolatorg','Logberg','Oddi','HusVigdisar','Arnagardur','Askja')
    }
    strcat = ""
    for (b in unique(usedbefore)) {
      strcat = sprintf("%s %s", strcat, b)
    }
    write(sprintf("set PriorityBuildings[%s] := %s;",cname,strcat), file = "SplitForPhase.dat", append = T)
    strcat = ""
    for (b in unique(requiredBuilding)) {
      strcat = sprintf("%s %s", strcat, b)
    }
    if (strcat != "") {
      write(sprintf("set RequiredBuildings[%s] := %s;",cname,strcat), file = "SplitForPhase.dat", append = T)
    }
  }
}


write("param Slot := ", file="SplitForPhase.dat", append = T)
for (c in cid) {
  cname <- Data[[c]]$'courseName'
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  start <- ymd_hms(Data[[c]]$start)
  examday <- which(yday(start)==udates) - 1
  slot <- 1 + 2*examday + ((hour(start)) > 12)
  strcat <- sprintf('%s %d 1', cname, slot)
  write(strcat, file = "SplitForPhase.dat", append = T)
}
write(";", file = "SplitForPhase.dat", append = T)

