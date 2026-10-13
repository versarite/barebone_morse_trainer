program MorseTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF LINUX} cthreads, {$ENDIF}
  SysUtils, Math, openal;

const
  SAMPLE_RATE = 44100;
  FREQUENCY   = 700.0;
  SLOPE_MS    = 2;

var
  Device: PALCdevice;
  Context: PALCcontext;
  SourceID: ALuint;
  BufferID: ALuint;

  DotLen, DashLen, ElementGap, LetterGap, WordGap: Integer;
  AudioData: array of Int16;
  CurrentSampleIdx: Integer;

procedure AppendSilence(DurationMS: Integer);
var
  SamplesCount, NewSize, I: Integer;
begin
  SamplesCount := Round((DurationMS / 1000.0) * SAMPLE_RATE);
  if SamplesCount <= 0 then Exit;
  NewSize := CurrentSampleIdx + SamplesCount;
  if Length(AudioData) < NewSize then SetLength(AudioData, NewSize);
  for I := 0 to SamplesCount - 1 do
  begin
    AudioData[CurrentSampleIdx] := 0;
    Inc(CurrentSampleIdx);
  end;
end;

procedure AppendPulse(DurationMS: Integer);
var
  SamplesCount, SlopeSamples, NewSize, I: Integer;
  AnglePerSample, VolumeFactor: Double;
begin
  SamplesCount := Round((DurationMS / 1000.0) * SAMPLE_RATE);
  SlopeSamples := Round((SLOPE_MS / 1000.0) * SAMPLE_RATE);
  if SlopeSamples * 2 > SamplesCount then SlopeSamples := SamplesCount div 2;
  NewSize := CurrentSampleIdx + SamplesCount;
  if Length(AudioData) < NewSize then SetLength(AudioData, NewSize);
  AnglePerSample := (2.0 * Pi * FREQUENCY) / SAMPLE_RATE;
  for I := 0 to SamplesCount - 1 do
  begin
    if (SlopeSamples > 0) and (I < SlopeSamples) then
      VolumeFactor := Double(I) / Double(SlopeSamples)
    else if (SlopeSamples > 0) and (I >= (SamplesCount - SlopeSamples)) then
      VolumeFactor := Double(SamplesCount - 1 - I) / Double(SlopeSamples)
    else
      VolumeFactor := 1.0;
    AudioData[CurrentSampleIdx] := Round(32000.0 * VolumeFactor * Sin(AnglePerSample * I));
    Inc(CurrentSampleIdx);
  end;
end;

procedure AddDit; begin AppendPulse(DotLen); AppendSilence(ElementGap); end;
procedure AddDah; begin AppendPulse(DashLen); AppendSilence(ElementGap); end;

// Dictionary parser handling basic characters, numbers, and extended Morse parameters
procedure AddChar(C: String);
begin
  if C = 'A' then begin AddDit; AddDah; end
  else if C = 'B' then begin AddDah; AddDit; AddDit; AddDit; end
  else if C = 'C' then begin AddDah; AddDit; AddDah; AddDit; end
  else if C = 'D' then begin AddDah; AddDit; AddDit; end
  else if C = 'E' then begin AddDit; end
  else if C = 'F' then begin AddDit; AddDit; AddDah; AddDit; end
  else if C = 'G' then begin AddDah; AddDah; AddDit; end
  else if C = 'H' then begin AddDit; AddDit; AddDit; AddDit; end
  else if C = 'I' then begin AddDit; AddDit; end
  else if C = 'J' then begin AddDit; AddDah; AddDah; AddDah; end
  else if C = 'K' then begin AddDah; AddDit; AddDah; end
  else if C = 'L' then begin AddDit; AddDah; AddDit; AddDit; end
  else if C = 'M' then begin AddDah; AddDah; end
  else if C = 'N' then begin AddDah; AddDit; end
  else if C = 'O' then begin AddDah; AddDah; AddDah; end
  else if C = 'P' then begin AddDit; AddDah; AddDah; AddDit; end
  else if C = 'Q' then begin AddDah; AddDah; AddDit; AddDah; end
  else if C = 'R' then begin AddDit; AddDah; AddDit; end
  else if C = 'S' then begin AddDit; AddDit; AddDit; end
  else if C = 'T' then begin AddDah; end
  else if C = 'U' then begin AddDit; AddDit; AddDah; end
  else if C = 'V' then begin AddDit; AddDit; AddDit; AddDah; end
  else if C = 'W' then begin AddDit; AddDah; AddDah; end
  else if C = 'X' then begin AddDah; AddDit; AddDit; AddDah; end
  else if C = 'Y' then begin AddDah; AddDit; AddDah; AddDah; end
  else if C = 'Z' then begin AddDah; AddDah; AddDit; AddDit; end
  else if C = '1' then begin AddDit; AddDah; AddDah; AddDah; AddDah; end
  else if C = '2' then begin AddDit; AddDit; AddDah; AddDah; AddDah; end
  else if C = '3' then begin AddDit; AddDit; AddDit; AddDah; AddDah; end
  else if C = '4' then begin AddDit; AddDit; AddDit; AddDit; AddDah; end
  else if C = '5' then begin AddDit; AddDit; AddDit; AddDit; AddDit; end
  else if C = '6' then begin AddDah; AddDit; AddDit; AddDit; AddDit; end
  else if C = '7' then begin AddDah; AddDah; AddDit; AddDit; AddDit; end
  else if C = '8' then begin AddDah; AddDah; AddDah; AddDit; AddDit; end
  else if C = '9' then begin AddDah; AddDah; AddDah; AddDah; AddDit; end
  else if C = '0' then begin AddDah; AddDah; AddDah; AddDah; AddDah; end
  // Extended Umlaut / Punctuation Matrix mappings:
  else if C = 'Ä' then begin AddDit; AddDah; AddDit; AddDah; end
  else if C = 'Ö' then begin AddDah; AddDah; AddDah; AddDit; end
  else if C = 'Ü' then begin AddDit; AddDit; AddDah; AddDah; end
  else if C = '.' then begin AddDit; AddDah; AddDit; AddDah; AddDit; AddDah; end
  else if C = ',' then begin AddDah; AddDah; AddDit; AddDit; AddDah; end
  else if C = '?' then begin AddDit; AddDit; AddDah; AddDah; AddDit; AddDit; end
  else if C = '!' then begin AddDah; AddDit; AddDah; AddDit; AddDah; AddDah; end
  else if C = '/' then begin AddDah; AddDit; AddDit; AddDah; AddDit; end
  else if C = '-' then begin AddDah; AddDit; AddDit; AddDit; AddDit; AddDah; end;

  AppendSilence(LetterGap - ElementGap);
