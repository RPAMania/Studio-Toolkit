#requires AutoHotkey v1.1

class SAPI
{
  class SpVoice
  {
    static SpVoiceStatic := comobjcreate("SAPI.SpVoice")
    static SpeechVoiceSpeakFlags := { SVSFDefault: 0, SVSFlagsAsync: 1 }

    static Subscription := { StartStream: "StartStream", EndStream: "EndStream" }

    static VolumeLimit := { Min: 0, Max: 100 }
    static Instances := {}

    __New()
    {
      this.instance := comobjcreate("SAPI.SpVoice")
      this.instance.Rate := 1
      
      this.base.Instances[&this.instance] := &this  
      comobjconnect(this.instance, "SAPI_")

      this.subscribers := { (this.base.Subscription.StartStream): []
          , (this.base.Subscription.EndStream): [] }
    }


    ; =====================================
    ; SAPI SPEECH COM OBJECT MANAGEMENT
    ; =====================================

    GetVoices()
    {
      static WINAPI :=
      (join c
        {
          ; LOCALE_SENGLISHDISPLAYNAME: 0x72, ; English (Great Britain)
          LOCALE_SNAME: 0x5C, ; locale name (ie: en-GB)
          ; LOCALE_SENGLISHLANGUAGENAME: 0x1001, ; English
          ; LOCALE_SENGLISHCOUNTRYNAME: 0x1002, ; Great Britain
          SORT_DEFAULT: 0x0, 
          LANG_NAME_MAX_LENGTH: 80
        }
      )

      result := []

      voices := this.SpVoiceStatic.GetVoices()

      loop % voices.Count()
      {
        voice := voices.Item(a_index - 1)

        ; Available attributes: "Gender", "Age", "Name", "Language", "Vendor"

        name := voice.GetAttribute("Name")
        languageId := "0x" voice.GetAttribute("Language")
        languageId += 0

        varsetcapacity(language, WINAPI.LANG_NAME_MAX_LENGTH * 2, 0)
        dllcall("GetLocaleInfo"
            , int, (WINAPI.SORT_DEFAULT << 16) | languageId ; (srtid << 16) | lgid
            , int, WINAPI.LOCALE_SNAME
            , str, language
            , int, WINAPI.LANG_NAME_MAX_LENGTH)

        result.Push({ id: voice.Id, name: name, language: language, spObjectToken: voice })
      }

      return result
    }

    GetVoicesString(separator, attributes, attributeSeparator := "")
    {
      voicesString := ""

      voices := this.GetVoices()
      for k, voice in voices
      {
        if (strlen(voicesString))
        {
          voicesString .= separator
        }
        
        attributesString := ""
        for k, attribute in attributes
        {
          if (strlen(attributesString))
          {
            attributesString .= attributeSeparator
          }

          attributesString .= voice[attribute]
        }
        
        voicesString .= attributesString
      }

      return voicesString
    }

    SetVoice(spObjectToken)
    {
      this.instance.Voice := spObjectToken
    }

    Speak(message, flags := "")
    {
      if (flags == "")
      {
        flags := this.base.SpeechVoiceSpeakFlags.SVSFlagsAsync
      }
      
      this.instance.Speak(message, flags)
    }
    
    Volume[]
    {
      get
      {
        return this.instance.Volume
      }
      set
      {
        if (value < this.base.VolumeLimit.Min)
        {
          value := this.base.VolumeLimit.Min
        }
        else if (value > this.base.VolumeLimit.Max)
        {
          value := this.base.VolumeLimit.Max
        }

        this.instance.Volume := value
      }
    }

    ; =====================================
    ; EVENT SUBSCRIPTION MANAGEMENT
    ; =====================================

    Subscribe(eventType, subscriberId, callback)
    {
      this.__ValidateEventType(eventType)

      if (!this.__SubscriberExists(subscriberId, eventType))
      {
        this.subscribers[eventType].Push({ id: subscriberId, fn: callback })
      }
    }

    Unsubscribe(eventType, subscriberId)
    {
      this.__ValidateEventType(eventType)

      for idx, subscriber in subscribers[eventType]
      {
        if (subscriber.id == subscriberId)
        {
          subscribers.RemoveAt(idx)
          break
        }
      }
    }

    __ValidateEventType(eventType)
    {
      switch (eventType)
      {
        case this.base.Subscription.StartStream:
        case this.base.Subscription.EndStream:
        default: throw Exception(format("Undefined SpVoice event type ""{}""", eventType), -3)
      }
    }

    __SubscriberExists(id, eventType)
    {
      for idx, subscriber in this.subscribers[eventType]
      {
        if (subscriber.id == id)
        {
          return true
        }
      }

      return false
    }
  }
}


; =====================================
; SAPI SPEECH COM OBJECT EVENT HANDLERS
; =====================================

SAPI_StartStream(streamNumber, streamPosition, spVoiceComObject)
{
  voiceInstance := Object(SAPI.SpVoice.Instances[&spVoiceComObject])

  for idx, subscriber in voiceInstance.subscribers[voiceInstance.base.Subscription.StartStream]
  {
    subscriber.fn.Call()
  }
}

SAPI_EndStream(streamNumber, streamPosition, spVoiceComObject)
{
  voiceInstance := Object(SAPI.SpVoice.Instances[&spVoiceComObject])

  for idx, subscriber in voiceInstance.subscribers[voiceInstance.base.Subscription.EndStream]
  {
    subscriber.fn.Call()
  }
}