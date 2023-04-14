using Jutul
using BattMo

graphite = Graphite()
nmc111   = NMC111()

T  = 300;
c  = 0.1;
a  = ocp(T, c, nmc111)
ba = ocp(T, c, graphite)
