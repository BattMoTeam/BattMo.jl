function computeOCPFunc_Graphite_paper(c, T, cmax)

    data = [0.00112867 1.0445
            0.00778984 0.7565
            0.0111049 0.5524
            0.0188711 0.412133
            0.0320813 0.315165
            0.0337326 0.303635
            0.0353839 0.292696
            0.0370352 0.282402
            0.0386865 0.272803
            0.0403378 0.263897
            0.041989 0.255509
            0.0436403 0.247479
            0.0452916 0.239904
            0.0469429 0.233055
            0.0485942 0.226877
            0.0502455 0.221269
            0.0518966 0.216244
            0.0535479 0.211818
            0.0551992 0.207841
            0.0568505 0.204308
            0.0585017 0.201218
            0.060153 0.198572
            0.0618043 0.196365
            0.0634556 0.194596
            0.0651069 0.193267
            0.0667582 0.192342
            0.0684094 0.191815
            0.0700607 0.191588
            0.0865736 0.190156
            0.0915274 0.189507
            0.09483 0.188836
            0.0981326 0.187927
            0.103086 0.18612
            0.10804 0.183796
            0.112994 0.18108
            0.122902 0.174683
            0.132809 0.167647
            0.141066 0.161102
            0.155927 0.148768
            0.160881 0.14489
            0.165835 0.141218
            0.187302 0.126627
            0.190605 0.124624
            0.193907 0.122836
            0.19721 0.121263
            0.200512 0.119904
            0.203815 0.11876
            0.208769 0.117446
            0.236841 0.112202
            0.243446 0.111242
            0.251702 0.110371
            0.322706 0.106419
            0.395363 0.104358
            0.408573 0.103829
            0.431691 0.102444
            0.436645 0.101966
            0.44325 0.101088
            0.448204 0.100248
            0.451506 0.0994756
            0.45646 0.0975449
            0.459763 0.0959175
            0.464717 0.0930551
            0.46967 0.0896039
            0.476276 0.0844563
            0.481229 0.0814558
            0.484532 0.0798546
            0.489486 0.0779722
            0.492788 0.0771046
            0.496091 0.0765806
            0.504347 0.0759713
            0.514255 0.0755982
            0.586912 0.0754924
            0.600122 0.0751734
            0.644707 0.0735591
            0.656266 0.0733773
            0.677732 0.0733614
            0.945599 0.0733
            0.968664 0.0707
            0.98927 0.0628
            0.995262 0.0497
            0.997814 0.0393
            0.999526 0.0236]
    
    ocp =  get_1d_interpolator(cmax.*data[:, 1], data[:, 2] cap_endpoints =false)
    
    return ocp
    
end

function  computeOCPFunc_NMC_paper(c, T, cmax)

    data = [0.0027 4.6697
            0.0737 4.6107
            0.1217 4.5655
            0.1572 4.5308
            0.1838 4.4891
            0.2087 4.4474
            0.2265 4.4022
            0.2478 4.3293
            0.262 4.28317
            0.27386 4.2527
            0.276825 4.24554
            0.27979 4.2391
            0.282755 4.23338
            0.284238 4.23079
            0.287203 4.226
            0.291651 4.21913
            0.294615 4.21503
            0.296099 4.21316
            0.300545 4.20807
            0.303511 4.20504
            0.307959 4.20104
            0.310923 4.19881
            0.315371 4.19601
            0.321302 4.19257
            0.336128 4.18479
            0.34354 4.18074
            0.347988 4.17797
            0.352434 4.17477
            0.356882 4.1711
            0.36133 4.16688
            0.365778 4.16211
            0.373191 4.15359
            0.376155 4.14998
            0.380603 4.14418
            0.385051 4.13801
            0.388015 4.13368
            0.392463 4.12687
            0.402841 4.11015
            0.407289 4.10316
            0.41322 4.09418
            0.417666 4.08769
            0.422114 4.08142
            0.441387 4.05487
            0.447317 4.04696
            0.453247 4.03948
            0.459177 4.03243
            0.488828 3.99933
            0.497724 3.98897
            0.505136 3.98002
            0.524409 3.9562
            0.531823 3.94679
            0.539235 3.93717
            0.552577 3.91922
            0.57185 3.8925
            0.579264 3.88265
            0.585194 3.87503
            0.607431 3.84704
            0.614845 3.83797
            0.625221 3.82591
            0.640048 3.80951
            0.644495 3.80481
            0.648942 3.80036
            0.656356 3.79352
            0.674146 3.77879
            0.681559 3.77304
            0.687489 3.76883
            0.691937 3.7659
            0.721587 3.74797
            0.731965 3.7413
            0.743825 3.7333
            0.751238 3.72807
            0.758651 3.72264
            0.807574 3.68578
            0.814987 3.67951
            0.8224 3.6724
            0.826847 3.66774
            0.853533 3.63876
            0.9014 3.5983
            0.9494 3.5585
            1.0009 3.5203]

    ocp =  get_1d_interpolator(cmax.*data[:, 1], data[:, 2] cap_endpoints =false)
    
    return ocp
    
end


function computeDiffusionCoefficient_paper(c, T)
    
    D = 8.794e-11*(c./1000).^2 - 3.972e-10*(c./1000) + 4.862e-10;

    return D
end


function computeElectrolyteConductivity_paper(c, T)

    creg = 0.1
    conductivity = 0.1297*(c./1000).^3 - 2.51*(c./1000).^1.5 + 3.329*(c./1000) + creg;

    return conductivity
    
end