NeP.FSH = {
	Version = 1.3
}

-- Core version check
if NeP.Info.Version >= 70.1 then
    NeP.Core.Print('Loaded Fishing Module v:'..NeP.FSH.Version)
else
    NeP.Core.Print('Failed to Fishing Module.\nYour Core is outdated.')
    return
end

Types = {
    Bool = "bool",
    Char = "char",
    Byte = "byte",
    SByte = "char",
    UByte = "byte",
    Short = "short",
    SShort = "short",
    UShort = "ushort",
    Int = "int",
    SInt = "int",
    UInt = "uint",
    Long = "long",
    SLong = "long",
    ULong = "ulong",
    Float = "float",
    Double = "double",
    String = "string",
    GUID = "guid",
};