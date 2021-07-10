#! /usr/bin/env julia

using CSV
using DataFrames

function convertHex(s)
    hex_array = [parse(Int, s[i:i+1], base=16) for i in range(1,step=2,stop=length(s))]
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

function xorMask(cipher, mask)
    maskLength = length(mask)
    text = [character for character in cipher]
    # BUGFIX: Start at 0 to account for i + j starting at 1
    for i in range(0,step=maskLength,stop=length(text))
        for (j, maskByte) in enumerate(mask)
            if length(text) >= i + j
                #println("I+J:",i+j)
                @inbounds text[i+j] ⊻= mask[j]
            end
        end
    end
    return text
end

function getLetterFrequency()
    df = DataFrame(CSV.File("../../common/frequency.csv"))
    df = Matrix{Union{Float64,String}}(df)
    characterToFrequency = Dict{Int,Float64}()
    for i in 1:size(df)[1]
        characterToFrequency[Int(df[i,1][1])] = df[i,2]
    end

    return characterToFrequency
end

characterToFrequency = getLetterFrequency()
function scoreText(text)
    score = 0
    for character in text
        score += get(characterToFrequency, character, 0.0)
    end
    return score
end

open("cipher.txt") do f
    maxScore = 0
    maxMask = 'a'
    maxText = []
    l = []
    # Get Cipher Text
    while ! eof(f)
        s1 = readline(f)
        #println(s1)
        l1 = convertHex(s1)
        push!(l,l1)
    end
    @time begin
        for l1 in l
            for mask in 0:(1<<15 - 1)
                decoded = xorMask(l1,[Int(mask)])
                score = scoreText(decoded)
                if maxScore < score
                    maxScore = score
                    maxMask = mask
                    maxText = [c for c in l1]
                    println(maxMask, " ", maxScore)
                end
            end
        end
        # Use best match
        decoded = xorMask(maxText,[Int(maxMask)])
        print(Char(maxMask), " ", maxScore, ": ")
        prettyPrint(decoded)
    end
end

open("cipher.txt") do f
    # Get Cipher Text
    maxScore = 0
    maxMask = 'a'
    maxText = []
    l = []
    # Loop through strings
    while ! eof(f)
        s1 = readline(f)
        #println(s1)
        l1 = convertHex(s1)
        push!(l,l1)
    end
    @time begin
        Threads.@threads for l1 in l
            # Loop Through Letters
            for mask in 0:(1<<15 - 1)
                decoded = xorMask(l1,[Int(mask)])
                score = scoreText(decoded)
                if maxScore < score
                    maxScore = score
                    maxMask = mask
                    maxText = Int[c for c in l1]
                    println(maxMask, " ", maxScore)
                end
            end
        end
        # Use best match
        decoded = xorMask(maxText,[Int(maxMask)])
        print(Char(maxMask), " ", maxScore, ": ")
        prettyPrint(decoded)
    end
end
