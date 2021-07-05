#! /usr/bin/env julia

open("cypher.txt") do f
    s = readline(f)
    for i in range(1,step=2,stop=length(s))
        convert = s[i:i+1]
        print(Char(parse(Int64, convert, base=16)))
    end
end
