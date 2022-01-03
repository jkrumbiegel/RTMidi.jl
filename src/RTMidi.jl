module RTMidi

using rtmidi_jll
using CEnum
using MIDI

include("api.jl")

export MidiOut, MidiIn, port_count, open_virtual_port!, listen!, stop_listening!

mutable struct MidiOut
    name::String
    ptr::Ptr{RtMidiWrapper}
    function MidiOut(name, api::RtMidiApi = RTMIDI_API_UNSPECIFIED)
        name = convert(String, name)
        ptr = rtmidi_out_create(api, name)
        midiout = new(name, ptr)
        finalizer(midiout) do m
            rtmidi_out_free(m.ptr)
        end
        midiout
    end
end

mutable struct MidiIn
    name::String
    ptr::Ptr{RtMidiWrapper}
    timer::Union{Nothing, Timer}
    function MidiIn(name, api::RtMidiApi = RTMIDI_API_UNSPECIFIED; queue_size_limit = 1024)
        name = convert(String, name)
        ptr = rtmidi_in_create(api, name, queue_size_limit)
        midiin = new(name, ptr, nothing)
        finalizer(midiin) do m
            rtmidi_out_free(m.ptr)
        end
        midiin
    end
end

function _check_status(m)
    wrapper = unsafe_load(m.ptr)
    if wrapper.ok == 0
        msg = unsafe_string(wrapper.msg)
        error(msg)
    end
    nothing
end

function port_count(m)::Int
    count = rtmidi_get_port_count(m.ptr)
    _check_status(m)
    count
end

function open_virtual_port!(m, name)
    rtmidi_open_virtual_port(m.ptr, name)
    _check_status(m)
    nothing
end

function listen!(callback, mi::MidiIn; interval_seconds = 0.001)
    if mi.timer !== nothing
        error("MidiIn is already listening.")
    end

    bufferlength = 1024
    vector = zeros(UInt8, bufferlength) # 1024 is maximal SYSEX size
    sz = Ref{Cint}()
    laststatus = 0x00 # is this correct?

    mi.timer = Timer(0, interval = interval_seconds) do timer
        sz[] = bufferlength
        deltatime = RTMidi.rtmidi_in_get_message(mi.ptr, vector, sz)
        sz[] == 0 && return
        event = MIDI.readMIDIevent(0, IOBuffer(vector), laststatus)
        laststatus = event.status
        callback(event)
    end
    return
end

function stop_listening!(mi::MidiIn)
    mi.timer === nothing && return
    close(mi.timer)
    mi.timer = nothing
    return
end

####################

end