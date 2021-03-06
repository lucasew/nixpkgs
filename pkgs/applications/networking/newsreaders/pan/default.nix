{ spellChecking ? true
, lib, stdenv, fetchurl, pkgconfig, gtk3, gtkspell3 ? null
, gmime2, gettext, intltool, itstool, libxml2, libnotify, gnutls
, makeWrapper, gnupg
, gnomeSupport ? true, libsecret, gcr
}:

assert spellChecking -> gtkspell3 != null;

let version = "0.146"; in

stdenv.mkDerivation {
  pname = "pan";
  inherit version;

  src = fetchurl {
    url = "http://pan.rebelbase.com/download/releases/${version}/source/pan-${version}.tar.bz2";
    sha256 = "17agd27sn4a7nahvkpg0w39kv74njgdrrygs74bbvpaj8rk2hb55";
  };

  nativeBuildInputs = [ pkgconfig gettext intltool itstool libxml2 makeWrapper ];
  buildInputs = [ gtk3 gmime2 libnotify gnutls ]
    ++ stdenv.lib.optional spellChecking gtkspell3
    ++ stdenv.lib.optionals gnomeSupport [ libsecret gcr ];

  configureFlags = [
    "--with-dbus"
    "--with-gtk3"
    "--with-gnutls"
    "--enable-libnotify"
  ] ++ stdenv.lib.optional spellChecking "--with-gtkspell"
    ++ stdenv.lib.optional gnomeSupport "--enable-gkr";

  postInstall = ''
    wrapProgram $out/bin/pan --suffix PATH : ${gnupg}/bin
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "A GTK-based Usenet newsreader good at both text and binaries";
    homepage = "http://pan.rebelbase.com/";
    maintainers = [ maintainers.eelco ];
    platforms = platforms.linux;
    license = with licenses; [ gpl2 fdl11 ];
  };
}