end;

procedure PlayCurrentBuffer;
var State: ALint;
begin
  SetLength(AudioData, CurrentSampleIdx);
  alGenBuffers(1, @BufferID);

  // ================================================================
  // CRITICAL FIX: CHANGE @AudioData TO POINT TO THE FIRST ELEMENT [0]
  // ================================================================
  alBufferData(BufferID, AL_FORMAT_MONO16, @AudioData[0], CurrentSampleIdx * SizeOf(Int16), SAMPLE_RATE);

  alSourcei(SourceID, AL_BUFFER, BufferID);
  alSourcePlay(SourceID);
  repeat
    alGetSourcei(SourceID, AL_SOURCE_STATE, State);
    Sleep(2);
  until State <> AL_PLAYING;
  alSourcei(SourceID, AL_BUFFER, AL_NONE);
  alDeleteBuffers(1, @BufferID);
end;


// Selects characters based on your practice routine choices
function GetRandomChar(Mode: Integer): String;
const
  UmlautPunct: array[0..8] of String = ('Ä', 'Ö', 'Ü', '.', ',', '?', '!', '/', '-');
begin
  case Mode of
    1: Result := Char(Random(26) + Ord('A')); // Pure Letters
    2: Result := Char(Random(10) + Ord('0')); // Pure Numbers
    3: if Random(2) = 0 then                  // Balanced Mixed
         Result := Char(Random(26) + Ord('A'))
       else
         Result := Char(Random(10) + Ord('0'));
    4: if Random(10) = 0 then                 // ~10% Chance for Umlaut/Punctuation
         Result := UmlautPunct[Random(9)]
       else if Random(5) < 4 then             // ~72% letters, ~18% numbers
         Result := Char(Random(26) + Ord('A'))
       else
         Result := Char(Random(10) + Ord('0'));
  else
    Result := 'E';
  end;
end;

var
  UserWPM, UserMode, I: Integer;
  NextChar: String;
  GroupText: String;
begin
  Randomize;

  // 1. COLLECT INTERACTIVE CONFIGURATIONS
  Write('Enter Speed in WPM (e.g. 45, 55): ');
  ReadLn(UserWPM);
  if UserWPM < 5 then UserWPM := 5;

  WriteLn('Select Training Target Type:');
  WriteLn('  1 : Pure Letters (A-Z)');
  WriteLn('  2 : Pure Numbers (0-9)');
  WriteLn('  3 : Balanced Mixed (Letters & Numbers)');
  WriteLn('  4 : Mixed with Extended Umlauts & Punctuation (äöü.,?!/-)');
  Write('Enter Selection (1-4): ');
  ReadLn(UserMode);
  if (UserMode < 1) or (UserMode > 4) then UserMode := 1;

  // Calculate strict timings matching the dynamic speed input
  DotLen     := Round(1200 / UserWPM);
  DashLen    := DotLen * 3;
  ElementGap := DotLen;
  LetterGap  := DotLen * 3;
  WordGap    := DotLen * 7;

  WriteLn(#10'Initializing Sound Card Hardware Context...');
  Device := alcOpenDevice(nil);
  if Device = nil then Exit;
  Context := alcCreateContext(Device, nil);
  alcMakeContextCurrent(Context);
  alGenSources(1, @SourceID);

  WriteLn('--------------------------------------------------');
  WriteLn(Format('Running Practice Loop: %dWPM | Target Mode: %d', [UserWPM, UserMode]));
  WriteLn('Press Ctrl + C in this window to close training.');
  WriteLn('--------------------------------------------------'#10);

  // 2. PRIMARY GENERATION LOOP
  while True do
  begin
    CurrentSampleIdx := 0;
    GroupText := '';

    for I := 1 to 5 do
    begin
      NextChar := GetRandomChar(UserMode);
      GroupText := GroupText + NextChar;
      AddChar(NextChar);
    end;

    AppendSilence(WordGap - LetterGap);

    // Outputs the text blocks cleanly tracking visual feedback layout streams
    if UserMode = 4 then
      Write(GroupText + '   ')
    else
      Write(GroupText + ' ');

    PlayCurrentBuffer;
  end;

  alDeleteSources(1, @SourceID);
  alcMakeContextCurrent(nil);
  alcDestroyContext(Context);
  alcCloseDevice(Device);
end.

