opt target : n635 (d7)
Input list : n143(d3) n167(d4) n312(d4) n288(d3) n368(d4) n344(d3) 
old bexp : (((((n312 xor n288) xor (n167 xor n143)) xor (n368 xor n344)) and ((((n312 xor n288) xor (n167 xor n143)) and (n368 xor n344)) xor ((n312 xor n288) and (n167 xor n143)))) and ((((((n312 xor n288) xor (n167 xor n143)) and (n368 xor n344)) xor ((n312 xor n288) and (n167 xor n143))) and (((n312 xor n288) xor (n167 xor n143)) and (n368 xor n344))) xor (not(((n312 xor n288) xor (n167 xor n143)) and (n368 xor n344)))))
new bexp : (((n344 xor n368) and (n288 xor n312)) and (n143 xor n167))


