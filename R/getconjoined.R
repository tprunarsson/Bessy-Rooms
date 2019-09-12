rm(list=ls())
require(rjson)

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Proftafla_id <- Ugla.Raw$data$proftafla_id

Proftafla_id = 58

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=sameiginlegNamskeid&proftaflaID=", Proftafla_id)
Ugla.Conjoined <- readLines(Ugla.Url,  warn = "F")
Ugla.raw <- fromJSON(Ugla.Conjoined)

Cid <- names(Ugla.raw$data)
M <- matrix(rep(0,length(Cid)*length(Cid)),nrow=length(Cid))
cat("param cidConjoinedData default 0 :=", file="conjoined.dat",sep="\n")
if (length(Cid)>0) {
  for (i in c(1:length(Cid))) {
    CidList <- Ugla.raw$data[[i]]
    for (j in c(1:length(CidList))) {
      idx <- which(CidList[j]==Cid)
      M[i,idx] <- 1
    }
  }
  for (i in c(1:length(Cid))) {
    for (j in c(i:length(Cid))) {
      if ((j > i) & (M[i,j] == 1)) {
        str <- c(Cid[i],",",Cid[j])
        str <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), str)
        cat(c("[",str,"] 1\n"), file="conjoined.dat", append=TRUE)
      }
    }
  }
}
cat(c(";\n"), file="conjoined.dat", append=TRUE)
