#! /usr/bin/env julia

using CSV
using DataFrames
using Printf

function convertHex(s)
    hex_array = [parse(Int, s[i:i+1], base=16) for i in range(1,step=2,stop=length(s))]
end

function strToIntArray(s)
    return [Int(c) for c in s]
end

function prettyPrint(s)
    if typeof(s) == String
        for character in convertHex(s)
            print(Char(character, base=16))
        end
    elseif typeof(s) == Array{Int64,1}
        println(join(map(Char, s)))
    end
end

@inbounds function xorMask(cipher, mask)
    text = Int[character for character in cipher]
    # BUGFIX: Start at 0 to account for i + j starting at 1
    for i in range(0,step=length(mask),stop=length(text))
        for (j, maskByte) in enumerate(mask)
            if length(text) >= i + j
                #println("I+J:",i+j)
                text[i+j] ⊻= maskByte
            end
        end
    end
    return text
end

function getLetterFrequency()
    df = DataFrame(CSV.File("../../common/frequency.csv"))
    df = Matrix{Union{Float64,String}}(df)
    characterToFrequency = Dict{Int64,Float64}()
    for i in 1:size(df)[1]
        characterToFrequency[Int64(df[i,1][1])] = df[i,2]
    end

    return characterToFrequency
end

characterToFrequency = getLetterFrequency()
@inbounds function scoreText(text)
    score = 0
    for character in text
        score += get(characterToFrequency, character, 0.0)
    end
    return score
end

open("cipher.txt") do f
    s = ""
    while ! eof(f)
        s = string(s, readline(f))
    end
    for i in 1:22
        s = string(s,s)
    end

    # println("s: ",s)
    i = strToIntArray(s)
    #println("i: ",i)
    mask = strToIntArray("ICECOLDKILLER")
    tmp = xorMask(i, mask)
    tmp = xorMask(i, mask)
    @time begin
        scoreText(tmp)
    end
    #println(join([@sprintf("%x",x) for x in i]))
end
