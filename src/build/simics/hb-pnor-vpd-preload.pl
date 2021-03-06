#!/usr/bin/perl
# IBM_PROLOG_BEGIN_TAG
# This is an automatically generated prolog.
#
# $Source: src/build/simics/hb-pnor-vpd-preload.pl $
#
# OpenPOWER HostBoot Project
#
# Contributors Listed Below - COPYRIGHT 2012,2018
# [+] International Business Machines Corp.
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.
#
# IBM_PROLOG_END_TAG
use strict;
use File::Temp qw/ tempfile tempdir /;

my $DEBUG = 0;

my $numProcs;
my $numCentPerProc;
my $numMcsPerProc = 8;
my $procChipType;
my $dataPath = ".";
my $outputPath = ".";
my $machine;
my $procConfig = "uninit";
my $centConfig = "uninit";
my $maxProcs = 8;
my $dimmType = "ISDIMM";

# Create temp file for MVPD
my $emptyMVPDfh;
my $emptyMVPD;
($emptyMVPDfh, $emptyMVPD) = tempfile();

# Create temp file for SPD
my $emptySPDfh;
my $emptySPD;
($emptySPDfh, $emptySPD) = tempfile();

# Create temp file for CVPD
my $emptyMemVPDfh;
my $emptyMemVPD;
($emptyMemVPDfh, $emptyMemVPD) = tempfile();

my $mvpdFile = "procmvpd.dat";
my $mvpdFile_ven = "procmvpd_ven.dat";
my $mvpdFile_p9n = "procmvpd_p9n.dat";
my $mvpdFile_p9c = "procmvpd_p9c.dat";
my $mvpdFile_p9a = "procmvpd_p9a.dat";
my $cvpdFile = "cvpd.dat";
my $cvpdCdimmFile = "cvpd_cdimm.dat";
my $dvpdFile = "dvpd.dat";
my $memVpdFile = "";
my $spdFile = "dimmspd.dat";
my $spdCdimmFile = "dimmspd_cdimm.dat";
my $sysMVPD = "sysmvpd.dat";
my $sysMemVPD = "sysmemvpd.dat";
my $sysSPD = "sysspd.dat";

my $MAX_CENT_PER_PROC = 8;
my $MAX_DIMMS_PER_CENT = 8;
my $MAX_MCS = 8;

my @mcsArray = ( 0,0,0,0,0,0,0,0 );


while( $ARGV = shift )
{
    if( $ARGV =~ m/--numProcs/ ||
        $ARGV =~ m/-np/ )
    {
        $numProcs = shift;
        debugMsg( "Num Procs: $numProcs" );
    }
    elsif( $ARGV =~ m/--maxProcs/ ||
           $ARGV =~ m/-mp/ )
    {
        $maxProcs = shift;
    }
    elsif( $ARGV =~ m/--numCentPerProc/ ||
           $ARGV =~ m/-ncpp/ )
    {
        $numCentPerProc = shift;
        debugMsg( "Num Centaurs Per Proc: $numCentPerProc" );
    }
    elsif( $ARGV =~ m/--procChipType/ ||
           $ARGV =~ m/-pct/ )
    {
        $procChipType = shift;
        debugMsg( "Proc Chip Type: $procChipType" );
    }
    elsif( $ARGV =~ m/--dataPath/ ||
        $ARGV =~ m/-dp/ )
    {
        $dataPath = shift;
        debugMsg( "Data Path: $dataPath" );
    }
    elsif( $ARGV =~ m/--machine/ ||
        $ARGV =~ m/-m/ )
    {
        $machine = shift;
        debugMsg( "Machine: $machine" );
    }
    elsif( $ARGV =~ m/--outputPath/ ||
           $ARGV =~ m/-op/ )
    {
        $outputPath = shift;
    }
    elsif( $ARGV =~ m/--forceProc/ ||
           $ARGV =~ m/-fp/ )
    {
        $procConfig = shift;
    }
    elsif( $ARGV =~ m/--forceCent/ ||
           $ARGV =~ m/-fc/ )
    {
        $centConfig = shift;
        if(length($centConfig) != $MAX_MCS)
        {
            print "\nERROR: --forceCent/-fc arg must define presence for all $MAX_MCS Centaurs\n\n\n";
            usage();
        }
    }
    elsif( $ARGV =~ m/--dimmType/ ||
           $ARGV =~ m/-dc/ )
    {
        $dimmType = shift;
    }
    elsif( $ARGV =~ m/--examples/ ||
           $ARGV =~ m/-e/ )
    {
        examples();
    }
    else
    {
        usage();
    }
}

