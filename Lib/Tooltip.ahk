#requires AutoHotkey v1.1

class Tooltip
{
  static WINAPI :=
  (join
    {
      WS_EX_TOPMOST: 0x8,
      TOOLTIPS_CLASS: "tooltips_class32",

      TTDT_RESHOW: 0x1,
      TTDT_AUTOPOP: 0x2,
      TTDT_INITIAL: 0x3,

      TTF_IDISHWND: 0x1,
      TTF_SUBCLASS: 0x10, 

      TTI_NONE: 0x0,
      TTI_INFO: 0x1,
      TTI_WARNING: 0x2,
      TTI_ERROR: 0x3,
      
      TTM_SETDELAYTIME: 0x403,
      TTM_SETMAXTIPWIDTH: 0x418,
      TTM_SETTITLEW: 0x421,
      TTM_ADDTOOLW: 0x432,
      TTM_UPDATETIPTEXTW: 0x439,

      TTS_ALWAYSTIP: 0x1,
      TTS_NOFADE: 0x20,

      CW_USEDEFAULT: 0x80000000,
      HWND_DESKTOP: 0x0,

      WM_SETFONT: 0x0030, 
      WM_GETFONT: 0x0031
    }
  )

  class IconType
  {
    static  None := Tooltip.WINAPI.TTI_NONE
          , Info := Tooltip.WINAPI.TTI_INFO
          , Warning := Tooltip.WINAPI.TTI_WARNING
          , Error := Tooltip.WINAPI.TTI_ERROR
  }

  __New(hAssociatedControl)
  {
    static WINAPI := Tooltip.WINAPI

    this.TOOLINFO := ""
    this.hAssociatedControl := hAssociatedControl

    this.handle := dllcall("CreateWindowEx"
        , int, WINAPI.WS_EX_TOPMOST   ; dwExStyle
        , str, WINAPI.TOOLTIPS_CLASS  ; lpClassName
        , ptr, 0                      ; lpWindowName
        , int, WINAPI.TTS_ALWAYSTIP 
            | WINAPI.TTS_NOFADE       ; dwStyle
        , int, WINAPI.CW_USEDEFAULT   ; X
        , int, WINAPI.CW_USEDEFAULT   ; Y
        , int, WINAPI.CW_USEDEFAULT   ; nWidth
        , int, WINAPI.CW_USEDEFAULT   ; nHeight
        , ptr, WINAPI.HWND_DESKTOP    ; hWndParent
        , ptr, 0                      ; hMenu
        , ptr, 0                      ; hInstance
        , ptr, 0                      ; lpParam
        , ptr)

    oldHiddenWindowsSetting := A_DetectHiddenWindows
    detecthiddenWindows, on

    this.__SetMaxWidth(400)
    this.__SetDisplayAttributes()
    this.__SetText("")
    this.__SetFontSize(UiPath.Studio.Toolkit.GlobalFontSize)
    
    ; Associate a blank tooltip with the control
    sendmessage, WINAPI.TTM_ADDTOOLW, 0, this.GetAddress("TOOLINFO"), , % "ahk_id " this.handle
    
    detecthiddenwindows % oldHiddenWindowsSetting
  }

  __Delete()
  {
    dllcall("DestroyWindow", ptr, this.handle)
  }


  ; =====================================
  ; PUBLIC INTERFACE FOR UPDATING TOOLTIP CONTENTS
  ; =====================================

  Update(text, title, iconType := "")
  {
    static WINAPI := Tooltip.WINAPI

    if (!this.handle)
    {
      throw Exception("Tooltip not yet instantiated: "
          . "call a class constructor first", -2)
    }

    if (iconType == "")
    {
      iconType := this.base.IconType.None
    }

    oldHiddenWindows := a_detecthiddenwindows
    detecthiddenwindows, on

    this.__SetTitle(title, iconType)

    this.__SetText(text)
    sendmessage, WINAPI.TTM_UPDATETIPTEXTW, 0, this.GetAddress("TOOLINFO"), 
        , % "ahk_id " this.handle

    detecthiddenwindows % oldHiddenWindows
  }


