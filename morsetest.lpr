program MorseTest;

{
  Old school morse trainer
  Copyright (c) 2026 DL1BWA/KD4AEV
  Produced with support by Gemini AI (Google)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <https://gnu.org>.
}



{$mode objfpc}{$H+}
{$codepage utf8} // <--- CRITICAL FIX: FORCES THE COMPILER TO PARSE THE SOURCE TEXT AS UTF-8


uses
  {$IFDEF LINUX} cthreads, {$ENDIF}
  SysUtils, Classes, Math, openal,
  {$IFDEF WINDOWS} Windows {$ENDIF} ;

const
  SAMPLE_RATE = 44100;
  FREQUENCY   = 800.0;
  SLOPE_MS    = 3;

var
  Device: PALCdevice;
  Context: PALCcontext;
  SourceID: ALuint;
  BufferID: ALuint;

  DotLen, DashLen, ElementGap, LetterGap, WordGap: Integer;
  AudioData: array of Int16;
  CurrentSampleIdx: Integer;
  LocaleStrings: TStringList;

function T(const Key, EnglishText: String): String;
var
  Translated: String;
begin
  Result := EnglishText;
  if LocaleStrings = nil then Exit;
  Translated := LocaleStrings.Values[Key];
  if Translated <> '' then
    Result := Translated;
end;

procedure LoadLocale;
var
  LocalePath: String;
begin
  LocaleStrings := TStringList.Create;
  LocaleStrings.NameValueSeparator := '=';
  LocalePath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'locale.txt';
  if FileExists(LocalePath) then
  begin
    try
      // locale.txt is UTF-8; decode it explicitly so German umlauts survive.
      LocaleStrings.LoadFromFile(LocalePath, TEncoding.UTF8);
    except
      // Keep the English hard-coded strings if the locale file cannot be read.
      LocaleStrings.Clear;
    end;
  end;
end;

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

// Rigorously handles multi-byte comparisons explicitly
procedure AddChar(C: String);
var
  S: String;
begin
  S := Trim(C); // Strips away trailing encoding or carriage space adjustments
  if Length(S) = 0 then Exit;

  if S = 'A' then begin AddDit; AddDah; end
  else if S = 'B' then begin AddDah; AddDit; AddDit; AddDit; end
  else if S = 'C' then begin AddDah; AddDit; AddDah; AddDit; end
  else if S = 'D' then begin AddDah; AddDit; AddDit; end
  else if S = 'E' then begin AddDit; end
  else if S = 'F' then begin AddDit; AddDit; AddDah; AddDit; end
  else if S = 'G' then begin AddDah; AddDah; AddDit; end
  else if S = 'H' then begin AddDit; AddDit; AddDit; AddDit; end
  else if S = 'I' then begin AddDit; AddDit; end
  else if S = 'J' then begin AddDit; AddDah; AddDah; AddDah; end
  else if S = 'K' then begin AddDah; AddDit; AddDah; end
  else if S = 'L' then begin AddDit; AddDah; AddDit; AddDit; end
  else if S = 'M' then begin AddDah; AddDah; end
  else if S = 'N' then begin AddDah; AddDit; end
  else if S = 'O' then begin AddDah; AddDah; AddDah; end
  else if S = 'P' then begin AddDit; AddDah; AddDah; AddDit; end
  else if S = 'Q' then begin AddDah; AddDah; AddDit; AddDah; end
  else if S = 'R' then begin AddDit; AddDah; AddDit; end
  else if S = 'S' then begin AddDit; AddDit; AddDit; end
  else if S = 'T' then begin AddDah; end
  else if S = 'U' then begin AddDit; AddDit; AddDah; end
  else if S = 'V' then begin AddDit; AddDit; AddDit; AddDah; end
  else if S = 'W' then begin AddDit; AddDah; AddDah; end
  else if S = 'X' then begin AddDah; AddDit; AddDit; AddDah; end
  else if S = 'Y' then begin AddDah; AddDit; AddDah; AddDah; end
  else if S = 'Z' then begin AddDah; AddDah; AddDit; AddDit; end
  else if S = '1' then begin AddDit; AddDah; AddDah; AddDah; AddDah; end
  else if S = '2' then begin AddDit; AddDit; AddDah; AddDah; AddDah; end
  else if S = '3' then begin AddDit; AddDit; AddDit; AddDah; AddDah; end
  else if S = '4' then begin AddDit; AddDit; AddDit; AddDit; AddDah; end
  else if S = '5' then begin AddDit; AddDit; AddDit; AddDit; AddDit; end
  else if S = '6' then begin AddDah; AddDit; AddDit; AddDit; AddDit; end
  else if S = '7' then begin AddDah; AddDah; AddDit; AddDit; AddDit; end
  else if S = '8' then begin AddDah; AddDah; AddDah; AddDit; AddDit; end
  else if S = '9' then begin AddDah; AddDah; AddDah; AddDah; AddDit; end
  else if S = '0' then begin AddDah; AddDah; AddDah; AddDah; AddDah; end
  else if S = 'Ä' then begin AddDit; AddDah; AddDit; AddDah; end
  else if S = 'Ö' then begin AddDah; AddDah; AddDah; AddDit; end
  else if S = 'Ü' then begin AddDit; AddDit; AddDah; AddDah; end
  else if S = '.' then begin AddDit; AddDah; AddDit; AddDah; AddDit; AddDah; end
  else if S = ',' then begin AddDah; AddDah; AddDit; AddDit; AddDah; end
  else if S = '?' then begin AddDit; AddDit; AddDah; AddDah; AddDit; AddDit; end
  else if S = '!' then begin AddDah; AddDit; AddDah; AddDit; AddDah; AddDah; end
  else if S = '/' then begin AddDah; AddDit; AddDit; AddDah; AddDit; end
  else if S = '-' then begin AddDah; AddDit; AddDit; AddDit; AddDit; end;

  AppendSilence(LetterGap - ElementGap);
