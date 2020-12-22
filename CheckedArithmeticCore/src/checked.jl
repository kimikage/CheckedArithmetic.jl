module Checked

using Base.Checked

export checked_fdiv

# re-export
for name in names(Base.Checked)
    @eval export $name
end

end # module
