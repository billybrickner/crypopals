#! /usr/bin/env julia

using CSV: CSV, File
using DataFrames: DataFrame
using Base64: base64decode
using BenchmarkTools

function strToIntArray(s)
    return Int16[Int16(c) for c in s]
end

function prettyPrint(s)
    if typeof(s) == String
        println([Char(char) for char in convertHex(s)])
    elseif typeof(s) == Array{Int16,1}
        println(join(map(Char, s)))
    else
        println("Unreckognized Type:",typeof(s))
    end
end

function xorMask(cipher, mask)
    if length(mask) == 1
        return Int16[char ⊻ mask[1] for char in cipher]
    end
    text = Int16[character for character in cipher]
    # BUGFIX: Start at 0 to account for i + j starting at 1
    for i in range(0,step=length(mask),stop=length(text)-1)
        for (j, maskByte) in enumerate(mask)
            if length(text) >= i + j
                #println("I+J:",i+j)
                @inbounds text[i+j] ⊻= maskByte
            end
        end
    end
    return text
end

function getLetterFrequency()
    df = DataFrame(CSV.File("../../common/frequency.csv"))
    df = Matrix{Union{Float64,String}}(df)
    characterToFrequency = Dict{Int16,Float64}()
    for i in 1:size(df)[1]
        characterToFrequency[Int16(df[i,1][1])] = df[i,2]
    end

    return characterToFrequency
end

function scoreText(text)
    score = 0
    for character in text
        score += get(characterToFrequency, character, 0.0)
    end
    return score
end

function editDistance(block1, block2)
    total = 0
    @simd for i in 1:length(block1)
        @inbounds total += count_ones(block1[i] ⊻ block2[i])
    end
    return total
end

const global characterToFrequency = getLetterFrequency()
function main()
    println("Staring Code!")
    @time begin
        open("cipher.txt") do f
            s = ""
            while ! eof(f)
                s = string(s, readline(f))
            end
            encoded = base64decode(s)

            # Block Size
            minEdit = 100
            minBlockSize = 0
            minEditList = []
            for i in 2:40
                numSamples = 7
                block1 = encoded[1:numSamples*i]
                block2 = encoded[1 + numSamples*i:2*numSamples*i]
                edit = editDistance(block1, block2)/(i*numSamples)
                if edit < 1.05*minEdit
                    #println(i, " ", edit)
                    push!(minEditList,[edit,i])
                end
                if edit < minEdit
                    minEdit = edit
                    minBlockSize = i
                end
            end
            topGuesses = sort(minEditList)[1:5]
            println("Top Guesses for Block Size")
            for (score, blocksize) in topGuesses
                println("Score: ",score," BlockSize: ",Int16(blocksize))
            end

            # Find Key
            key = Int16[]
            decoded = Int16[]
            maxGuess = 0
            for (_, guess) in topGuesses
                guess = Int16(guess)
                println("Guess ",guess)
                keyGuess = Int16[0 for i in 1:guess]
                for i in 1:guess
                    charBlock = [i+(j)*guess for j in 0:40]
                    maxScore = 0
                    maxChar = 0
                    for char in 0:255
                        tmp = [encoded[c] for c in charBlock]
                        score = scoreText(xorMask(tmp, [char]))
                        if score > maxScore
                            maxScore = score
                            maxChar = char
                        end
                    end
                    keyGuess[i] = maxChar
                end
                decodedGuess = xorMask(encoded,keyGuess)
                guessScore = scoreText(decodedGuess)
                if guessScore > maxGuess
                    maxGuess = guessScore
                    decoded = decodedGuess
                    key = keyGuess
                end
            end
            print("Key: ")
            prettyPrint(key)
            println("Decrypted: ")
            prettyPrint(decoded)
        end
    end
end

main()
