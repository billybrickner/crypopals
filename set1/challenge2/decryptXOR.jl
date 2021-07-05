#! /usr/bin/env julia

function convertHex(s)
    hex_array = [parse(Int, s[i:i+1], base=16) for i in range(1,step=2,stop=length(s))]
end

function printHex(s)
    for character in convertHex(s)
        print(Char(character, base=16))
    end
end

open("cypher.txt") do f
    # Get Cipher Text
    s1 = readline(f)
    l1 = convertHex(s1)
    # Get Cipher Key
    s2 = readline(f)
    l2 = convertHex(s2)
    # Decrypt
    l3 = [c1 ⊻ c2 for (c1,c2) in zip(l1,l2)]
    expected = readline(f)
    println(join(map(Char, l3)))
    println("Passed Check:",convertHex(expected)==l3)
end
