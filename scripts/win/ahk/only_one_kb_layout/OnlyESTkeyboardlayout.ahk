Loop {
et := DllCall("LoadKeyboardLayout", "Str", "00000425", "Int", 1)
en := DllCall("LoadKeyboardLayout", "Str", "00000409", "Int", 1)


w := DllCall("GetForegroundWindow")
pid := DllCall("GetWindowThreadProcessId", "UInt", w, "Ptr", 0)
l := DllCall("GetKeyboardLayout", "UInt", pid)
if (l = en)
{
    PostMessage 0x50, 0, %et%,, A
}
else
{
    PostMessage 0x50, 0, %et%,, A
}
Sleep, 5000
}