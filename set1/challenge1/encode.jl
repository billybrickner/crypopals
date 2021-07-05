open("cypher.txt") do f
    while ! eof(f)
        s = readline(f)
        for i in range(1,step=2,stop=length(s))
            convert = s[i:i+1]
            print(Char(parse(Int, convert, base=16)))
        end
    end
end
