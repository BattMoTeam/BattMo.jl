using Jutul
using BattMo
##
ac = ACMaterial()
grafite = Grafite()
nmc111 = NMC111()
T=300;
c=0.1;
a=ocd(T,c,nmc111)
ba=ocd(T,c,grafite)
