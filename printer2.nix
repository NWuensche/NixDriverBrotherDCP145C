{ pkgs, stdenv, fetchurl, cups, dpkg, ghostscript, patchelf, a2ps, coreutils, gnused, gawk, file, makeWrapper, tcsh , gnugrep}:

stdenv.mkDerivation rec {
  name = "mfc2j47dd0dw-cupswrapper-${version}";
  version = "3.0.0-1";

  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf005443/dcp145clpr-1.1.2-2.i386.deb";
    sha256 = "0230jlsmhh5m1fm5386r2zq0zb7mvi0abp6pxnqddqbg1sfw94i5";
  };

  srcLPD = ./brlpdwrapperDCP145C;
  srcPPD = ./MFC.ppd;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ cups ghostscript dpkg a2ps tcsh ];

  unpackPhase = "true";

  installPhase = ''
    ar x $src
    tar xzvf data.tar.gz
    substituteInPlace  usr/local/Brother/Printer/dcp145c/lpd/filterdcp145c \
      --replace /opt "$out/opt"
    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' usr/local/Brother/Printer/dcp145c/lpd/psconvertij2

#    patchelf --set-interpreter ${stdenv.glibc.out}/lib/ld-linux.so.2 usr/local/Brother/lpd/rastertobrij2
    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux.so.2 usr/bin/brprintconf_dcp145c

    #    ln -sr usr/lib/libbrcompij2.so.1.0.2 -T usr/lib/libbrcompij2.so.1
    #patchelf --set-rpath $out/usr/lib usr/local/Brother/lpd/rastertobrij2

    #install -m 755 $srcLPD $out/lib/cups/filter/brlpdwrapperDCP145C
    cp $srcLPD ./brlpdwrapperDCP145C
    patchShebangs ./brlpdwrapperDCP145C
    substituteInPlace ./brlpdwrapperDCP145C \
      --replace /usr "$out/usr" \
      --replace CHANGE "$out/share/cups/model/brdcp145c_cups.ppd"\
      --replace brprintconf_dcp145c "$out/usr/bin/brprintconf_dcp145c"
    substituteInPlace usr/local/Brother/Printer/dcp145c/lpd/filterdcp145c \
      --replace /usr/local/Brother/ "$out/usr/local/Brother/"

    mkdir -p $out
    mkdir -p $out/weg
    mkdir -p $out/lib/cups/filter/
    mkdir -p $out/share/cups/model
    cp -r -v usr $out
    cp brlpdwrapperDCP145C $out/lib/cups/filter/brlpdwrapperDCP145C
    cp $srcPPD $out/share/cups/model/brdcp145c_cups.ppd


    wrapProgram  $out/lib/cups/filter/brlpdwrapperDCP145C \
     --prefix PATH ":" "$out/usr/bin:${stdenv.lib.makeBinPath [ coreutils ]}"
    wrapProgram  $out/usr/local/Brother/Printer/dcp145c/lpd/brdcp145cfilter \
     --prefix PATH ":" "$out/usr/bin:${stdenv.lib.makeBinPath [ coreutils gnugrep]}"
    #    wrapProgram  $out/usr/local/Brother/Printer/dcp145c/lpd/.brdcp145cfilter-wrapped \
    # --prefix PATH ":" "$out/usr/bin:${stdenv.lib.makeBinPath [ coreutils ]}"
    wrapProgram $out/usr/local/Brother/Printer/dcp145c/lpd/psconvertij2 \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ gnused coreutils gawk ] }
    wrapProgram $out/usr/local/Brother/Printer/dcp145c/lpd/filterdcp145c \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }
    '';

      postInstall = ''
    chmod 0777 $out/lib/cups/filter/brlpdwrapperDCP145C
    chmod 0777 $out/lib/cups/filter/.brlpdwrapperDCP145C-wrapped
      '';

  meta = {
    homepage = http://www.brother.com/;
    description = "Brother MFC-J470DW LPR driver";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=mfcj470dw_us_eu_as&os=128;
    maintainers = [ stdenv.lib.maintainers.yochai ];
  };
}
