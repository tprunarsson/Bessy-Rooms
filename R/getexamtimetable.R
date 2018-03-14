rm(list=ls())
require(rjson)
require(lubridate)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=courses&proftaflaID=37")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Data <- Ugla.Raw$data
cid <- names(Data)
props <- names(Data[[cid[1]]])

load(file = c('ubuildings.Rdata'))
load(file = c('mhr.Rdata'))

# quickly extract all potential exam dates:
dates = rep(ymd_hms(Data[[cid[1]]]$start),length(cid))
vikudagur = rep(0,length(cid))
for (i in c(1:length(cid))) {
  dates[i] <- ymd_hms(Data[[cid[i]]]$start)
  vikudagur[i] <- wday(dates[i])
}
dates <- dates[vikudagur != 7 & vikudagur != 1]
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

FEL = c('ASK','BLF','FEL','FOR','FRA','FRG','FVS','HAG','KYN','LOG','MAN','NSR','OSS','STJ','VID','TJO')
HEL = c('GSL','HJU','LEI','LYF','LYD','LAK','MAT','NAR','SAL','SJU','TAL','TAN','TSM')
HUG = c('ABF','DAN','DET','ENS','GRF','GRI','HSP','ISE','ISL','ITA','JAP','KIN','KVI','LAT','LIS','MAF','MIS','NLF','RUS','SAG','SPA','SAN','TAK','TYD','TYS')
MEN = c('GSS','INT','ITH','KEN','LSS','MEX','MVS','NOK','STM','TOS','UMS','TRS')
VON = c('BYG','EDL','EFN','EVF','FER','HBV','IDN','JAR','JED','LAN','LEF','LIF','RAF','REI','STA','TOL','UAU','UPP','VEL')

FELBUILDINGS = c('Haskolatorg','Logberg','Oddi','Arnagardur')
HELBUILDINGS = c('Eirberg','Askja','Haskolatorg') # 'Stakkahlid_Hamar')
HUGBUILDINGS = c('Arnagardur','Logberg','Oddi','HusVigdisar')
MENBUILDINGS = c('Stakkahlid_Hamar','Stakkahlid_Enni','Stakkahlid_Klettur')
VONBUILDINGS = c('VR_2', 'Askja','HusVigdisar','Haskolatorg')

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
    priorityBuilding = unique(usedbefore)
    if (Data[[c]]$preferredBuildingName != "") {
      buildingname <- Data[[c]]$preferredBuildingName
      buildingname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉíáæöýðþóúé-'),c('IAAOYDTOUEiaaoydtoue_'), buildingname)
      buildingname <- gsub(" ", "", buildingname, fixed = TRUE)
      upile = unique(usedbefore)
      priorityBuilding = unique(c(priorityBuilding,buildingname))
    }
    # Special additions:
    cnameshort = substr(cname[1],1,3)
      if (cnameshort %in% VON) {
        priorityBuilding = c(priorityBuilding,VONBUILDINGS[1])
      } else if (cnameshort %in% FEL) {
        priorityBuilding = c(priorityBuilding,FELBUILDINGS[1])
      } else if (cnameshort %in% HUG) {
        priorityBuilding = c(priorityBuilding,HUGBUILDINGS[1])
      } else if (cnameshort %in% MEN) {
        priorityBuilding = c(priorityBuilding,MENBUILDINGS[1])
      } else if (cnameshort %in% HEL) {
        priorityBuilding = c(priorityBuilding,HELBUILDINGS[1])
      } else {
        priorityBuilding = 'Haskolatorg'
      }
    
    strcat = ""
    for (b in unique(priorityBuilding)) {
      strcat = sprintf("%s %s", strcat, b)
    }
    write(sprintf("set PriorityBuildings[%s] := %s;",cname,strcat), file = "SplitForPhase.dat", append = T)
    if (cnameshort %in% VON) {
      requiredBuilding = VONBUILDINGS
    } else if (cnameshort %in% FEL) {
      requiredBuilding = FELBUILDINGS
    } else if (cnameshort %in% HUG) {
      requiredBuilding = HUGBUILDINGS
    } else if (cnameshort %in% MEN) {
      requiredBuilding = MENBUILDINGS
    } else if (cnameshort %in% HEL) {
      requiredBuilding = HELBUILDINGS
    } else {
      requiredBuilding = c('Gimli','Haskolatorg','Logberg','Oddi','HusVigdisar','Arnagardur','Askja')
    }
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
  print(cname)
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  start <- ymd_hms(Data[[c]]$start)
  print(start)
  examday <- which(yday(start)==udates) - 1
  if (length(examday)==0) {
    print(yday(start))
  }
  else {
    slot <- 1 + 2*examday + ((hour(start)) > 12)
    print(slot)
    print(wday(start))
    strcat <- sprintf('%s %d 1', cname, slot)
    write(strcat, file = "SplitForPhase.dat", append = T)
  }
}
write(";", file = "SplitForPhase.dat", append = T)

