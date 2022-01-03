using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()

headers = ["./rtmidi/rtmidi_c.h"]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

# create context
ctx = create_context(headers, String[], options)

# run generator
build!(ctx)