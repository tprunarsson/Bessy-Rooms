# Messy Bessy Room allocation model
Bessy room allocation for assigned exams

Post run:

cat test.sol | grep 'h(' | grep -v ') 0' > rusl.txt

sed -i 's/,/ /g' rusl.txt

sed -i 's/h(/ /g' rusl.txt

sed -i 's/)/ /g' rusl.txt

echo "param hfix := " >  hfix.dat

cat rusl.txt >> hfix.dat

echo ";" >> hfix.dat

echo "end;" >> hfix.dat

glpsol --math BessyRooms.mod -d courses.dat -d default.dat  -d resources.dat -d RoomData.dat -d SplitForPhase.dat -d 
RoomsAndBuildings.dat -d conjoined.dat -d forgangur.dat -d hfix.dat