if ($dimmType eq "CDIMM")
{
    $memVpdFile = $cvpdCdimmFile;
}
else
{
    $memVpdFile = $cvpdFile;
}


#figure out default procConfig if one was not specified.
#if procConfig was specified, validate it's length.
if( $procConfig =~ m/uninit/ )
{
    $procConfig = "";
    for( my $proc = 0; $proc < $maxProcs; $proc++ )
    {
        if( $proc < $numProcs )
        {
            $procConfig = $procConfig."1";
        }
        else
        {
            $procConfig = $procConfig."0";
        }
    }
}
elsif(length($procConfig) != $maxProcs)
{
    print "ERROR: forceProc arg must specify presence of same number of procs as indicated by maxProcs($maxProcs)\n";
    exit 1;
}

#if Machine is HABANERO exit out -- HB collects the VPD itself
if($machine eq "HABANERO")
{
    print "PNOR VPD Data Build Not needed.\n";
    exit 0;
}

getMemoryConfig();
createMVPDData();
createCVPDData();
createSPDData();
cleanup();

print "PNOR VPD Data Build Complete.\n";
exit 0;

############################################
# End of Main program
############################################

#====================================================================
# Usage Message
#====================================================================
sub usage
{
    print "Usage: $0 --numProcs <value> [--numCentPerProc <value>]\n";
    print "         [--procChipType <value>]\n";
    print "         [--dataPath <path> ] [-m | --machine <value>]\n";
    print "         [-mp | --maxProcs <value>]\n";
    print "         [-fp | --forceProc <value ] [-fc | -forceCent <value>]\n";
    print "         [-h | --help]\n";
    print "\n";
    print "  -np    --numProcs        Number of Processors in the drawer.\n";
    print "  -mp    --maxProcs        Max number of Proc records created.\n";
    print "  -fp    --forceProc       Force specific procs to be present.\n";
    print "  -ncpp  --numCentPerProc  Number of Centaurs per Processor.\n";
    print "                             not required with --forceCent.\n";
    print "  -fc    --forceCent       Force specifc Centaurs to be present\n";
    print "                           behind each processor. Must always\n";
    print "                           contain info for 8 Centaurs\n";
    print "                           --numCentPerProc\n";
    print "  -pct   --procChipType    Processor Chip Type, ie p9n\n";
    print "  -m     --machine         Text machine to build data for.\n";
    print "                              Default: MURANO\n";
    print "  -dp    --dataPath        Path to VPD data files.\n";
    print "  -op    --outputPath      Path where VPD files should end up.\n";
    print "                              Default: ./\n";
    print "  -h  --help               Help/Usage.\n";
    print "  -e  --examples           List some example use cases.\n";
    print "\n\n";
    exit 1;
}

#====================================================================
# Examples Message
#====================================================================
sub examples
{
    print "Following are some Examples of common use-cases for this tool\n";
    print "\n";
    print "Create System Specfic image with standard plugging:\n";
    print "$0 --numProcs 2 --numCentPerProc 2 --machine MURANO";
    print "   --dataPath <path to input dat files>\n";
    print "\n";
    print "Create a VPO image with explicit Proc and Centaur plugging\n";
    print "   This will result in VPD for the first to proc and Centaurs\n";
    print "   behind MCS0 and MCS1 on each processor\n";
    print "   NOTE: for VPO, maxProcs must be set to 4\n";
    print "$0 --maxProcs 4 --forceProc 1100 --forceCent 11000000";
    print "   --dataPath <path to input dat files>\n";
    print "\n\n";
    exit 1;
}