end;

procedure PlayCurrentBuffer;
var
  State: ALint;
begin
  if CurrentSampleIdx = 0 then Exit; // Safety: Never pass an empty array to OpenAL

  SetLength(AudioData, CurrentSampleIdx);
  alGenBuffers(1, @BufferID);

  // Clean pointer assignment referencing index zero element to fix crackling
  alBufferData(BufferID, AL_FORMAT_MONO16, @AudioData[0], CurrentSampleIdx * SizeOf(Int16), SAMPLE_RATE);

  alSourcei(SourceID, AL_BUFFER, BufferID);
  alSourcePlay(SourceID);

  repeat
    alGetSourcei(SourceID, AL_SOURCE_STATE, State);
    Sleep(1);
  until State <> AL_PLAYING;

  alSourcei(SourceID, AL_BUFFER, AL_NONE);
  alDeleteBuffers(1, @BufferID);
end;

function GetRandomChar(Mode: Integer): String;
const
  PunctOnly: array[0..5] of String = ('.', ',', '?', '!', '/', '-');
  AllExtended: array[0..8] of String = ('Ä', 'Ö', 'Ü', '.', ',', '?', '!', '/', '-');
begin
  case Mode of
    1: Result := Char(Random(26) + Ord('A'));
    2: Result := Char(Random(10) + Ord('0'));
    3: if Random(2) = 0 then
         Result := Char(Random(26) + Ord('A'))
       else
         Result := Char(Random(10) + Ord('0'));
    4: if Random(10) = 0 then
         Result := PunctOnly[Random(6)]
       else if Random(5) < 4 then
         Result := Char(Random(26) + Ord('A'))
       else
         Result := Char(Random(10) + Ord('0'));
    5: if Random(10) = 0 then
         Result := AllExtended[Random(9)]
       else if Random(5) < 4 then
         Result := Char(Random(26) + Ord('A'))
       else
         Result := Char(Random(10) + Ord('0'));
  else
    Result := 'E';
  end;
end;

var
  UserWPM, UserMode, UserLimit, GroupCount, I: Integer;
  NextChar: String;
  GroupText: String;
  IsInfinite: Boolean;
