Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=forsendurMessy&proftaflaID=37")
Ugla.forsendur <- readLines(Ugla.Url,  warn = "F")

for (j in c(1:length(Ugla.forsendur))) {
  if (Ugla.forsendur[[j]] == "param cidConjoinedData default 0 :=") {
    break
  }
}

cat("", file="conjoined.dat",sep="\n")
for (i in c(j:length(Ugla.forsendur))) {
  cat(Ugla.forsendur[[i]], file="conjoined.dat",append=TRUE)
  cat(c("\n"), file="conjoined.dat", append=TRUE)
}