#====================================================================
# Print Debug Messages
#====================================================================
sub debugMsg
{
    my ($msg) = @_;
    if( $DEBUG )
    {
        print "DEBUG: $msg\n";
    }
}

#====================================================================
# Cleanup
#====================================================================
sub cleanup
{
    print "Cleaning up...\n";
    my $cmd = "rm -rf $emptyMVPD $emptySPD";
    system( $cmd ) == 0 or die "Failure to cleanup!";
}

#====================================================================
# Create the MVPD data for PNOR
#====================================================================
sub createMVPDData
{
    print "Creating MVPD Data...\n";

    my $cmd;
    my $result;
    my $sourceFile;
    my $sysMVPDFile = "$outputPath/$sysMVPD";
    my $sysMVPDFileECC = $sysMVPDFile . ".ecc";

    if( -e $sysMVPDFile )
    {
        # Cleanup any existing files
        system( "rm -rf $sysMVPDFile" );
    }

    # Currently it looks like all processors are populated in the order that
    # they are numbered.  The following logic should work for every platform.
    # If this ever changes, building the MVPD data and SPD data will need to
    # be combined to not duplicate the logic for determining which processors
    # have which DIMMs.

    # Create empty processor MVPD chunk.
    $cmd = "echo \"00FFFF: 00\" \| xxd -r \> $emptyMVPD";
    system( $cmd ) == 0 or die "Creating $emptyMVPD failed!";

    for( my $proc = 0; $proc < $maxProcs; $proc++ )
    {
        if( substr($procConfig,$proc,1) =~ /1/ )
        {
            # Use real data to the full image.
            if( $machine eq "VENICE" )
            {
                $sourceFile = "$dataPath/$mvpdFile_ven";
            }
            elsif( $procChipType eq "p9n")
            {
                $sourceFile = "$dataPath/$mvpdFile_p9n";
            }
            elsif( $procChipType eq "p9c")
            {
                $sourceFile = "$dataPath/$mvpdFile_p9c";
            }
            elsif( $procChipType eq "p9a")
            {
                 $sourceFile = "$dataPath/$mvpdFile_p9a";
            }
            else
            {
                $sourceFile = "$dataPath/$mvpdFile";
            }

            debugMsg( "Using source $sourceFile for machine $machine\n" );
        }
        else
        {
            # No processor, use empty data chunk.
            $sourceFile = $emptyMVPD;

            debugMsg( "Using source $sourceFile\n" );
        }

        $result = `dd if=$sourceFile of=$sysMVPDFile conv=notrunc oflag=append 2>&1 1>/dev/null`;
        if( $? )
        {
            debugMsg( "Failed to create: $sysMVPDFile, using source: $sourceFile" );
            die "Error building MVPD file! $proc\n";
        }
    }

    if( -e $sysMVPDFile )
    {
        system( "chmod 775 $sysMVPDFile" );
        system( "ecc --inject $sysMVPDFile --output $sysMVPDFileECC --p8" );
        system( "chmod 775 $sysMVPDFileECC" );
    }
    debugMsg( "MVPD Done." );
}

