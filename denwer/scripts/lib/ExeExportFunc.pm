package ExeExportFunc;

# If true, prints debug info.
my $DEBUG = 0;

# Notes:
# *RVA: offset from image LOADED into memory.
# *Raw: offset in EXE file on disk.
#
# When EXE is loaded into memory, its sections (.data, .edata etc.) may be placed 
# at different memory addresses. So we need to scan each section to find RVA in it
# and convert to Raw offset using mapping address.
sub getRawOffsetOfExportedFunc {
  my ($fileName, $funcName) = @_;

  # Read all the file into memory (improve speed).
  open(local *F, $fileName) or die "Could not open $fileName\n"; binmode(F); local $/;
  local $FILEDATA = <F>;
  local @SECTIONS = ();

  # IMAGE_DOS_HEADER = 0
  my $e_lfanew = readunpack("IMAGE_DOS_HEADER.e_lfanew", "L", 60);
  
  # IMAGE_NT_HEADERS = $e_lfanew
  my $SizeOfOptionalHeader = readunpack("IMAGE_NT_HEADERS.SizeOfOptionalHeader", "S", $e_lfanew+4+16);
  my $NumberOfSections     = readunpack("IMAGE_NT_HEADERS.NumberOfSections",     "S", $e_lfanew+4+2);
  
  # Read all EXE sections.
  my $section = $e_lfanew + 24 + $SizeOfOptionalHeader;
  for (my $i=0; $i<$NumberOfSections; $i++, $section+=40) {
    # IMAGE_SECTION_HEADER = $section
    my $Name             = readunpack("IMAGE_SECTION_HEADER.Name", "a8", $section);
    my $VirtualSize      = readunpack("IMAGE_SECTION_HEADER.VirtualSize", "L", $section+8);
    my $VirtualAddress   = readunpack("IMAGE_SECTION_HEADER.VirtualAddress", "L", $section+12);
    my $SizeOfRawData    = readunpack("IMAGE_SECTION_HEADER.SizeOfRawData", "L", $section+16);
    my $PointerToRawData = readunpack("IMAGE_SECTION_HEADER.PointerToRawData", "L", $section+20);
    my $size = $VirtualSize || $SizeOfRawData;
    push @SECTIONS, [$size, $VirtualAddress, $PointerToRawData];
  }
  
  # IMAGE_OPTIONAL_HEADER.DataDirectory 
  my $dataDirectoryRaw        = $e_lfanew+0x78; 
  my $ExportTableRVA          = readunpack("IMAGE_NT_HEADERS.ExportTableRVA",       "L", $dataDirectoryRaw);
  
  # IMAGE_EXPORT_DIRECTORY = $ExportTableRVA
  # Convert RVA to raw offset in EXE image (search each section).
  my $exportTableRaw = rvaToRaw($ExportTableRVA) or do { debug("Could not find raw EXE offset for ExportTableRVA=$ExportTableRVA\n"); return };

  # IMAGE_EXPORT_DIRECTORY = $exportTableRaw
  my $NumberOfFunctions     = readunpack("IMAGE_EXPORT_DIRECTORY.NumberOfFunctions",        "L",  $exportTableRaw+20);
  my $NumberOfNames         = readunpack("IMAGE_EXPORT_DIRECTORY.NumberOfNames",            "L",  $exportTableRaw+20+4);
  my $AddressOfFunctions    = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfFunctions",       "L",  $exportTableRaw+20+8);
  my $AddressOfNames        = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfNames",           "L",  $exportTableRaw+20+12);
  my $AddressOfNameOrdinals = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals",    "L",  $exportTableRaw+20+16);
  my @namePointers          = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfNames->*",        "L*", rvaToRaw($AddressOfNames), $NumberOfNames*4);
  my @funcPointers          = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfFunctions->*",    "L*", rvaToRaw($AddressOfFunctions), $NumberOfFunctions*4);
  my @ordinals              = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals->*", "S*", rvaToRaw($AddressOfNameOrdinals), $NumberOfNames*2);

  # Enumerate all names.
  for (my $i=0; $i<@namePointers; $i++) {
    my $nameRva = $namePointers[$i];
    my $nameRaw = rvaToRaw($nameRva);
    my $name = readunpack("IMAGE_EXPORT_DIRECTORY.AddressOfNames->$nameRva", "a*", $nameRaw);
    if ($name eq $funcName) {
      my $ordinal = $ordinals[$i];
      my $funcRva = $funcPointers[$i];
      my $funcRaw = rvaToRaw($funcRva);
      debug("FOUND $name: $ordinal, $funcRva -> $funcRaw");
      return $funcRaw;
    }
  }

  # Convert RVA (memory-based) offset to Raw (file-based) offset.
  sub rvaToRaw {
    my ($rva) = @_;
    for (my $i=0; $i<@SECTIONS; $i++) {
      my $section = $SECTIONS[$i];
      my $size             = $section->[0];
      my $VirtualAddress   = $section->[1];
      my $PointerToRawData = $section->[2];
      my $offset = $rva - $VirtualAddress;
      if ($offset >= 0 && $offset < $size) {
        my $raw = $PointerToRawData + $offset;
        debug("Found raw offset for $rva: $raw");
        # If section is non-first in the list, make it first to improve speed.
        if ($i) {
          splice @SECTIONS, $i, 1;
          unshift @SECTIONS, $section;
        }
        return $raw;
      }
    }
    debug("Cannot find raw offset for $rva");
    return undef;
  }

  # Read part of file starting from $pos. See unpack() syntax.
  sub readunpack {
    my ($title, $fmt, $pos, $size) = @_;
    $size ||= 16;
    my $data = substr($FILEDATA, $pos, $size);
    my @result = unpack($fmt, $data);
    debug(sprintf "%-50s %s", "$title [$pos]:", @result==1? @result : "$result[0], ... ".@result." times");
    return wantarray? @result : $result[0];
  }
  
  # Output debug information.
  sub debug {
    print join("", @_) . "\n" if $DEBUG;
  }
}

return 1;
