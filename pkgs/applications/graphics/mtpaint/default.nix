{ stdenv, fetchFromGitHub
, pkg-config
, freetype, giflib, gtk3, lcms2, libjpeg, libpng, libtiff, openjpeg, gifsicle
}:

stdenv.mkDerivation rec {
  p_name  = "mtPaint";
  ver_maj = "3.50";
  ver_min = "01";
  name = "${p_name}-${ver_maj}.${ver_min}";

  src = fetchFromGitHub {
    owner = "wjaguar";
    repo = p_name;
    rev = "a4675ff5cd9fcd57d291444cb9f332b48f11243f";
    sha256 = "04wqxz8i655gz5rnz90cksy8v6m2jhcn1j8rzhqpp5xhawlmq24y";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    freetype giflib gtk3 lcms2 libjpeg libpng libtiff openjpeg gifsicle
  ];

  configureFlags = [ "gtk3" "intl" "man" ];

  meta = {
    description = "A simple GTK painting program";
    longDescription = ''
      mtPaint is a simple GTK painting program designed for
      creating icons and pixel based artwork.  It can edit indexed palette
      or 24 bit RGB images and offers basic painting and palette manipulation
      tools. It also has several other more powerful features such as channels,
      layers and animation.
      Due to its simplicity and lack of dependencies it runs well on
      GNU/Linux, Windows and older PC hardware.
    '';
    homepage = "http://mtpaint.sourceforge.net/";
    license = stdenv.lib.licenses.gpl3Plus;
    platforms = stdenv.lib.platforms.linux;
    maintainers = [ stdenv.lib.maintainers.vklquevs ];
  };
}