#====================================================================
# Create the CVPD data for PNOR
#====================================================================
sub createCVPDData
{
    print "Creating Mem VPD Data...\n";

    my $cmd;
    my $result;
    my $sourceFile;
    my $sysMemVPDFile = "$outputPath/$sysMemVPD";
    my $sysMemVPDFileECC = $sysMemVPDFile . ".ecc";
    my $numProcs = $maxProcs;

    if( -e $sysMemVPDFile )
    {
        # Cleanup any existing files
        system( "rm -rf $sysMemVPDFile" );
    }

    if( $procChipType eq "p9n")
    {
        $numProcs = 2;
    }
    elsif($procChipType eq "p9c")
    {
        $numProcs = 4;
    }
    elsif( $procChipType eq "p9a")
    {
        $numProcs = 2;
    }

    #Centaurs are populated based on populated Processors and special
    #MCS plugging rules.  We can look at $procConfig and $maxProcs
    #to determine processor config.  Centaur plugging is contained
    #in $mcsArray, populated by getMemoryConfig()
    #For direct access memory, $mcsArray has which MCSs are present

    # Create empty Mem VPD data chunk
    if($procChipType eq "p9c")
    {
        $cmd = " echo \"001FFF: 00\" \| xxd -r \> $emptyMemVPD";
    }
    else
    {
        $cmd = " echo \"000FFF: 00\" \| xxd -r \> $emptyMemVPD";
    }

    system( $cmd ) == 0 or die "Creating $emptyMemVPD failed!";

    for( my $proc = 0; $proc < $numProcs; $proc++ )
    {
        for( my $mcs = 0; $mcs < $MAX_MCS; $mcs++ )
        {
            if( ($mcsArray[$mcs] == 1) &&
                substr($procConfig,$proc,1) =~ /1/ )
            {
                debugMsg( "$machine( $proc, $mcs): Real File" );
                # Use the real data to the full image
                $sourceFile = "$dataPath/$memVpdFile";
            }
            else
            {
                debugMsg( "$machine( $proc, $mcs): Empty file" );
                # No Centaur/MCS, use empty data chunk
                $sourceFile = $emptyMemVPD;
            }

            debugMsg( "Using source $sourceFile\n" );

            $result = `dd if=$sourceFile of=$sysMemVPDFile conv=notrunc oflag=append 2>&1 1>/dev/null`;
            if( $? )
            {
                die "Error building Mem VPD file! proc=$proc cent=$mcs\n";
            }

        }
    }

    if( -e $sysMemVPDFile )
    {
        system( "chmod 775 $sysMemVPDFile" );
        system( "ecc --inject $sysMemVPDFile --output $sysMemVPDFileECC --p8" );
        system( "chmod 775 $sysMemVPDFileECC" );
    }
    debugMsg( "Mem VPD Done." );
}


#====================================================================
# Create the SPD data for PNOR
#====================================================================
sub createSPDData
{
    print "Creating SPD Data...\n";

    my $cmd;
    my $result;
    my $sourceFile;
    my $sysSPDFile = "$outputPath/$sysSPD";
    my $sysSPDFileECC = $sysSPDFile . ".ecc";

    if( -e $sysSPDFile )
    {
        # Cleanup any existing files
        system( "rm -rf $sysSPDFile" );
    }

    # Create empty SPD data chunk
    $cmd = " echo \"0001FF: 00\" \| xxd -r \> $emptySPD";
    system( $cmd ) == 0 or die "Creating $emptySPD failed!";

    for( my $proc = 0; $proc < $maxProcs; $proc++ )
    {
        for( my $mcs = 0; $mcs < $MAX_MCS; $mcs++ )
        {
            for( my $dimm = 0; $dimm < $MAX_DIMMS_PER_CENT; $dimm++ )
            {
                 if( ($mcsArray[$mcs] == 1) &&
                     substr($procConfig,$proc,1) =~ /1/ )
                {
                    debugMsg( "$machine( $proc, $mcs, $dimm ): Real File" );
                    if ($dimmType eq "CDIMM")
                    {
                         # CDIMM Config - Use the real data to the full image
                         $sourceFile = "$dataPath/$spdCdimmFile";
                    }
                    else
                    {
                        # Assume ISDIMM - Use the real data to the full image
                        $sourceFile = "$dataPath/$spdFile";
                    }
                    
                }
                else
                {
                    debugMsg( "$machine( $proc, $mcs, $dimm ): Empty file" );
                    # No dimm, use empty data chunk
                    $sourceFile = $emptySPD;
                }

                debugMsg( "Using source $sourceFile\n" );

                $result = `dd if=$sourceFile of=$sysSPDFile conv=notrunc oflag=append 2>&1 1>/dev/null`;
                if( $? )
                {
                    die "Error building SPD file! $proc  $mcs  $dimm\n";
                }
            }
        }
    }


    if( -e $sysSPDFile )
    {
        system( "chmod 775 $sysSPDFile" );
        system( "ecc --inject $sysSPDFile --output $sysSPDFileECC --p8" );
        system( "chmod 775 $sysSPDFileECC" );
    }
    debugMsg( "SPD Done." );
}