  ; =====================================
  ; TOOLTIP PROPERTY METHODS
  ; =====================================
  
  __SetMaxWidth(maxWidth)
  {
    static WINAPI := Tooltip.WINAPI

    ; SendMessage, WINAPI.TTM_SETMAXTIPWIDTH, 0, A_ScreenWidth*96 // A_ScreenDPI, , % "ahk_id " this.handle
    sendmessage, WINAPI.TTM_SETMAXTIPWIDTH, 0, maxWidth * 96 // a_screendpi, 
        , % "ahk_id " this.handle
  }

  __SetDisplayAttributes()
  {
    static WINAPI := Tooltip.WINAPI
    static maxRemainVisibleMs := 2**15 - 1

    ; Set initial display-after-hover milliseconds
    sendmessage, WINAPI.TTM_SETDELAYTIME, WINAPI.TTDT_INITIAL, 0, , % "ahk_id " this.handle
    
    ; Set display duration
    sendmessage, WINAPI.TTM_SETDELAYTIME, WINAPI.TTDT_AUTOPOP, maxRemainVisibleMs
        , , % "ahk_id " this.handle
    
    ; Set reshow duration when moving from one tool to anothers
    sendmessage, WINAPI.TTM_SETDELAYTIME, WINAPI.TTDT_RESHOW, 0, , % "ahk_id " this.handle
  }
  
  __SetFontSize(size)
  {
    static WINAPI := Tooltip.WINAPI

    ; Create a temp GUI with a text control having a requested font 
    ; size to copy a handle to the font from
    defaultGui := a_defaultgui
    gui, new
    gui, font, % "s" size
    gui, add, text, hwndhText, DummyText
    sendmessage, WINAPI.WM_GETFONT, 0, 0, , % "ahk_id " hText
    hFont := errorlevel
    ; hFont := dllcall("SendMessage", "Ptr", hText, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
    gui, destroy
    gui, % defaultGui ":default"
    postmessage, WINAPI.WM_SETFONT, hFont, true, , % "ahk_id " this.handle
    ; DllCall("SendMessage", "Ptr", CtrlHwnd, "UInt", WM_SETFONT, "Ptr", hFont, "Ptr", true)
  }

  __SetText(byref text)
  {
    static sizeof_TOOLINFO := 72
    static WINAPI := Tooltip.WINAPI

    if (this.TOOLINFO == "")
    {
      ; Assign fixed TOOLINFO members

      ; NOTE: TTF_SUBCLASS is a MUST flag to have; otherwise no tooltip will be displayed
      tooltipDisplayFlags := WINAPI.TTF_IDISHWND | WINAPI.TTF_SUBCLASS

      this.SetCapacity("TOOLINFO", sizeof_TOOLINFO)
  
      numput(sizeOf_TOOLINFO,         this.GetAddress("TOOLINFO"),  0, "uint") ; cbSize
      numput(tooltipDisplayFlags,     this.GetAddress("TOOLINFO"),  4, "uint") ; uFlags
      numput(WINAPI.HWND_DESKTOP,     this.GetAddress("TOOLINFO"),  8, "uptr") ; hwnd
      numput(0,                       this.GetAddress("TOOLINFO"), 24, "uptr") ; rect 1/2
      numput(this.hAssociatedControl, this.GetAddress("TOOLINFO"), 16, "uptr") ; uId
      numput(0,                       this.GetAddress("TOOLINFO"), 32, "uptr") ; rect 2/2
      numput(0,                       this.GetAddress("TOOLINFO"), 40, "uptr") ; hinst
      numput(0,                       this.GetAddress("TOOLINFO"), 56, "uptr") ; lparam
      numput(0,                       this.GetAddress("TOOLINFO"), 64, "uptr") ; lpReserved
    }

    numput(&text,                     this.GetAddress("TOOLINFO"), 48, "uptr") ; lpszText
  }

  __SetTitle(title, iconType)
  {
    static WINAPI := Tooltip.WINAPI

    sendmessage, WINAPI.TTM_SETTITLEW, iconType, &title, , % "ahk_id " this.handle
  }
}