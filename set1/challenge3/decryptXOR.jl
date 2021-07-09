#! /usr/bin/env julia

using CSV: CSV, File
using DataFrames: DataFrame
using DataStructures: DefaultDict

function convertHex(s)
    hex_array = Int[parse(Int, s[i:i+1], base=16) for i in range(1,step=2,stop=length(s))]
end

function prettyPrint(s)
    if typeof(s) == String
        println(map.(Char, convertHex(s), 16))
    elseif typeof(s) == Array{Int64,1}
        println(join(map.(Char, s)))
    end
end

function xorMask(cipher, mask)
    maskLength = length(mask)
    text = Int[character for character in cipher]
    text .= text .⊻ mask[mod1.(1:length(text),length(mask))]
    return text
end

function getLetterFrequency()
    df = DataFrame(CSV.File("../../common/frequency.csv"))
    df = Matrix{Union{Float64,String}}(df)
    characterToFrequency = DefaultDict{Int,Float64}(0.0)
    for i in 1:size(df)[1]
        characterToFrequency[Int(df[i,1][1])] = df[i,2]
    end

    return characterToFrequency
end

characterToFrequency = getLetterFrequency()
function scoreText(text)
    getFreq(x) = characterToFrequency[x]
    return sum(map.(getFreq, text))
end

println("Starting Code")
open("cipher.txt") do f
    # Get Cipher Text
    s1 = readline(f)
    l1 = convertHex(s1)
    maxScore = 0
    maxMask = 'a'
    # Loop Through Letters
    for i in 0:25
        for mask in ['a' + i, 'A' + i]
            decoded = xorMask(l1,[Int(mask)])
            score = scoreText(decoded)
            if maxScore < score
                maxScore = score
                maxMask = mask
            end
        end
    end
    # Use best match
    decoded = xorMask(l1,[Int(maxMask)])
    print(maxMask, " ", maxScore, ": ")
    prettyPrint(decoded)
end