sub getMemoryConfig
{
    debugMsg( "getMemoryConfig $machine" );

    #Select direct memory vpd file or Centaur vpd file
    if( $procChipType eq "p9n")
    {
        $memVpdFile = $dvpdFile;
        $numMcsPerProc = 4;
    }

    #First check if explicit Centaur Plugging rules were provided
    if( $centConfig !~ m/uninit/ )
    {
        for( my $mcs = 0; $mcs < $MAX_MCS; $mcs++ )
        {
            if( substr($centConfig,$mcs,1) =~ /1/ )
            {
                $mcsArray[$mcs] = 1;
            }
            else
            {
                $mcsArray[$mcs] = 0;
            }
        }
    }
    else
    {
        #use pre-defined Centaur Plugging order
        for( my $mcs = 0; $mcs < $MAX_MCS; $mcs++ )
        {
            debugMsg( "Mcs: $mcs CentPerProc: $numCentPerProc" );
            if( $machine eq "MURANO" || $machine eq "NO_SP")
            {
                # Plugging order is:
                #   Processor 0 - 3
                #   MCS 4 - 7 (1 Centaur/MCS)
                if( $mcs >= 4 &&
                    $mcs <= (4 + ($numCentPerProc - 1)) )
                {
                    $mcsArray[$mcs] = 1;
                }
            }
            elsif( $machine eq "VENICE" )
            {
                # Plugging order is:
                #   Processor 0 - 7
                #   MCS 0 - 7, then 0 - 3
                if( $mcs >= 0 &&
                    $mcs <= (($numCentPerProc - 1)) )
                {
                    $mcsArray[$mcs] = 1;
                }
            }
            elsif( $machine eq "TULETA" )
            {
                # Plugging order is:
                #   Processor 0 - 3
                #   MCS 4 - 7, then 0 - 3 (1 Centaur/MCS)
                if( ($numCentPerProc <= 4) &&
                    ($mcs >= 4) &&
                    ($mcs <= (4 + ($numCentPerProc - 1))) )
                {
                    $mcsArray[$mcs] = 1;
                }
                elsif( $numCentPerProc > 4 )
                {
                    if( $mcs >= 4 &&
                        $mcs <= 7 )
                    {
                        $mcsArray[$mcs] = 1;
                    }
                    elsif( $mcs >= 0 &&
                           $mcs < ($numCentPerProc - 4) )
                    {
                        $mcsArray[$mcs] = 1;
                    }
                }
            }
            elsif( $machine eq "CUMULUS" || $machine eq "CUMULUS_CDIMM" )
            {
                # Plugging order is:
                #   Processor 0 - 3
                #   MCS 0 - 3 (1 Centaur/MCS)
                if(($mcs % $MAX_MCS) >= 0 && ($mcs % $MAX_MCS) < 4)
                {
                    $mcsArray[$mcs] = 1;
                }
            }
            elsif( $procChipType eq "p9n")
            {
                #There are no centaurs within a NIMBUS machine, but need to set
                #up the mcs array.
                if( $mcs < $numMcsPerProc)
                {
                    $mcsArray[$mcs] = 1;
                }
            }
            elsif( $procChipType eq "p9a")
            {
                #There are no centaurs within an AXONE machine, but need to set
                #up the mcs array.
                if( $mcs < $numMcsPerProc)
                {
                    $mcsArray[$mcs] = 1;
                }
            }
            else
            {
                die "Invalid machine ($machine)!!!  Cannot preload DIMM VPD data...exiting.";
            }
        }
    }

    debugMsg( "mcsArray=@mcsArray" );
}
