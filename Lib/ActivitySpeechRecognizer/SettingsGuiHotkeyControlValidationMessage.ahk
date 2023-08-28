static validationMessage :=
(join c
  {
    ok:
    {
      title: "Hotkey has been assigned",
      text: "The hotkey ""{1}"" successfully set."
    },
    error:
    {
      hotkeyAlreadyInUse:
      {
        title: "Hotkey already in use",
        text: "Hotkey ""{1}"" is already assigned for another purpose: {2}."
      },
      invalidHotkey:
      {
        title: "Invalid hotkey",
        text: "Hotkey ""{1}"" is invalid/unsupported."
      },
      hotkeyNotAssigned:
      {
        title: "Unset hotkey",
        text: "A hotkey to activate listening to incoming audio has not yet been assigned."
      }
    }
  }
)