begin
  Randomize;
  LoadLocale;

  // =================================================================
  // FORCE BOTH WINDOWS KERNEL AND PASCAL RTL TO PROCESS UTF-8 CAPITALS
  // =================================================================
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);

  // This explicitly commands Free Pascal's output engine to pass
  // multi-byte strings to the console without silently stripping capitals
  SetTextCodePage(Output, CP_UTF8);
  {$ENDIF}

  // 1. COLLECT INTERACTIVE CONFIGURATIONS

  Write(T('prompt_wpm', 'Enter Speed in WPM (e.g. 45, 55): '));
  ReadLn(UserWPM);
  if UserWPM < 5 then UserWPM := 5;

  WriteLn(T('menu_mode_title', 'Select Training Target Type:'));
  WriteLn(T('mode_1', '  1 : Pure Letters (A-Z)'));
  WriteLn(T('mode_2', '  2 : Pure Numbers (0-9)'));
  WriteLn(T('mode_3', '  3 : Balanced Mixed (Letters & Numbers)'));
  WriteLn(T('mode_4', '  4 : Mixed with Punctuation (.,?!/-)'));
  WriteLn(T('mode_5', '  5 : Mixed with Punctuation and Extended Umlauts (äöü.,?!/-)'));
  Write(T('prompt_mode', 'Enter Selection (1-5): '));
  ReadLn(UserMode);
  if (UserMode < 1) or (UserMode > 5) then UserMode := 1;

  WriteLn(T('menu_limit_title', 'Select Group Length Rule:'));
  WriteLn(T('limit_0', '  0 : Stop after 50 groups'));
  WriteLn(T('limit_1', '  1 : Endless loop'));
  Write(T('prompt_limit', 'Enter Selection (0-1): '));
  ReadLn(UserLimit);

  IsInfinite := (UserLimit = 1);

  DotLen     := Round(1200 / UserWPM);
  DashLen    := DotLen * 3;
  ElementGap := DotLen;
  LetterGap  := DotLen * 3;
  WordGap    := DotLen * 7;

  WriteLn(#10 + T('init_audio', 'Initializing Sound Card Hardware Context...'));
  Device := alcOpenDevice(nil);
  if Device = nil then Exit;
  Context := alcCreateContext(Device, nil);
  alcMakeContextCurrent(Context);
  alGenSources(1, @SourceID);

  WriteLn('--------------------------------------------------');
  if IsInfinite then
    WriteLn(Format(T('status_endless', 'Running Practice Loop: %dWPM | Mode: %d | Endless Mode'), [UserWPM, UserMode]))
  else
    WriteLn(Format(T('status_finite', 'Running Practice Loop: %dWPM | Mode: %d | Target: 50 Groups'), [UserWPM, UserMode]));
  WriteLn(T('close_hint', 'Press Ctrl + C in this window to close training.'));
  WriteLn('--------------------------------------------------'#10);

  GroupCount := 0;

  while IsInfinite or (GroupCount < 50) do
  begin
    CurrentSampleIdx := 0;
    SetLength(AudioData, 0);
    GroupText := '';

    for I := 1 to 5 do
    begin
      NextChar := GetRandomChar(UserMode);
      GroupText := GroupText + NextChar;
      AddChar(NextChar);
    end;

    AppendSilence(WordGap - LetterGap);

    if UserMode >= 4 then
      Write(GroupText + '   ')
    else
      Write(GroupText + ' ');

    PlayCurrentBuffer;
    Inc(GroupCount);

    if (GroupCount mod 10 = 0) then WriteLn;
  end;

  WriteLn(#10#10 + T('completed', 'Target practice run completed.'));

  alSourcei(SourceID, AL_BUFFER, AL_NONE);
  alDeleteSources(1, @SourceID);
  alcMakeContextCurrent(nil);
  alcDestroyContext(Context);
  alcCloseDevice(Device);

  WriteLn(T('exit_hint', 'Press Enter to exit.'));
  ReadLn;
end.

