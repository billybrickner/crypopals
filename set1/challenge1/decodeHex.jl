#! /usr/bin/env julia

function printHex(s)
    for i in range(1,step=2,stop=length(s))
        convert = s[i:i+1]
        print(Char(parse(Int, convert, base=16)))
    end
end

open("cipher.txt") do f
    s = readline(f)
    printHex(s)
    print('\n')
end
