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

write("param hfix := ", file = "SplitForPhase.dat", append = T)
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

for (c in cid) {
  strcat = ""
  usedbefore = character(0)
  cname <- Data[[c]]$'courseName'
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  if ((cname %in% MHR) == FALSE) {
    if (Data[[c]]$preferredBuildingName != "") {
      buildingname <- Data[[c]]$preferredBuildingName
      buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
      buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
      usedbefore = buildingname
    }
    for (i in Data[[c]]$priorityRooms) {
      buildingname <- i$building # Data[[c]]$priorityRooms[[i]]
      buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
      buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
      if (buildingname %in% ubuildings) {
        usedbefore = c(usedbefore, buildingname)
      }
    }
    if (length(usedbefore) == 0) {
      usedbefore = c('Haskolatorg') # if nothing has been chosen ...
    }
    for (b in unique(usedbefore)) {
      strcat = sprintf("%s %s", strcat, b)
    }
    write(sprintf("set PriorityBuildings[%s] = %s;",cname,strcat), file = "SplitForPhase.dat", append = T)
  }
}


write("param Slots := ", file="SplitForPhase.dat", append = T)
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

