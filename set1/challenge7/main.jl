#! /usr/bin/env julia

using Pkg
Pkg.activate(joinpath(@__DIR__, "../.."))
Pkg.add(url="https://github.com/faf0/AES.jl")

using AES
using Base64: base64decode

function prettyPrint(s)
    if typeof(s) == String
        println([Char(char) for char in convertHex(s)])
    elseif typeof(s) == Array{UInt8,1}
        println(join(map(Char, s)))
    else
        println("Unreckognized Type:",typeof(s))
    end
end

# AES Block
key_s = "YELLOW SUBMARINE"
key = UInt8[UInt8(c) for c in key_s]

println("Loading Message Text")
open("cipher.txt") do f
   s = ""
   while ! eof(f)
      s = string(s,readline(f))
   end
   encoded = base64decode(s)
   l = length(encoded)
   println(typeof(encoded))
   decoded = AESECB(encoded,key,false)
   prettyPrint(decoded[1:l])
end

