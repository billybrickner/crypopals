#! /usr/bin/env julia

using CUDA
using CSV: CSV, File
using DataFrames: DataFrame
using DataStructures: DefaultDict
using .Threads
using BenchmarkTools

function convertHex(s)
    hex_array = [parse(Int64, s[i:i+1], base=16) for i in range(1,step=2,stop=length(s))]
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
    characterToFrequency = DefaultDict{Int,Float64}(0.0)
    for i in 1:size(df)[1]
        characterToFrequency[Int(df[i,1][1])] = df[i,2]
    end

    return characterToFrequency
end

characterToFrequency = getLetterFrequency()
function scoreText(text)
    score = 0
    for character in text
        @inbounds score += get(characterToFrequency, character, 0.0)
    end
    return score
end

MAX_MASK = (1<<15 - 1)
MAX_CHAR = Int('z')

function straightRun()
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
        for l1 in l
            for mask in 0:MAX_MASK
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

function threadedRun()
    open("cipher.txt") do f
        # Get Cipher Text
        maxScore = 0
        maxMask = 'a'
        maxText = []
        l = []
        lk = ReentrantLock()
        # Loop through strings
        while ! eof(f)
            s1 = readline(f)
            #println(s1)
            l1 = convertHex(s1)
            push!(l,l1)
        end
        Threads.@threads for l1 in l
            # Loop Through Letters
            for mask in 0:MAX_MASK
                decoded = xorMask(l1,[Int64(mask)])
                score = scoreText(decoded)
                if maxScore < score
                lock(lk) do
                    if maxScore < score
                        maxScore = score
                        maxMask = mask
                        maxText = Int[c for c in l1]
                        println(maxMask, " ", maxScore)
                    end
                end
                end
            end
        end
        # Use best match
        decoded = xorMask(maxText,[Int(maxMask)])
        print(Char(maxMask), " ", maxScore, ": ")
        prettyPrint(decoded)
    end
end

function gpu_kernel_solve(l1, cuLetters, cuScores)
    for i = 1:length(cuScores)
        mask = i - 1
        score = 0
        size = length(cuLetters)
        for j = 1:length(l1)
            character = (l1[j] ⊻ mask)
            characterIndex = character + 1
            if character < size
                @inbounds score += cuLetters[characterIndex]
            end
        end
        @inbounds cuScores[i] = score
    end
    return nothing
end

function gpuRun()
    open("cipher.txt") do f
        # Get Cipher Text
        maxScore = 0
        maxMask = 'a'
        maxText = []
        l = []
        cuLetters = CuArray{UInt16,1}([UInt16(round(10*get(characterToFrequency,i, 0.0))) for i in 0:MAX_CHAR])
        lk = ReentrantLock()
        # Loop through strings
        while ! eof(f)
            s1 = readline(f)
            #println(s1)
            l1 = convertHex(s1)
            push!(l,l1)
        end
        Threads.@threads for l1 in l
            cuL1 = CuArray{UInt16, 1}(l1)
            cuScores = CuArray{UInt32,1}([0 for i in 0:MAX_MASK])
            # Loop Through Letters: Scoring
            @cuda gpu_kernel_solve(cuL1, cuLetters, cuScores)
            score, maskIndex = findmax(cuScores)
            if score > maxScore
                lock(lk) do
                    if score > maxScore
                        mask = maskIndex - 1
                        maxScore = score
                        maxMask = mask
                        maxText = l1
                        println(maxMask, " ", maxScore)
                    end
                end
            end
        end
        # Use best match
        decoded = xorMask(maxText,[Int(maxMask)])
        print(Char(maxMask), " ", maxScore, ": ")
        prettyPrint(decoded)
    end
end

@btime straightRun()

@btime threadedRun()

@btime gpuRun()
