using RTMidi
using Test

@testset "RTMidi.jl" begin
    mi = MidiIn("RTMidi")
    mo = MidiOut("RTMidi")
end
