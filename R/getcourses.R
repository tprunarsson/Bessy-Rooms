require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Proftafla_id <- Ugla.Raw$data$proftafla_id

Proftafla_id = 58

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=coursesMessy&proftaflaID=", Proftafla_id)
Ugla.course <- readLines(Ugla.Url,  warn = "F")
cat("", file="courses.dat",sep="\n")
for (i in c(1:length(Ugla.course))) {
  cat(Ugla.course[[i]], file="courses.dat",append=TRUE)
  cat(c("\n"), file="courses.dat", append=TRUE)
}

cat("", file="namskeid.txt",sep="")
for (i in c(2:length(Ugla.course))) {
  if (Ugla.course[[i]] == ';') {
    break;
  }
  cat(Ugla.course[[i]], file="namskeid.txt",append=TRUE)
  cat(c("\n"), file="namskeid.txt", append=TRUE)  
}

cat("", file="namskeidid.txt",sep="")
# scan for param "param CidId :="
for (k in c(1:length(Ugla.course))) {
  if (identical(unlist(Ugla.course[[k]]),"param CidId :=")== TRUE) {
    break;
  }
}
for (i in c((k+1):length(Ugla.course))) {
  if (Ugla.course[[i]] == ';') {
    break;
  }
  cat(Ugla.course[[i]], file="namskeidid.txt",append=TRUE)
  cat(c("\n"), file="namskeidid.txt", append=TRUE)  
}

load('ubuildings.Rdata')

namsid = read.csv('namskeidid.txt',sep=" ", header = FALSE, stringsAsFactors = FALSE)

DEBUGSTR = NULL
for (i in c(1:nrow(namsid))) {
  print(namsid$V1[i])
  Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=courseRooms&course=", sprintf('%011.0f',namsid$V2[i]))
  Ugla.Data <- readLines(Ugla.Url,  warn = "F")
  Ugla.Raw <- fromJSON(Ugla.Data)
  idn = NULL
  if (length(Ugla.Raw$data) > 0) {
    Ugla.Raw$data[[1]]$name
    ids = NULL
    bn = NULL
    for (j in c(1:length(Ugla.Raw$data))) {
      ids = c(ids, as.numeric(Ugla.Raw$data[[j]]$room_id))
      idn = c(idn, Ugla.Raw$data[[j]]$name)
    }
    idx = which(roomID %in% ids)
    print(idn)
    if (length(idx) > 0) {
      print(paste0(sort(room[idx]),collapse = " "))
      strcat = "set CourseInRoom[";
      strcat <- sprintf("%s%s] := ",strcat,namsid$V1[i])
      strcat <- sprintf("%s %s;",strcat,paste0(room[idx],collapse = " "))
      cat(strcat, file="courses.dat",append=TRUE)
      cat(c("\n"), file="courses.dat", append=TRUE)
      strcat = "set CourseInBuilding[";
      strcat <- sprintf("%s%s] := ",strcat,namsid$V1[i])
      strcat <- sprintf("%s %s;",strcat,paste0(unique(buildingName[idx]),collapse = " "))
      cat(strcat, file="courses.dat",append=TRUE)
      cat(c("\n"), file="courses.dat", append=TRUE)
      bn = paste0(unique(buildingName[idx]),collapse = " ")
    }
  }
  DEBUGSTR = c(DEBUGSTR, sprintf('%s "%s:%s"', namsid$V1[i], paste0(idn,collapse = " "), bn))
}
strcat = "param DebugCourseRooms :=";
cat(strcat, file="courses.dat",append=TRUE)
cat(c("\n"), file="courses.dat", append=TRUE)
for (i in c(1:length(DEBUGSTR))) {
  strcat = DEBUGSTR[i]
  if (nchar(strcat) > 70)
    strcat = paste0(substr(strcat,1,min(70,nchar(strcat))),'"')
  cat(strcat, file="courses.dat",append=TRUE)
  cat(c("\n"), file="courses.dat", append=TRUE)
}
cat(c(";\n"), file="courses.dat", append=TRUE)
