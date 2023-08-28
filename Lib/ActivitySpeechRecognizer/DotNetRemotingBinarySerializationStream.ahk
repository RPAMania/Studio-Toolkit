class DotNetRemotingBinarySerializationStream
{
  /*
    [MS-NRBF]: .NET Remoting: Binary Format Data Structure
    @ https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nrbf/75b9fe09-be15-475f-85b8-ae7b7558cfe5
  */
  static TextHeaderBytesWithPlaceholders := ""
      /*
        DataObject Class
        @ https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.dataobject?view=net-5.0

        .NET source for System.WinForms.DataObject.cs
          // We use this to identify that a stream is actually a serialized object.  On read, 
          // we don't know if the contents of a stream were saved "raw" or if the stream is really
          // pointing to a serialized object. If we saved an object, we prefix it with this 
          // guid.
          //
          private static readonly byte[] serializedObjectID = new Guid("FD9EA796-3B13-4370-A679-56106BB288FB").ToByteArray();

        "Variant 2 UUIDs, historically used in Microsoft's COM/OLE libraries, use a mixed-endian format, 
        whereby the first three components of the UUID are little-endian, and the last two are big-endian"
        @ https://en.wikipedia.org/wiki/Universally_unique_identifier
      */
      . "96A79EFD" "133B" "7043" "A679" "56106BB288FB"

      /*
        Chapter 2.6.1 SerializationHeaderRecord
          "The SerializationHeaderRecord record MUST be the first record in a binary serialization. This record
          has the major and minor version of the format and the IDs of the top object and the headers."

          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. The value MUST be 0."

          "RootId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that identifies 
           the root of the graph of nodes.
            - If neither the BinaryMethodCall nor BinaryMethodReturn record is present in the serialization
               stream, the value of this field MUST contain the ObjectId of a Class, Array, or
               BinaryObjectString record contained in the serialization stream."

          "HeaderId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that identifies the
           Array that contains the header objects. The value of the field is set as follows:
            - If neither the BinaryMethodCall nor BinaryMethodReturn record is present in the serialization
              stream, the value of this field MUST contain the ObjectId of a Class, Array, or
              BinaryObjectString record that is contained in the serialization stream.

           NOTE: Docs probably have a mistake here - the value should be -1!

          "MajorVersion (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that identifies
           the major version of the format. The value of this field MUST be 1."

          "MinorVersion (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that identifies
           the minor version of the protocol. The value of this field MUST be 0."
      */
      . "00" ; SerializationHeaderRecord record type enum
        . "01000000" ; RootId == 1
        . "FFFFFFFF" ; HeaderId == -1
        . "01000000" ; MajorVersion == 1
        . "00000000" ; MinorVersion == 0
      /*
        Chapter 2.5.7 BinaryObjectString
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. 
           The value MUST be 6."

          "ObjectId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that uniquely
           identifies the string instance in the serialization stream. The value MUST be a positive integer.
           An implementation MAY use any algorithm to generate the unique IDs."

          "Value (variable): A LengthPrefixedString value"
      */
      . "06" ; BinaryStringObject record type enum
        . "01000000" ; ObjectId

      . "{1}" ; Activity text prefix length bytes
      . "{2}" ; Activity text bytes
      . "{3}" ; Terminator byte

  ; Terminator byte
  /*
    [MS-NRBF]: .NET Remoting: Binary Format Data Structure
    @ https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nrbf/75b9fe09-be15-475f-85b8-ae7b7558cfe5

    Chapter 2.6.3 MessageEnd

    Chapter 2.1.2.1 RecordTypeEnumeration
      "MessageEnd 11 - Identifies a MessageEnd record."
  */
  static TerminatorByte := "0B"

  /*
    [MS-NRBF]: .NET Remoting: Binary Format Data Structure
    @ https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nrbf/75b9fe09-be15-475f-85b8-ae7b7558cfe5
  */
  static TargetFrameworkBytes := ""
      . "96A79EFD" "133B" "7043" "A679" "56106BB288FB"

      . "00" ; SerializationHeaderRecord record type enum
        . "01000000" ; RootId == 1
        . "FFFFFFFF" ; HeaderId == -1
        . "01000000" ; MajorVersion == 1
        . "00000000" ; MinorVersion == 0
      /*
        Chapter 2.6.2 BinaryLibrary
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type.
           The value MUST be 12."

          "LibraryId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that uniquely
           identifies the Library name in the serialization stream. The value MUST be a positive integer.
           An implementation MAY use any algorithm to generate the unique IDs."

          "LibraryName (variable): A LengthPrefixedString value that represents the Library name. The format
           of the string is specified in [MS-NRTP] section 2.2.1.3."
      */
      . "0C" ; BinaryLibrary record type enum
        . "02000000" ; LibraryId
        . "49" ; LibraryName prefix length 0x49 => 73
        ; Library name == System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089
        . "53797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E6575"
        . "7472616C2C205075626C69634B6579546F6B656E3D62373761356335363139333465303839"

      /*
        Chapter 2.3.2.1 ClassWithMembersAndTypes
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. Its value MUST be 5."
        
          "ClassInfo (variable): A ClassInfo structure that provides information about the name and Members of the Class."

            Chapter 2.3.1.1 ClassInfo
              "ObjectId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that uniquely
               identifies the object in the serialization stream. An implementation MAY use any algorithm to 
               generate the unique IDs. If the ObjectId is referenced by a MemberReference record elsewhere in
               the serialization stream, the ObjectId MUST be positive. If the ObjectId is not referenced by any
               MemberReference in the serialization stream, then the ObjectId SHOULD be positive, but MAY be
               negative."

                Chapter 5 Appendix A
                  "<4> Section 2.3.1.1: Windows uses a single counter that counts from 1 to generate the ObjectId in
                   the ClassInfo, ArrayInfo, BinaryObjectString, and BinaryArray records, and the LibraryId in the
                   BinaryLibrary record. The maximum value is 2,147,483,647"

              "Name (variable): A LengthPrefixedString value that contains the name of the Class (1). The format
               of the string MUST be as specified in the RemotingTypeName, as specified in [MS-NRTP] section 2.2.1.2."

              "MemberCount (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that contains
               the number of Members in the Class (2). The value MUST be 0 or a positive integer."

              "MemberNames (variable): A sequence of LengthPrefixedString values that represents the names of
               the Members in the class (2). The number of items in the sequence MUST be equal to the value
               specified in the MemberCount field.
               The MemberNames MAY be in any order."

              "MemberTypeInfo (variable): A MemberTypeInfo structure that provides information about the 
               Remoting Types of the Members."

                Chapter 2.3.1.2 MemberTypeInfo
                  "BinaryTypeEnums (variable): A sequence of BinaryTypeEnumeration values that represents the
                   Member Types that are being transferred. The Array MUST:
                   - Have the same number of items as the MemberCount field of the ClassInfo structure.
                   - Be ordered such that the BinaryTypeEnumeration corresponds to the Member name in the
                     MemberNames field of the ClassInfo structure."

              "AdditionalInfos (variable): A sequence of additional information about a Remoting Type. For
               every value of the BinaryTypeEnum in the BinaryTypeEnums field that is a Primitive,
               SystemClass, Class (2), or PrimitiveArray, the AdditionalInfos field contains additional
               information about the Remoting Type. For the BinaryTypeEnum value of Primitive and
               PrimitiveArray, this field specifies the actual Primitive Type that uses the PrimitiveTypeEnum. For
               the BinaryTypeEnum value of SystemClass, this field specifies the name of the class (2). For the
               BinaryTypeEnum value of Class (2), this field specifies the name of the Class (2) and the Library
               ID. The following table enumerates additional information required for each BinaryType
               enumeration.
              
                SystemClass - String (Class (1) name as specified in [MS-NRTP] section 2.2.1.2)"

          "LibraryId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that references a
           BinaryLibrary record by its Library ID. A BinaryLibrary record with the LibraryId MUST appear
           earlier in the serialization stream."
      */
      . "05" ; ClassWithMembersAndTypes record type enum
        . "01000000" ; ClassInfo: ObjectId
        . "27" ; ClassInfo: Name prefix length == 39
          ; ClassInfo: Name == System.Runtime.Versioning.FrameworkName
        . "53797374656D2E52756E74696D652E56657273696F6E696E672E4672616D65776F726B4E616D65"
        . "04000000" ; ClassInfo: MemberCount == 4
        . "0C" ; ClassInfo: MemberName 1 prefix length == 12
        . "6D5F6964656E746966696572" ; ClassInfo: Member 1 name == m_identifier
        
        . "09" ;ClassInfo: MemberName 2 prefix length ==  9
        . "6D5F76657273696F6E" ; ClassInfo: Member 2 name == m_version

        . "09" ;ClassInfo: MemberName 3 prefix length ==  9
        . "6D5F70726F66696C65" ; ClassInfo: Member 3 name == m_profile

        . "0A" ; ClassInfo: MemberName 4 prefix length == 10
        . "6D5F66756C6C4E616D65" ; ClassInfo: Member 4 name == m_fullName
        . "01" ; MemberTypeInfo: Member 1 binary type enum == String (See 2.1.2.2 BinaryTypeEnumeration)
        . "03" ; MemberTypeInfo: Member 2 binary type enum == SystemClass (See 2.1.2.2 BinaryTypeEnumeration)
        . "01" ; MemberTypeInfo: Member 3 binary type enum == String (See 2.1.2.2 BinaryTypeEnumeration)
        . "01" ; MemberTypeInfo: Member 4 binary type enum == String (See 2.1.2.2 BinaryTypeEnumeration)
        . "0E" ; MemberTypeInfo: Member 2 additional info: Name length prefix == 14
        . "53797374656D2E56657273696F6E" ; MemberTypeInfo: Member 2 additional info: Name == System.Version
        . "02000000" ; LibraryId
      /*
        Chapter 2.5.7 BinaryObjectString
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. 
           The value MUST be 6."

          "ObjectId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that uniquely
          identifies the string instance in the serialization stream. The value MUST be a positive integer.
          An implementation MAY use any algorithm to generate the unique IDs."
        
          "Value (variable): A LengthPrefixedString value"
      */
      . "06" ; BinaryObjectString record type enum
        . "03000000" ; ObjectId
        . "0D" ; Length prefix == 13
        . "2E4E45544672616D65776F726B" ; String == .NETFramework
      /*
        Chapter 2.5.3 MemberReference
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. The value MUST be 9."

          "IdRef (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that is an ID of an object
           defined in another record.

           A Class, Array, or BinaryObjectString record MUST exist in the serialization stream with the
           value as its ObjectId. Unlike other ID references, there is no restriction on where the record
           that defines the ID appears in the serialization stream; that is, it MAY appear after the
           referencing record."
      */
      . "09" ; MemberReference record type enum
        . "04000000" ; IdRef
      /*
        Chapter 2.5.7 BinaryObjectString
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. 
           The value MUST be 6."

          "ObjectId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that uniquely
          identifies the string instance in the serialization stream. The value MUST be a positive integer.
          An implementation MAY use any algorithm to generate the unique IDs."
        
          "Value (variable): A LengthPrefixedString value"
      */
      . "06" ; BinaryObjectString record type enum
        . "05000000" ; ObjectId
        . "00" ; Length prefix == 0
        . "" ; String
      /*
        Chapter 2.5.4 ObjectNull
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type.
           The value MUST be 10."
      */
      . "0A" ; ObjectNull record type enum 
      /*
        Chapter 2.3.2.3 SystemClassWithMembersAndTypes
          "The SystemClassWithMembersAndTypes record is less verbose than ClassWithMembersAndTypes. It
           does not contain a LibraryId. This record implicitly specifies that the Class is in the System Library.
          
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type. Its value MUST be 4."

          "ClassInfo (variable): A ClassInfo structure that provides information about the name and Members of the Class."

            Chapter 2.3.1.1 ClassInfo

              "ObjectId (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that uniquely
               identifies the object in the serialization stream. An implementation MAY use any algorithm to
               generate the unique IDs. If the ObjectId is referenced by a MemberReference record elsewhere in
               the serialization stream, the ObjectId MUST be positive. If the ObjectId is not referenced by any
               MemberReference in the serialization stream, then the ObjectId SHOULD be positive, but MAY be
               negative."

              "Name (variable): A LengthPrefixedString value that contains the name of the Class (1). The format
               of the string MUST be as specified in the RemotingTypeName, as specified in [MS-NRTP] section 2.2.1.2."

              "MemberCount (4 bytes): An INT32 value (as specified in [MS-DTYP] section 2.2.22) that contains
               the number of Members in the Class (2). The value MUST be 0 or a positive integer."

              "MemberNames (variable): A sequence of LengthPrefixedString values that represents the names of
               the Members in the class (2). The number of items in the sequence MUST be equal to the value
               specified in the MemberCount field.
               The MemberNames MAY be in any order."

          "MemberTypeInfo (variable): A MemberTypeInfo structure that provides information about the
           Remoting Type of the Members."

            Chapter 2.3.1.2 MemberTypeInfo

              "BinaryTypeEnums (variable): A sequence of BinaryTypeEnumeration values that represents the
               Member Types that are being transferred. The Array MUST:
                - Have the same number of items as the MemberCount field of the ClassInfo structure.
                - Be ordered such that the BinaryTypeEnumeration corresponds to the Member name in the
                  MemberNames field of the ClassInfo structure."
      */
      . "04" ; SystemClassWithMembersAndTypes record type enum
        . "04000000" ; ClassInfo: ObjectId
        . "0E" ; ClassInfo: Name length prefix == 14
        . "53797374656D2E56657273696F6E" ; ClassInfo: Name == System.Version
        . "04000000" ; ClassInfo: MemberCount == 4
        . "06" ; ClassInfo: MemberName 1: Name length prefix == 6
        . "5F4D616A6F72" ; ClassInfo: MemberName 1: Name == _Major
        . "06" ; ClassInfo: MemberName 2: Name length prefix == 6
        . "5F4D696E6F72" ; ClassInfo: MemberName 2: Name == _Minor
        . "06" ; ClassInfo: MemberName 3: Name length prefix == 6
        . "5F4275696C64" ; ClassInfo: MemberName 3: Name == _Build
        . "09" ; ClassInfo: MemberName 4: Name length prefix == 9
        . "5F5265766973696F6E" ; ClassInfo: MemberName 4: Name == _Revision
        . "00" ; MemberTypeInfo: Member 1: Type 0 == Primitive
        . "00" ; MemberTypeInfo: Member 2: Type 0 == Primitive
        . "00" ; MemberTypeInfo: Member 3: Type 0 == Primitive
        . "00" ; MemberTypeInfo: Member 4: Type 0 == Primitive
        . "08" ; MemberTypeInfo: Member 1: Type 8 == Int32 (see 2.1.2.3 PrimitiveTypeEnumeration)
        . "08" ; MemberTypeInfo: Member 2: Type 8 == Int32 (see 2.1.2.3 PrimitiveTypeEnumeration)
        . "08" ; MemberTypeInfo: Member 3: Type 8 == Int32 (see 2.1.2.3 PrimitiveTypeEnumeration)
        . "08" ; MemberTypeInfo: Member 4: Type 8 == Int32 (see 2.1.2.3 PrimitiveTypeEnumeration)
      /*
      */
      . "04000000" ; ?
      . "05000000" ; ?
      . "FFFFFFFFFFFFFFFF" ; ?
      /*
        Chapter 2.6.3 MessageEnd
          "RecordTypeEnum (1 byte): A RecordTypeEnumeration value that identifies the record type.
           The value MUST be 11."
      */
      . "{1}" ; Terminator byte

  /*
    [MS-NRBF]: .NET Remoting: Binary Format Data Structure
    @ https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nrbf/75b9fe09-be15-475f-85b8-ae7b7558cfe5
    
    Chapter 2.1.1.6 LengthPrefixedString describes how to form the length component.
  */
  __GetLengthPrefixedStringLengthBytes(xamlText)
  {
    LogMethod(a_thisfunc)

    textLength := strlen(xamlText)
    
    lengthPrefixedStringLength := textLength

    loop
    {
      ; The most significant bit is reserved for span flag. The bit will 
      ; incidate whether the length value continues in the next octet.

      ; Therefore, check if the length value requires the 8th bit of the
      ; currently iterated octet to be reserved for span flag.
      shouldSpanLengthToNextOctetBitValue := 1 << ((a_index - 1) * 8 + 7)

      if (lengthPrefixedStringLength >= shouldSpanLengthToNextOctetBitValue)
      {
        ; 8th octet bit should be reserved for span flag. More significant
        ; bits in the original length value must be shifted out of the way.

        lengthCopy := lengthPrefixedStringLength

        ; Discard all bits starting from the 7 least significant bits of the 
        ; currently iterated octet by bit-shifting right
        ; F.ex. 11011000 11011000 becomes
        ;       00000001 10110001
        lengthCopy := lengthCopy >> ((a_index - 1) * 8 + 7)
        
        ; Shift remaining bits (most significant bits starting from the 
        ; 8th most significant bit of the the currently iterated octet
        ; left by 8 bits to accommodate for the span bit
        ; F.ex.          00000001 10110001 becomes
        ;       00000001 10110001 00000000
        lengthCopy := lengthCopy << (a_index * 8)

        ; Set the span bit of the currently iterated octet
        ; F.ex. 00000001 10110001 00000000 becomes
        ;       00000001 10110001 10000000
        lengthCopy := lengthCopy | 1 << ((a_index - 1) * 8 + 7)

        ; Restore the bits lost in the first right-shift (all bits starting 
        ; from the 7 least significant bits of the currently iterated octet)
        ; F.ex. 00000001 10110001 10000000 becomes
        ;       00000001 10110001 11011000 becomes
        lengthCopy := lengthCopy | lengthPrefixedStringLength & ((1 << ((a_index - 1) * 8 + 7)) - 1)

        lengthPrefixedStringLength := lengthCopy
      }
      else
      {
        break
      }
    }

    oldIntegerFormat := a_formatInteger

    setformat, integer, hex
    lengthHexBytes := lengthPrefixedStringLength + 0
    
    lengthPrefixedStringLength := ""

    hexByteCount := ceil((strlen(lengthHexBytes) - 2) / 2) ; - 2 for "0x" prefix removal
    
    ; Iterate all hex bytes
    loop % hexByteCount
    {
      ; Get Nth byte
      singleHexByte := (lengthHexBytes >> ((a_index - 1) * 8)) & 0xFF

      ; Remove "0x" prefix
      singleHexByte := substr(singleHexByte, 3) 

      ; Pad to two chars
      if (strlen(singleHexByte) == 1)
      {
        singleHexByte := "0" singleHexByte
      }
      
      ; Append
      lengthPrefixedStringLength .= singleHexByte
    }
    
    setformat, integer, % oldIntegerFormat

    return lengthPrefixedStringLength
  }

  GetTargetFrameworkStreamData()
  {
    LogMethod(a_thisfunc)

    return Format(""
      . this.TargetFrameworkBytes
      , this.TerminatorByte)
  }

  GetXamlStreamData(xamlText)
  {
    LogMethod(a_thisfunc)

    return Format(""
        . this.TextHeaderBytesWithPlaceholders 
        , this.__GetLengthPrefixedStringLengthBytes(xamlText)
        , this.GetStringBytes(xamlText)
        , this.TerminatorByte)
  }

  GetStringBytes(xamlText)
  {
    LogMethod(a_thisfunc)

    stringBytes := ""

    ; Iterate all characters
    loop, parse, xamlText
    {
      ; Convert to hex and strip off "0x"
      stringBytes .= format("{:02U}", format("{:X}", asc(a_loopfield)))
    }
    
    return stringBytes
  }
}